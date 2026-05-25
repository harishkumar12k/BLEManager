import Foundation
import CoreBluetooth
import Combine

public enum BLEPeripheralState {
    case unknown
    case poweredOn
    case poweredOff
    case advertising
    case error(String)
}

public protocol BLEPeripheralManagerDelegate: AnyObject {
    func didUpdateState(_ state: BLEPeripheralState)
    func didReceiveData(_ data: Data)
}

public protocol CBPeripheralManagerProtocol: AnyObject {
    var state: CBManagerState { get }
    func add(_ service: CBMutableService)
    func startAdvertising(_ advertisementData: [String: Any]?)
    func stopAdvertising()
    func respond(to request: CBATTRequest, withResult result: CBATTError.Code)
    func updateValue(_ value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CBCentral]?) -> Bool
}

extension CBPeripheralManager: CBPeripheralManagerProtocol {}

public class BLEPeripheralManager: NSObject {
    private var peripheralManager: CBPeripheralManagerProtocol?
    private var echoCharacteristic: CBMutableCharacteristic?

    public weak var delegate: BLEPeripheralManagerDelegate?

    private let serviceUUID = CBUUID(string: "1234")
    private let characteristicUUID = CBUUID(string: "5678")

    public init(peripheralManager: CBPeripheralManagerProtocol? = nil) {
        super.init()
        if let manager = peripheralManager {
            self.peripheralManager = manager
        } else {
            // In a real app, we'd need to handle the delegate assignment carefully
            // since CBPeripheralManager(delegate:queue:) is the standard way.
            self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        }
    }

    public func startAdvertising() {
        guard peripheralManager?.state == .poweredOn else {
            delegate?.didUpdateState(.error("Peripheral not powered on"))
            return
        }

        echoCharacteristic = CBMutableCharacteristic(
            type: characteristicUUID,
            properties: [.read, .write, .notify],
            value: nil,
            permissions: [.readable, .writeable]
        )

        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [echoCharacteristic!]

        peripheralManager?.add(service)

        let advertisementData: [String: Any] = [
            CBAdvertisementDataLocalNameKey: "EchoPeripheral",
            CBAdvertisementDataServiceUUIDsKey: [serviceUUID]
        ]
        peripheralManager?.startAdvertising(advertisementData)
        delegate?.didUpdateState(.advertising)
    }

    public func stopAdvertising() {
        peripheralManager?.stopAdvertising()
        delegate?.didUpdateState(.poweredOn)
    }
}

extension BLEPeripheralManager: CBPeripheralManagerDelegate {
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            delegate?.didUpdateState(.poweredOn)
        case .poweredOff:
            delegate?.didUpdateState(.poweredOff)
        default:
            delegate?.didUpdateState(.unknown)
        }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if request.characteristic.uuid == characteristicUUID {
            request.value = "Echoing data".data(using: .utf8)
            peripheralManager?.respond(to: request, withResult: .success)
        } else {
            peripheralManager?.respond(to: request, withResult: .attributeNotFound)
        }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == characteristicUUID, let data = request.value {
                delegate?.didReceiveData(data)
                if let echoCharacteristic = echoCharacteristic {
                    _ = peripheralManager?.updateValue(data, for: echoCharacteristic, onSubscribedCentrals: nil)
                }
            }
        }
    }
}
