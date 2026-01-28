import Foundation

/// Options specific to certain top list item types.
///
/// Different item types use different options:
/// - `.locations`: Uses `locationLevel` to determine granularity (countries, regions, cities)
/// - `.devices`: Uses `deviceBreakdown` to determine breakdown type (screensize, platform, browser)
/// - Other item types: These options are ignored
struct TopListItemOptions: Equatable, Sendable, Codable, Hashable {
    /// The granularity level for location data.
    /// Only applies to `.locations` item type.
    var locationLevel: LocationLevel

    /// The breakdown type for device data.
    /// Only applies to `.devices` item type.
    var deviceBreakdown: DeviceBreakdown

    init(
        locationLevel: LocationLevel = .countries,
        deviceBreakdown: DeviceBreakdown = .screensize
    ) {
        self.locationLevel = locationLevel
        self.deviceBreakdown = deviceBreakdown
    }
}
