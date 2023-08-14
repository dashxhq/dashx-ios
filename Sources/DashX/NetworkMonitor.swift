// Reference https://github.com/segmentio/analytics-swift/blob/main/Sources/Segment/Plugins/Platforms/Vendors/AppleUtils.swift
import Foundation
import SystemConfiguration

class NetworkMonitor {
    static let shared = NetworkMonitor()

    var connection: ConnectionStatus {
        return connectionStatus()
    }
}

internal enum ConnectionType {
    case cellular
    case wifi
    case bluetooth
}

internal enum ConnectionStatus {
    case offline
    case online(ConnectionType)
    case unknown
}

extension ConnectionStatus {
    init(reachabilityFlags flags: SCNetworkReachabilityFlags) {
        let connectionRequired = flags.contains(.connectionRequired)
        let isReachable = flags.contains(.reachable)
        let isCellular = flags.contains(.isWWAN)

        if !connectionRequired, isReachable {
            if isCellular {
                self = .online(.cellular)
            } else {
                self = .online(.wifi)
            }

        } else {
            self = .offline
        }
    }
}

internal func connectionStatus() -> ConnectionStatus {
    var zeroAddress = sockaddr_in()
    zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
    zeroAddress.sin_family = sa_family_t(AF_INET)

    guard let defaultRouteReachability = (withUnsafePointer(to: &zeroAddress) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
            SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
        }
    }) else {
        return .unknown
    }

    var flags: SCNetworkReachabilityFlags = []
    if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
        return .unknown
    }

    return ConnectionStatus(reachabilityFlags: flags)
}
