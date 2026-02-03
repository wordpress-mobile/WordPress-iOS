import Foundation

enum DeviceBreakdown: String, Identifiable, CaseIterable, Sendable, Codable {
    case screensize
    case browser
    case platform

    var id: DeviceBreakdown { self }

    var localizedTitle: String {
        switch self {
        case .screensize: Strings.DeviceBreakdowns.screensize
        case .browser: Strings.DeviceBreakdowns.browser
        case .platform: Strings.DeviceBreakdowns.platform
        }
    }

    var systemImage: String {
        switch self {
        case .screensize: "laptopcomputer.and.iphone"
        case .browser: "safari"
        case .platform: "square.stack.3d.up"
        }
    }

    var analyticsName: String {
        rawValue
    }
}
