import AdSupport
import AppTrackingTransparency
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

extension Data {
    var string: String {
        return map { String(format: "%02.2hhx", $0) }.joined()
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

func getIPAddress() -> (ipV4: String?, ipV6: String?) {
    var ipv4Address: String?
    var ipv6Address: String?

    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0,
          let firstAddr = ifaddr
    else {
        return (ipv4Address, ipv6Address)
    }

    for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
        let interface = ifptr.pointee
        let name = String(cString: interface.ifa_name)
        if ["en0", "en2", "en3", "en4", "pdp_ip0", "pdp_ip1", "pdp_ip2", "pdp_ip3"].contains(name) {
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            getnameinfo(
                interface.ifa_addr,
                socklen_t(interface.ifa_addr.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                socklen_t(0),
                NI_NUMERICHOST
            )
            if let address = String(cString: hostname).split(separator: "%").first {
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET), ipv4Address == nil {
                    ipv4Address = "\(address)"
                }
                if addrFamily == UInt8(AF_INET6), ipv6Address == nil {
                    ipv6Address = "\(address)"
                }
            }
            if ipv4Address != nil, ipv6Address != nil {
                break
            }
        }
    }
    freeifaddrs(ifaddr)
    return (ipv4Address, ipv6Address)
}

func generateMuxVideoUrl(playbackId: String) -> String {
    return "https://stream.mux.com/$\(playbackId).m3u8"
}
