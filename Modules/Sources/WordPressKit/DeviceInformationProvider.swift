import Foundation

/// Device metadata needed for push notification registration.
///
/// This protocol decouples networking code from UIKit, allowing WordPressKit to build on macOS.
/// On iOS, `UIDevice` conforms to this protocol automatically.
public protocol DeviceInformationProvider {
    var name: String { get }
    var systemVersion: String { get }
    var identifierForVendor: UUID? { get }
}

extension DeviceInformationProvider {
    /// The hardware machine identifier (e.g. "iPhone15,2", "Mac14,6").
    public var hardwarePlatform: String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }
}

#if canImport(UIKit)
import UIKit

extension UIDevice: DeviceInformationProvider {}
#endif
