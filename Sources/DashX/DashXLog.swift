import Foundation
import os.log

public class DashXLog {
    public enum LogLevel: Int {
        case debug = 2
        case info = 1
        case error = 0
        case off = -1

        static func >= (lhs: Self, rhs: Self) -> Bool {
            return lhs.rawValue >= rhs.rawValue
        }
    }

    static private var logLevel: LogLevel = .off

    static public func setLogLevel(to: LogLevel) {
        self.logLevel = to
    }

    static func d(tag: String, _ data: String) {
        if logLevel >= .debug {
            if #available(iOS 10.0, *) {
                os_log("%@: %@", type: .debug, tag, data)
            } else {
                print("[DEBUG] %@: %@", tag, data)
            }
        }
    }

    static func i(tag: String, _ data: String) {
        if logLevel >= .info {
            if #available(iOS 10.0, *) {
                os_log("%@: %@", type: .info, tag, data)
            } else {
                print("[INFO] %@: %@", tag, data)
            }
        }
    }

    static func e(tag: String, _ data: String) {
        if logLevel >= .error {
            if #available(iOS 10.0, *) {
                os_log("%@: %@", type: .error, tag, data)
            } else {
                print("[ERROR] %@: %@", tag, data)
            }
        }
    }
}
