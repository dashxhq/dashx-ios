// Reference https://github.com/segmentio/analytics-swift/blob/main/Sources/Segment/Plugins/Platforms/Vendors/AppleUtils.swift
import Foundation
import Network

extension Notification.Name {
    static let dashXNetworkBecameAvailable = Notification.Name("com.dashx.networkBecameAvailable")
}

class NetworkMonitor {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.dashx.networkmonitor")
    private let lock = NSLock()
    private var currentStatus: ConnectionStatus = .unknown

    var connection: ConnectionStatus {
        lock.lock()
        defer { lock.unlock() }
        return currentStatus
    }

    private init() {
        currentStatus = ConnectionStatus(path: monitor.currentPath)
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let nextStatus = ConnectionStatus(path: path)
            self.lock.lock()
            let previousStatus = self.currentStatus
            self.currentStatus = nextStatus
            self.lock.unlock()

            if case .online = nextStatus, !previousStatus.isOnline {
                NotificationCenter.default.post(name: .dashXNetworkBecameAvailable, object: nil)
            }
        }
        monitor.start(queue: queue)
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

    var isOnline: Bool {
        if case .online = self { return true }
        return false
    }
}

extension ConnectionStatus {
    init(path: NWPath) {
        guard path.status == .satisfied else {
            self = .offline
            return
        }
        if path.usesInterfaceType(.cellular) {
            self = .online(.cellular)
        } else if path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet) {
            self = .online(.wifi)
        } else if path.usesInterfaceType(.other) {
            self = .online(.bluetooth)
        } else {
            self = .unknown
        }
    }
}
