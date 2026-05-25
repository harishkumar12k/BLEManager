import Foundation
import Combine

public class BLEPeripheralViewModel: ObservableObject {
    @Published public var state: BLEPeripheralState = .unknown
    @Published public var receivedMessages: [String] = []
    @Published public var isAdvertising: Bool = false

    private let peripheralManager: BLEPeripheralManager

    public init(peripheralManager: BLEPeripheralManager = BLEPeripheralManager()) {
        self.peripheralManager = peripheralManager
        self.peripheralManager.delegate = self
    }

    public func toggleAdvertising() {
        if isAdvertising {
            peripheralManager.stopAdvertising()
        } else {
            peripheralManager.startAdvertising()
        }
    }
}

extension BLEPeripheralViewModel: BLEPeripheralManagerDelegate {
    public func didUpdateState(_ state: BLEPeripheralState) {
        DispatchQueue.main.async {
            self.state = state
            if case .advertising = state {
                self.isAdvertising = true
            } else {
                self.isAdvertising = false
            }
        }
    }

    public func didReceiveData(_ data: Data) {
        if let message = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.receivedMessages.append(message)
            }
        }
    }
}
