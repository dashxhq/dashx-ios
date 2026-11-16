import AdSupport
import AppTrackingTransparency
import Foundation
import UniformTypeIdentifiers
#if canImport(MobileCoreServices)
import MobileCoreServices
#endif

extension URL {
    func mimeType() -> String {
        let pathExtension = self.pathExtension
        guard !pathExtension.isEmpty else {
            return "application/octet-stream"
        }

        if #available(iOS 14.0, *) {
            if let mimeType = UTType(filenameExtension: pathExtension)?.preferredMIMEType {
                return mimeType
            }
        } else if let uti = UTTypeCreatePreferredIdentifierForTag(
            kUTTagClassFilenameExtension,
            pathExtension as NSString,
            nil
        )?.takeRetainedValue(),
            let mimeType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue()
        {
            return mimeType as String
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
    var ifaddr: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
        return (nil, nil)
    }
    defer { freeifaddrs(ifaddr) }
    return ipAddresses(from: firstAddr)
}

private let ipInterfaceNames: Set<String> = ["en0", "en2", "en3", "en4", "pdp_ip0", "pdp_ip1", "pdp_ip2", "pdp_ip3"]

/// The first IPv4 and IPv6 address on a Wi-Fi or cellular interface. `getifaddrs` may list an
/// interface with a null `ifa_addr`, and dereferencing it is a fatal error no caller can catch.
func ipAddresses(from firstAddr: UnsafeMutablePointer<ifaddrs>) -> (ipV4: String?, ipV6: String?) {
    var ipv4Address: String?
    var ipv6Address: String?

    for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
        let interface = ifptr.pointee
        guard let namePointer = interface.ifa_name,
              ipInterfaceNames.contains(String(cString: namePointer)),
              let address = interface.ifa_addr
        else { continue }

        let family = address.pointee.sa_family
        let isIPv4 = family == UInt8(AF_INET)
        guard isIPv4 || family == UInt8(AF_INET6) else { continue }
        let alreadyFound = isIPv4 ? ipv4Address != nil : ipv6Address != nil
        guard !alreadyFound else { continue }

        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let status = getnameinfo(
            address,
            socklen_t(address.pointee.sa_len),
            &hostname,
            socklen_t(hostname.count),
            nil,
            socklen_t(0),
            NI_NUMERICHOST
        )
        guard status == 0, let host = String(cString: hostname).split(separator: "%").first else { continue }

        if isIPv4 {
            ipv4Address = String(host)
        } else {
            ipv6Address = String(host)
        }
        if ipv4Address != nil, ipv6Address != nil { break }
    }
    return (ipv4Address, ipv6Address)
}

func generateMuxVideoUrl(playbackId: String) -> String {
    return "https://stream.mux.com/\(playbackId).m3u8"
}
