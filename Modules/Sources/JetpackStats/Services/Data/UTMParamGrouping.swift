import Foundation

enum UTMParamGrouping: String, Identifiable, CaseIterable, Sendable, Codable {
    case sourceMedium
    case campaignSourceMedium
    case source
    case medium
    case campaign

    var id: UTMParamGrouping { self }

    var localizedTitle: String {
        switch self {
        case .sourceMedium: Strings.UTMParamGroupings.sourceMedium
        case .campaignSourceMedium: Strings.UTMParamGroupings.campaignSourceMedium
        case .source: Strings.UTMParamGroupings.source
        case .medium: Strings.UTMParamGroupings.medium
        case .campaign: Strings.UTMParamGroupings.campaign
        }
    }

    var analyticsName: String {
        rawValue
    }

    /// Returns true if this grouping represents aggregated values
    var isAggregated: Bool {
        switch self {
        case .sourceMedium, .campaignSourceMedium:
            return true
        case .source, .medium, .campaign:
            return false
        }
    }

    /// Returns grouped options for display in a picker
    static var grouped: [[UTMParamGrouping]] {
        [
            // Aggregated values in first section
            allCases.filter { $0.isAggregated },
            // Simple values in second section
            allCases.filter { !$0.isAggregated }
        ]
    }
}
