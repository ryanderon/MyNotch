import Foundation
import IOBluetooth

/// Wraps IOBluetooth connect/disconnect notifications. Only registered while the Bluetooth live activity is on.
/// Battery levels of AirPods are not exposed by any public API, so events carry the name and kind only.
final class BluetoothService: NSObject {
    var deviceEventDidOccur: ((BluetoothDeviceEvent) -> Void)?

    private var connectNotification: IOBluetoothUserNotification?
    private var disconnectNotifications: [String: IOBluetoothUserNotification] = [:]

    /// Registering for connect notifications immediately reports every device that is already connected;
    /// those are remembered here so launching the app doesn't look like a burst of new connections.
    private var alreadyConnectedAddresses: Set<String> = []

    var isRunning: Bool { connectNotification != nil }

    func start() {
        guard connectNotification == nil else { return }
        let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? []
        alreadyConnectedAddresses = Set(pairedDevices.filter { $0.isConnected() }.compactMap(\.addressString))
        connectNotification = IOBluetoothDevice.register(
            forConnectNotifications: self,
            selector: #selector(deviceDidConnect(_:device:))
        )
    }

    func stop() {
        connectNotification?.unregister()
        connectNotification = nil
        disconnectNotifications.values.forEach { $0.unregister() }
        disconnectNotifications = [:]
        alreadyConnectedAddresses = []
    }

    @objc private func deviceDidConnect(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        guard let address = device.addressString else { return }
        disconnectNotifications[address] = device.register(
            forDisconnectNotification: self,
            selector: #selector(deviceDidDisconnect(_:device:))
        )
        if alreadyConnectedAddresses.remove(address) == nil {
            publish(device, isConnected: true)
        }
    }

    @objc private func deviceDidDisconnect(_ notification: IOBluetoothUserNotification, device: IOBluetoothDevice) {
        if let address = device.addressString {
            disconnectNotifications[address]?.unregister()
            disconnectNotifications[address] = nil
        }
        publish(device, isConnected: false)
    }

    private func publish(_ device: IOBluetoothDevice, isConnected: Bool) {
        deviceEventDidOccur?(BluetoothDeviceEvent(
            deviceName: device.name ?? "Bluetooth device",
            deviceKind: Self.kind(of: device),
            isConnected: isConnected
        ))
    }

    private static func kind(of device: IOBluetoothDevice) -> BluetoothDeviceEvent.DeviceKind {
        let major = Int(device.deviceClassMajor)
        let minor = Int(device.deviceClassMinor)
        if major == kBluetoothDeviceClassMajorAudio { return .headphones }
        guard major == kBluetoothDeviceClassMajorPeripheral else { return .other }
        // Peripheral minor classes are bit fields: 0x10 keyboard, 0x20 pointing device.
        if minor & 0x10 != 0 { return .keyboard }
        if minor & 0x20 != 0 { return .mouse }
        return .other
    }
}
