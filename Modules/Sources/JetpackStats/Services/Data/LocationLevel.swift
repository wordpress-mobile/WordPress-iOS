import Foundation

enum LocationLevel: String, Identifiable, CaseIterable, Sendable, Codable {
    case countries
    case regions
    case cities

    var id: LocationLevel { self }

    var localizedTitle: String {
        switch self {
        case .countries: Strings.LocationLevels.countries
        case .regions: Strings.LocationLevels.regions
        case .cities: Strings.LocationLevels.cities
        }
    }

    var systemImage: String {
        switch self {
        case .countries: "flag"
        case .regions: "map"
        case .cities: "building.2"
        }
    }

    var analyticsName: String {
        rawValue
    }
}
