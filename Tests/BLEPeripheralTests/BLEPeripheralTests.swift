import XCTest
import Combine
import CoreBluetooth
@testable import BLEPeripheral

final class BLEPeripheralTests: XCTestCase {
    var viewModel: BLEPeripheralViewModel!
    var mockPeripheralManager: MockCBPeripheralManager!
    var peripheralService: BLEPeripheralManager!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockPeripheralManager = MockCBPeripheralManager()
        peripheralService = BLEPeripheralManager(peripheralManager: mockPeripheralManager)
        viewModel = BLEPeripheralViewModel(peripheralManager: peripheralService)
        cancellables = []
    }

    override func tearDown() {
        viewModel = nil
        peripheralService = nil
        mockPeripheralManager = nil
        cancellables = nil
        super.tearDown()
    }

    func testInitialStateIsUnknown() {
        XCTAssertEqual(viewModel.state, .unknown)
        XCTAssertFalse(viewModel.isAdvertising)
    }

    func testUpdateStateToPoweredOn() {
        let expectation = XCTestExpectation(description: "State updates to poweredOn")

        viewModel.$state
            .dropFirst()
            .sink { state in
                if case .poweredOn = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // Manually trigger delegate call since we can't easily trigger CBPeripheralManagerDelegate
        peripheralService.delegate?.didUpdateState(.poweredOn)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(viewModel.isAdvertising)
    }

    func testToggleAdvertisingOn() {
        mockPeripheralManager.mockState = .poweredOn

        viewModel.toggleAdvertising()

        XCTAssertTrue(mockPeripheralManager.startAdvertisingCalled)
        XCTAssertEqual(viewModel.state, .advertising)
        XCTAssertTrue(viewModel.isAdvertising)
    }

    func testReceiveData() {
        let expectation = XCTestExpectation(description: "Received messages updates")
        let testMessage = "Hello BLE"
        let data = testMessage.data(using: .utf8)!

        viewModel.$receivedMessages
            .dropFirst()
            .sink { messages in
                if messages.contains(testMessage) {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        peripheralService.delegate?.didReceiveData(data)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(viewModel.receivedMessages.last, testMessage)
    }
}

class MockCBPeripheralManager: CBPeripheralManagerProtocol {
    var mockState: CBManagerState = .unknown
    var state: CBManagerState { return mockState }

    var addCalled = false
    var startAdvertisingCalled = false
    var stopAdvertisingCalled = false
    var respondCalled = false
    var updateValueCalled = false

    func add(_ service: CBMutableService) {
        addCalled = true
    }

    func startAdvertising(_ advertisementData: [String: Any]?) {
        startAdvertisingCalled = true
    }

    func stopAdvertising() {
        stopAdvertisingCalled = true
    }

    func respond(to request: CBATTRequest, withResult result: CBATTError.Code) {
        respondCalled = true
    }

    func updateValue(_ value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CBCentral]?) -> Bool {
        updateValueCalled = true
        return true
    }
}

extension BLEPeripheralState: Equatable {
    public static func == (lhs: BLEPeripheralState, rhs: BLEPeripheralState) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown), (.poweredOn, .poweredOn), (.poweredOff, .poweredOff), (.advertising, .advertising):
            return true
        case (.error(let l), .error(let r)):
            return l == r
        default:
            return false
        }
    }
}
