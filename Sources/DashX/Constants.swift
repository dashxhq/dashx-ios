import Foundation

public struct Constants {
    /// Reverse-DNS namespace used to derive stable `UserDefaults` keys (APNs token,
    /// identity token, FCM token, etc.). Changing this value would re-key every
    /// user's persisted state and appear as a silent logout — do not change without
    /// a migration.
    static let PACKAGE_NAME = "com.dashx.ios"

    /// Analytics / telemetry library identifier sent in `SystemContext.library.name`
    /// and the subscribe-contact metadata. Matches the slug convention used by the
    /// Android SDK (`dashx-android`) and most analytics SDKs — keep these aligned
    /// across platforms so dashboard filters work uniformly.
    static let LIBRARY_NAME = "dashx-ios"

    static let PACKAGE_VERSION = "1.5.1"
    public static let USER_PREFERENCES_KEY_ACCOUNT_UID = "\(PACKAGE_NAME).account_uid"
    public static let USER_PREFERENCES_KEY_ACCOUNT_ANONYMOUS_UID = "\(PACKAGE_NAME).account_anonymous_uid"
    public static let USER_PREFERENCES_KEY_IDENTITY_TOKEN = "\(PACKAGE_NAME).identity_token"
    public static let USER_PREFERENCES_KEY_APNS_TOKEN = "\(PACKAGE_NAME).apns_token"
    public static let USER_PREFERENCES_KEY_FCM_TOKEN = "\(PACKAGE_NAME).fcm_token"
    public static let USER_PREFERENCES_KEY_SUBSCRIBED_LIBRARY_VERSION = "\(PACKAGE_NAME).subscribed_library_version"
    public static let USER_PREFERENCES_KEY_BUILD = "\(PACKAGE_NAME).build"
    public static let INTERNAL_EVENT_APP_INSTALLED = "Application Installed"
    public static let INTERNAL_EVENT_APP_UPDATED = "Application Updated"
    public static let INTERNAL_EVENT_APP_OPENED = "Application Opened"
    public static let INTERNAL_EVENT_APP_BACKGROUNDED = "Application Backgrounded"
    public static let INTERNAL_EVENT_APP_CRASHED = "Application Crashed"
    public static let INTERNAL_EVENT_APP_SCREEN_VIEWED = "Screen Viewed"
    /// Emitted when a deep link URL is processed (push, universal link, custom scheme, etc.).
    public static let EVENT_DEEP_LINK_OPENED = "dx_deep_link_opened"
    /// Emitted on every notification tap regardless of navigation type (deep link, screen, click action, etc.).
    public static let EVENT_NOTIFICATION_NAVIGATED = "dx_notification_navigated"
    public static let CONTENT_TYPE = "Content-Type"
    public static let GCS_ASSET_UPLOAD_HEADER_KEY = "x-goog-meta-origin-id"
    public static let DASHX_NOTIFICATION_DATA_KEY = "dashx"
    public static let DASHX_NOTIFICATION_CATEGORY_IDENTIFIER = "DASHX_NOTIFICATION"
}

public enum UserAttributes {
    public static let UID = "uid"
    public static let ANONYMOUS_UID = "anonymousUid"
    public static let EMAIL = "email"
    public static let PHONE = "phone"
    public static let NAME = "name"
    public static let FIRST_NAME = "firstName"
    public static let LAST_NAME = "lastName"
}

public enum HttpMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
