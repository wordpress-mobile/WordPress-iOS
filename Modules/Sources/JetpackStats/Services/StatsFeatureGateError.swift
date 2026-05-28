import Foundation
@preconcurrency import WordPressKit

/// Error indicating a stats feature is gated behind a paid plan
struct StatsFeatureGateError: LocalizedError, Sendable {
    let message: String
    let itemType: TopListItemType

    var errorDescription: String? {
        message
    }

    /// Analytics-friendly feature name
    var featureName: String {
        switch itemType {
        case .utm:
            return "utm_stats"
        case .devices:
            return "device_stats"
        case .locations:
            return "location_breakdown"
        default:
            return itemType.rawValue
        }
    }

    /// Creates a feature gate error from an API error response
    /// - Parameters:
    ///   - apiError: The error from the API
    ///   - itemType: The item type that was requested when the error occurred
    /// - Returns: A StatsFeatureGateError if the error indicates a gated feature, nil otherwise
    static func from(apiError: Error, itemType: TopListItemType) -> StatsFeatureGateError? {
        guard let wpError = apiError as? WordPressAPIError<WordPressComRestApiEndpointError>,
              case .endpointError(let endpointError) = wpError else {
            return nil
        }
        guard endpointError.apiErrorCode == "unauthorized",
              let message = endpointError.apiErrorMessage else {
            return nil
        }
        return StatsFeatureGateError(message: message, itemType: itemType)
    }
}
