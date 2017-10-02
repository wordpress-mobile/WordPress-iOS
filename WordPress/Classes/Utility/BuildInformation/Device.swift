/// Runtime information about the current device.
///
@objc
class Device: NSObject {
    @objc
    enum DeviceType: Int {
        case simulator
        case physical
    }

    @objc
    static func `is`(_ type: DeviceType) -> Bool {
        return type == deviceType()
    }

    private static func deviceType() -> DeviceType {
        if let overriddenDeviceType = overriddenDeviceType {
            return overriddenDeviceType
        }

        #if TARGET_OS_SIMULATOR
            return .simulator
        #else
            return .physical
        #endif
    }

    /// For testing purposes only
    private static var overriddenDeviceType: DeviceType? = nil

    @objc
    static func overrideDeviceType(_ deviceType: DeviceType) {
        overriddenDeviceType = deviceType
    }

    @objc
    static func clearDeviceTypeOverride() {
        overriddenDeviceType = nil
    }
}
