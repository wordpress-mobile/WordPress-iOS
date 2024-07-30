import Foundation

// TODO: Add support for NWPathMonitor for network conditions
//
actor ResourceMonitor {

    private let device: UIDevice

    init(device: UIDevice) {
        self.device = device
    }

    enum PreloadPolicy: Int {
        case none       = 0
        case minimal    = 1
        case normal     = 2
        case aggressive = 5

        init(withRawValue rawValue: Int) {
            if let match = PreloadPolicy(rawValue: rawValue) {
                self = match
            }

            if rawValue < 5 {
                self = .normal
            } else {
                self = .aggressive
            }
        }

        static func forBatteryChargeLevel(_ amount: Float) -> PreloadPolicy {
            return switch amount {
            case 0.00 ..< 0.25: .none
            case 0.26 ..< 0.50: .minimal
            case 0.51 ..< 0.75: .normal
            case 0.76 ..< 1.00: .aggressive
            default: .normal
            }
        }

        static func forUserInterfaceIdiom(_ idiom: UIUserInterfaceIdiom) -> PreloadPolicy {
            return switch idiom {
            case .unspecified: .normal
            case .phone: .normal
            case .pad: .normal
            case .tv: .aggressive        // Always plugged in
            case .carPlay: .normal
            case .mac: .aggressive       // Big battery and big screen
            case .vision: .normal
            @unknown default: .normal
            }
        }

        static func forPowerState(_ state: UIDevice.BatteryState) -> PreloadPolicy {
            return switch state {
                case .unknown: .minimal
                case .unplugged: .normal
                case .charging: .aggressive
                case .full: .aggressive
                @unknown default: .normal
            }
        }

        static func forDeviceFreeSpace(_ amount: Measurement<UnitInformationStorage>) -> PreloadPolicy {
            return switch amount {
            case Measurement.gigabytes(0) ..< Measurement.gigabytes(0.25): .none
            case Measurement.gigabytes(0.26) ..< Measurement.gigabytes(0.999): .minimal
            case Measurement.gigabytes(1) ..< Measurement.gigabytes(4): .normal
            case Measurement.gigabytes(4) ..< Measurement.gigabytes(256): .aggressive
            default: .normal
            }
        }
    }

    var recommended: PreloadPolicy {
        get async throws {
            let policies = [
                PreloadPolicy.forPowerState(await device.batteryState),
                PreloadPolicy.forBatteryChargeLevel(await device.batteryLevel),
                PreloadPolicy.forUserInterfaceIdiom(await device.userInterfaceIdiom),
                PreloadPolicy.forDeviceFreeSpace(try diskFreeSpace)
            ]

            let average = policies
                .reduce(into: 0) { $0 = $0 + $1.rawValue }
                .quotientAndRemainder(dividingBy: policies.count)

            return PreloadPolicy(rawValue: average.quotient)!
        }
    }

    var diskFreeSpace: Measurement<UnitInformationStorage> {
        get throws {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            let doubleValue = (attributes[FileAttributeKey.systemFreeSize] as! NSNumber).doubleValue
            return Measurement(value: doubleValue, unit: .bytes)
        }
    }

    var diskTotalSpace: Measurement<UnitInformationStorage> {
        get throws {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
            let doubleValue = (attributes[FileAttributeKey.systemSize] as! NSNumber).doubleValue
            return Measurement(value: doubleValue, unit: .bytes)
        }
    }
}

extension Measurement<UnitInformationStorage> {
    static func gigabytes(_ number: Double) -> Measurement<UnitInformationStorage> {
        Measurement(value: number, unit: .gigabytes)
    }
}
