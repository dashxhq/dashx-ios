import Foundation

struct Constants {
    static let PACKAGE_NAME = "com.dashx.sdk"
    static let USER_PREFERENCES_KEY_ACCOUNT_UID = "\(PACKAGE_NAME).account_uid"
    static let USER_PREFERENCES_KEY_ACCOUNT_ANONYMOUS_UID = "\(PACKAGE_NAME).account_anonymous_uid"
    static let USER_PREFERENCES_KEY_IDENTITY_TOKEN = "\(PACKAGE_NAME).identity_token"
    static let USER_PREFERENCES_KEY_DEVICE_TOKEN = "\(PACKAGE_NAME).device_token"
    static let USER_PREFERENCES_KEY_BUILD = "\(PACKAGE_NAME).build"
    static let INTERNAL_EVENT_APP_INSTALLED = "Application Installed"
    static let INTERNAL_EVENT_APP_UPDATED = "Application Updated"
    static let INTERNAL_EVENT_APP_OPENED = "Application Opened"
    static let INTERNAL_EVENT_APP_BACKGROUNDED = "Application Backgrounded"
    static let INTERNAL_EVENT_APP_CRASHED = "Application Crashed"
    static let INTERNAL_EVENT_APP_SCREEN_VIEWED = "Screen Viewed"
}

public struct UserAttributes {
    public static let UID = "uid"
    public static let ANONYMOUS_UID = "anonymousUid"
    public static let EMAIL = "email"
    public static let PHONE = "phone"
    public static let NAME = "name"
    public static let FIRST_NAME = "firstName"
    public static let LAST_NAME = "lastName"
}
