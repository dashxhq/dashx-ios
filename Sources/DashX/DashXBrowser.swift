import SafariServices
import UIKit

/// In-app browser helpers for notification "rich landing" URLs.
public enum DashXBrowser {
    /// Optional hook to customize the ``SFSafariViewController`` before it is presented
    /// (e.g. set `preferredBarTintColor`, `dismissButtonStyle`, etc.).
    public static var safariConfiguration: ((SFSafariViewController) -> Void)?

    /// Presents `url` in ``SFSafariViewController`` when a presenter can be found; otherwise opens the URL with the system handler.
    public static func presentRichLanding(url: URL, from presenter: UIViewController? = nil) {
        let safari = SFSafariViewController(url: url)
        safari.modalPresentationStyle = .pageSheet
        safariConfiguration?(safari)
        guard let host = presenter ?? topViewController() else {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return
        }
        host.present(safari, animated: true)
    }

    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            for window in scene.windows where window.isKeyWindow {
                if let root = window.rootViewController {
                    return topViewController(from: root)
                }
            }
        }
        if let scene = scenes.first, let root = scene.windows.first?.rootViewController {
            return topViewController(from: root)
        }
        return nil
    }

    private static func topViewController(from root: UIViewController?) -> UIViewController? {
        if let presented = root?.presentedViewController {
            return topViewController(from: presented)
        }
        if let nav = root as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        return root
    }
}
