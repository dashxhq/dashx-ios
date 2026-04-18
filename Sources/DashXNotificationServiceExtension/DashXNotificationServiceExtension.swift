import CryptoKit
import DashXCore
import Foundation
import MobileCoreServices
import UserNotifications

/// Base class for a Notification Service Extension that handles DashX push notifications.
///
/// Host apps integrating DashX 1.3.0+ should add a Notification Service Extension target to
/// their Xcode project and subclass this class inside that target. The extension:
///
/// 1. Downloads and attaches `dashx.image` to the notification before display.
/// 2. Registers a `UNNotificationCategory` for the push's action buttons (matching the
///    hash the backend stamped into `aps.category`) so banner long-press reveals them.
/// 3. Fires a `trackNotification(event: delivered)` GraphQL mutation so analytics records
///    delivery even when the host app isn't running.
///
/// Two Info.plist keys are required on the NSE target for delivered tracking:
/// - `DASHX_BASE_URI` — same value as the host app
/// - `DASHX_PUBLIC_KEY` — same value as the host app
///
/// If these keys are absent, the NSE skips delivered tracking silently; image attachment
/// and category registration still work.
open class DashXNotificationServiceExtension: UNNotificationServiceExtension {
    /// Cap media downloads so a hostile server can't OOM the NSE (which has roughly a
    /// 24 MB memory budget). APNs itself allows up to 50 MB attachments.
    private static let maxMediaBytes: Int64 = 50 * 1024 * 1024

    /// Best-effort bound on how long to keep the NSE alive after the content handler fires,
    /// waiting for the delivered-tracking HTTP call. iOS keeps the process around briefly
    /// after `contentHandler` returns; anything over ~5s risks the system killing us mid-request.
    private static let deliveredTrackingTimeout: DispatchTimeInterval = .seconds(3)

    private var bestAttempt: UNMutableNotificationContent?
    private let handlerLock = NSLock()
    private var underlyingHandler: ((UNNotificationContent) -> Void)?
    private var handlerCalled = false

    override open func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        underlyingHandler = contentHandler
        // Always prefer a mutable copy; if that somehow fails, fall back to an empty content
        // rather than `request.content` so the "never return raw content" invariant holds
        // (any work we do below — category, attachment — still lands on the returned object).
        let content = (request.content.mutableCopy() as? UNMutableNotificationContent)
            ?? UNMutableNotificationContent()
        bestAttempt = content

        let userInfo = request.content.userInfo
        let dashx = userInfo.dashxNotificationData()

        // Default the notification sound when the server didn't specify one. iOS
        // copies `aps.sound` (if present) into `content.sound` before spawning the
        // NSE; if it's nil, the banner renders silently. Matches the legacy
        // silent-push path which hardcoded `UNNotificationSound.default` on the
        // reconstructed local notification. Servers that want true silence can
        // override by sending an explicit `aps.sound` the integrator recognizes.
        if content.sound == nil {
            content.sound = .default
        }

        // 1. Synchronously register the action-button category before the content handler fires.
        //    iOS reads the category state at display time; if we set it asynchronously AFTER
        //    `contentHandler(...)`, action buttons won't appear on this notification.
        if let buttons = dashx?.actionButtons, !buttons.isEmpty {
            registerCategorySynchronously(for: buttons)
        }

        // 2. Start delivered tracking. The semaphore is signalled on HTTP completion and
        //    we wait on it AFTER firing the content handler — iOS keeps the NSE alive
        //    briefly post-handler, so this is the safest window to land the request.
        let deliveredSemaphore = (dashx?.id).flatMap { self.startTrackDelivered(notificationId: $0) }

        // 3. Attach the image (async). When the download completes or is skipped, we fire
        //    the content handler, then bounded-wait on the delivery semaphore.
        let finalize: () -> Void = { [weak self] in
            guard let self else { return }
            self.deliver(content)
            if let sem = deliveredSemaphore {
                _ = sem.wait(timeout: .now() + Self.deliveredTrackingTimeout)
            }
        }

