// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BLEPeripheral",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "BLEPeripheral",
            targets: ["BLEPeripheral"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BLEPeripheral",
            dependencies: []),
        .testTarget(
            name: "BLEPeripheralTests",
            dependencies: ["BLEPeripheral"]),
    ]
)
