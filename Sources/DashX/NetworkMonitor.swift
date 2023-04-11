import Foundation
import Network

// Stop monitoring when there is no need
class NetworkMonitor {
    static let shared = NetworkMonitor()

    let monitor = NWPathMonitor()
    private var status: NWPath.Status = .requiresConnection
    var isReachable: Bool { status == .satisfied }
    var isReachableOnCellular: Bool = false
    var isReachableOnWifi: Bool = false

    init() {
        startMonitoring()
    }

    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.status = path.status
            guard !path.isExpensive else {
                self?.isReachableOnCellular = path.isExpensive
                return
            }
            if path.usesInterfaceType(.cellular) {
                self?.isReachableOnCellular = path.status == .satisfied
            } else if path.usesInterfaceType(.wifi) {
                self?.isReachableOnWifi = path.status == .satisfied
            } else {}
        }

        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }

    func stopMonitoring() {
        monitor.cancel()
    }
}
