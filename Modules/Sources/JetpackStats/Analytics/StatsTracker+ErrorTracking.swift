import Foundation

extension StatsTracker {
    /// Convenience method to track errors with automatic type detection
    /// - Parameters:
    ///   - error: The error to track
    ///   - screen: The screen where the error occurred
    func trackError(_ error: Error, screen: String) {
        let errorType: String
        let errorCode = (error as NSError).code

        // Determine error type based on the error instance
        switch error {
        case let urlError as URLError:
            errorType = urlErrorType(urlError)
        case is DecodingError:
            errorType = "parsing"
        case is CancellationError:
            return
        default:
            errorType = (error as NSError).domain
        }

        send(.errorEncountered, properties: [
            "error_type": errorType,
            "error_code": "\(errorCode)",
            "screen": screen
        ])
    }

    /// Determine specific network error type
    private func urlErrorType(_ error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet: "network_offline"
        case .timedOut: "network_timeout"
        case .cannotFindHost, .cannotConnectToHost: "network_host_unreachable"
        case .networkConnectionLost: "network_connection_lost"
        case .dnsLookupFailed: "network_dns_failed"
        case .httpTooManyRedirects: "network_too_many_redirects"
        case .resourceUnavailable: "network_resource_unavailable"
        case .dataNotAllowed: "network_data_not_allowed"
        case .secureConnectionFailed: "network_ssl_failed"
        default: "other"
        }
    }
}
