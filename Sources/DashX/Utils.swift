import Foundation
import MobileCoreServices

extension URL {
    func mimeType() -> String {
        let url = NSURL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
}

let swizzler: (AnyClass, AnyClass, Selector, Selector) -> Void = { mainClass, swizzledClass, originalSelector, swizzledSelector in
    guard let swizzledMethod = class_getInstanceMethod(swizzledClass, swizzledSelector) else {
        return
    }

    if let originalMethod = class_getInstanceMethod(mainClass, originalSelector) {
        method_exchangeImplementations(originalMethod, swizzledMethod)
    } else {
        class_addMethod(mainClass, swizzledSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
    }
}

extension String {
    func convertToDictionary() -> [String: Any]? {
        if let data = data(using: .utf8) {
            return (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
        }
        return nil
    }
}
