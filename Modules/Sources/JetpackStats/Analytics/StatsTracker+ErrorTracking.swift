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
            errorType = "cancelled"
        default:
            // Check for common error domains
            let nsError = error as NSError
            switch nsError.domain {
            case NSCocoaErrorDomain:
                errorType = "cocoa_\(errorCode)"
            case NSURLErrorDomain:
                errorType = "url_\(errorCode)"
            default:
                errorType = "unknown"
            }
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
        case .notConnectedToInternet:
            return "network_offline"
        case .timedOut:
            return "network_timeout"
        case .cannotFindHost, .cannotConnectToHost:
            return "network_host_unreachable"
        case .networkConnectionLost:
            return "network_connection_lost"
        case .dnsLookupFailed:
            return "network_dns_failed"
        case .httpTooManyRedirects:
            return "network_too_many_redirects"
        case .resourceUnavailable:
            return "network_resource_unavailable"
        case .dataNotAllowed:
            return "network_data_not_allowed"
        case .secureConnectionFailed:
            return "network_ssl_failed"
        default:
            return "network"
        }
    }
}
