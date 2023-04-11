import CoreBluetooth
import Foundation

// Stop monitoring when there is no need
class BluetoothMonitor: NSObject {
    static let shared = BluetoothMonitor()

    private var cbCentralManager: CBCentralManager?

    override init() {
        super.init()

        if isBluetoothUsagePermissionDescriptionPresent {
            cbCentralManager = CBCentralManager()
            cbCentralManager!.delegate = self
        }
    }

    var isBluetoothEnabled: Bool {
        if isBluetoothUsagePermissionDescriptionPresent {
            return cbCentralManager!.state == .poweredOn
        }

        return false
    }

    private var isBluetoothUsagePermissionDescriptionPresent: Bool {
        Bundle.main.object(forInfoDictionaryKey: Constants.BLUETOOTH_USAGE_PERMISSION_DESCRIPTION_KEY) != nil
    }
}

extension BluetoothMonitor: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        cbCentralManager = central
    }
}
