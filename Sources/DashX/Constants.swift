import Foundation

public struct Constants {
    static let PACKAGE_NAME = "com.dashx.sdk"
    static let PACKAGE_VERSION = "1.0.19"
    public static let USER_PREFERENCES_KEY_ACCOUNT_UID = "\(PACKAGE_NAME).account_uid"
    public static let USER_PREFERENCES_KEY_ACCOUNT_ANONYMOUS_UID = "\(PACKAGE_NAME).account_anonymous_uid"
    public static let USER_PREFERENCES_KEY_IDENTITY_TOKEN = "\(PACKAGE_NAME).identity_token"
    public static let USER_PREFERENCES_KEY_APNS_TOKEN = "\(PACKAGE_NAME).apns_token"
    public static let USER_PREFERENCES_KEY_FCM_TOKEN = "\(PACKAGE_NAME).fcm_token"
    public static let USER_PREFERENCES_KEY_BUILD = "\(PACKAGE_NAME).build"
    public static let INTERNAL_EVENT_APP_INSTALLED = "Application Installed"
    public static let INTERNAL_EVENT_APP_UPDATED = "Application Updated"
    public static let INTERNAL_EVENT_APP_OPENED = "Application Opened"
    public static let INTERNAL_EVENT_APP_BACKGROUNDED = "Application Backgrounded"
    public static let INTERNAL_EVENT_APP_CRASHED = "Application Crashed"
    public static let INTERNAL_EVENT_APP_SCREEN_VIEWED = "Screen Viewed"
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