        if let imageString = dashx?.image, let imageURL = URL(string: imageString) {
            downloadAttachment(from: imageURL) { attachment in
                if let attachment {
                    content.attachments = [attachment]
                }
                finalize()
            }
        } else {
            finalize()
        }
    }

    override open func serviceExtensionTimeWillExpire() {
        // iOS is about to terminate us. Ship whatever partial work we have.
        if let content = bestAttempt {
            deliver(content)
        }
    }

    // MARK: - Exactly-once content handler

    /// Calls the underlying content handler exactly once. Safe to invoke from any of the
    /// completion paths (attachment callback, time-expired callback) or in race with one
    /// another — the second call is a no-op.
    private func deliver(_ content: UNNotificationContent) {
        handlerLock.lock()
        defer { handlerLock.unlock() }
        guard !handlerCalled, let handler = underlyingHandler else { return }
        handlerCalled = true
        handler(content)
    }

    // MARK: - Category / action buttons

    /// Derives the category identifier that the backend stamped into `aps.category` for this
    /// button set, then registers a matching `UNNotificationCategory` on the shared center
    /// before iOS renders the notification. Matches `dashx_category_id_for_buttons` in
    /// `apps/messaging/src/notifiers/fcm.rs` on the backend.
    ///
    /// Implementation notes:
    /// - Merges with existing categories (doesn't replace) so other SDKs' categories are preserved.
    /// - Uses a semaphore to make `getNotificationCategories` synchronous — the NSE must not
    ///   return from `didReceive` with category state still unsettled, otherwise iOS displays
    ///   the notification without action buttons.
    /// - Reads the categories back after writing them. `setNotificationCategories`
    ///   is async internally, and the read-back gives iOS a beat to flush so the current
    ///   notification picks up the new actions.
    private func registerCategorySynchronously(for buttons: [ActionButton]) {
        let categoryId = Self.dashxCategoryId(forButtons: buttons)
        let actions = buttons.map { button in
            UNNotificationAction(
                identifier: button.identifier,
                title: button.label,
                options: [.foreground]
            )
        }
        let category = UNNotificationCategory(
            identifier: categoryId,
            actions: actions,
            intentIdentifiers: [],
            options: .customDismissAction
        )

        let center = UNUserNotificationCenter.current()
        let semaphore = DispatchSemaphore(value: 0)

        center.getNotificationCategories { existing in
            var merged = existing.filter { $0.identifier != categoryId }
            merged.insert(category)
            center.setNotificationCategories(merged)
            // Read-back: forces iOS to flush the updated category set before we return.
            // Without this, action buttons intermittently fail to appear on the current push.
            center.getNotificationCategories { _ in semaphore.signal() }
        }

        _ = semaphore.wait(timeout: .now() + .seconds(2))
    }

    /// Canonical form: `<identifier>|<label>` joined with ASCII 0x1F, SHA-256, hex,
    /// then `DASHX_CAT_` + first 14 hex chars (total 24 chars). Must match the
    /// backend's `dashx_category_id_for_buttons` byte-for-byte.
    public static func dashxCategoryId(forButtons buttons: [ActionButton]) -> String {
        let canonical = buttons.map { "\($0.identifier)|\($0.label)" }.joined(separator: "\u{1F}")
        let digest = SHA256.hash(data: Data(canonical.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return "DASHX_CAT_" + String(hex.prefix(14))
    }

    // MARK: - Delivered tracking

    /// Kicks off the delivered-tracking HTTP request and returns a semaphore that will be
    /// signalled on completion. Returns nil if the NSE Info.plist doesn't carry the
    /// required keys — in that case the caller simply skips waiting.
    ///
    /// The mutation mirrors the main SDK's `trackMessage` path (`DashXClient.trackMessage`):
    /// same mutation name, same `TrackMessageInput` fields (id/status/timestamp), same
    /// headers (`X-PUBLIC-KEY` uppercase, optional `X-TARGET-ENVIRONMENT`). Integrators
    /// that ship an NSE should add `DASHX_BASE_URI`, `DASHX_PUBLIC_KEY`, and optionally
    /// `DASHX_TARGET_ENVIRONMENT` to the extension's Info.plist with the same values
    /// the host app uses — the NSE runs in its own process and can't see the main app's
    /// runtime configuration.
    private func startTrackDelivered(notificationId: String) -> DispatchSemaphore? {
        guard let baseURL = Bundle.main.object(forInfoDictionaryKey: "DASHX_BASE_URI") as? String,
              let publicKey = Bundle.main.object(forInfoDictionaryKey: "DASHX_PUBLIC_KEY") as? String,
              let url = URL(string: baseURL)
        else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(publicKey, forHTTPHeaderField: "X-PUBLIC-KEY")
        if let targetEnvironment = Bundle.main.object(forInfoDictionaryKey: "DASHX_TARGET_ENVIRONMENT") as? String {
            request.setValue(targetEnvironment, forHTTPHeaderField: "X-TARGET-ENVIRONMENT")
        }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let mutation = """
        mutation TrackMessage($input: TrackMessageInput!) {
          trackMessage(input: $input) { success }
        }
        """
        let body: [String: Any] = [
            "query": mutation,
            "variables": [
                "input": [
                    "id": notificationId,
                    "status": "DELIVERED",
                    "timestamp": timestamp,
                ]
            ],
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let semaphore = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { _, _, _ in
            semaphore.signal()
        }.resume()
        return semaphore
    }

    // MARK: - Image attachment

    private func downloadAttachment(
        from url: URL,
        completion: @escaping (UNNotificationAttachment?) -> Void
    ) {
        URLSession.shared.downloadTask(with: url) { location, response, _ in
            guard let location else {
                completion(nil)
                return
            }
            // Enforce a media size cap. Servers report this via Content-Length in the
            // HTTPURLResponse; if they omit it we trust iOS to truncate. This is defence
            // against a malicious or misconfigured payload OOMing the NSE.
            if let expected = response?.expectedContentLength,
               expected > 0,
               expected > Self.maxMediaBytes
            {
                completion(nil)
                return
            }

            let contentType = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Type")
            let ext = Self.fileExtension(for: contentType, fallback: url.pathExtension)
            let uti = Self.uti(forMimeType: contentType, fallbackExtension: ext)

            let tmpURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(ext.isEmpty ? "dat" : ext)

            do {
                // iOS deletes the download location once this closure returns, so the
                // file must be moved before we construct the attachment.
                try FileManager.default.moveItem(at: location, to: tmpURL)
                var options: [String: Any] = [:]
                if let uti { options[UNNotificationAttachmentOptionsTypeHintKey] = uti }
                let attachment = try UNNotificationAttachment(
                    identifier: UUID().uuidString,
                    url: tmpURL,
                    options: options.isEmpty ? nil : options
                )
                completion(attachment)
            } catch {
                completion(nil)
            }
        }.resume()
    }

    /// Picks a file extension for the downloaded media so iOS can infer its type on disk.
    /// Prefers the server's Content-Type header; falls back to the URL path extension.
    private static func fileExtension(for contentType: String?, fallback: String) -> String {
        guard let primaryType = contentType?
            .split(separator: ";").first
            .map({ $0.trimmingCharacters(in: .whitespaces).lowercased() })
        else { return fallback }

        switch primaryType {
        case "image/jpeg", "image/jpg": return "jpg"
        case "image/png": return "png"
        case "image/gif": return "gif"
        case "image/heic": return "heic"
        case "image/webp": return "webp"
        case "video/mp4": return "mp4"
        case "audio/mpeg", "audio/mp3": return "mp3"
        default: return fallback
        }
    }

    /// Preferred UTI for the given MIME type. iOS uses this as the attachment's type hint
    /// when set, avoiding silent rejection when the file extension doesn't match the body.
    private static func uti(forMimeType mime: String?, fallbackExtension ext: String) -> String? {
        if let primary = mime?.split(separator: ";").first
            .map({ $0.trimmingCharacters(in: .whitespaces).lowercased() })
        {
            if let uti = UTTypeCreatePreferredIdentifierForTag(
                kUTTagClassMIMEType,
                primary as CFString,
                nil
            )?.takeRetainedValue() as String? {
                return uti
            }
        }
        if !ext.isEmpty,
           let uti = UTTypeCreatePreferredIdentifierForTag(
               kUTTagClassFilenameExtension,
               ext as CFString,
               nil
           )?.takeRetainedValue() as String?
        {
            return uti
        }
        return nil
    }
}
