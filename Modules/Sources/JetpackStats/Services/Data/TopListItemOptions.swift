import Foundation

/// Options specific to certain top list item types.
///
/// Different item types use different options:
/// - `.locations`: Uses `locationLevel` to determine granularity (countries, regions, cities)
/// - `.devices`: Uses `deviceBreakdown` to determine breakdown type (screensize, platform, browser)
/// - `.utm`: Uses `utmParamGrouping` to determine UTM parameter grouping (source/medium, campaign, etc.)
/// - Other item types: These options are ignored
struct TopListItemOptions: Equatable, Sendable, Codable, Hashable {
    /// The granularity level for location data.
    /// Only applies to `.locations` item type.
    var locationLevel: LocationLevel

    /// The breakdown type for device data.
    /// Only applies to `.devices` item type.
    var deviceBreakdown: DeviceBreakdown

    /// The UTM parameter grouping.
    /// Only applies to `.utm` item type.
    var utmParamGrouping: UTMParamGrouping

    init(
        locationLevel: LocationLevel = .countries,
        deviceBreakdown: DeviceBreakdown = .screensize,
        utmParamGrouping: UTMParamGrouping = .sourceMedium
    ) {
        self.locationLevel = locationLevel
        self.deviceBreakdown = deviceBreakdown
        self.utmParamGrouping = utmParamGrouping
    }
}
