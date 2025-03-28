import Foundation

protocol TrackableErrorProtocol {
    func getTrackingUserInfo() -> [String: String]?
}

extension WordPressAPIError: TrackableErrorProtocol {
    /// Returns a Tracks-compatible user info.
    func getTrackingUserInfo() -> [String: String]? {
        switch self {
        case .requestEncodingFailure(let underlyingError):
            return getUserInfo(for: underlyingError, category: "request_encoding_failure")
        case .connection(let error):
            return getUserInfo(for: error, category: "connection")
        case .endpointError(let endpointError):
            switch endpointError {
            case let error as WordPressComRestApiEndpointError:
                return [
                    "category": "wpcom_endpoint_error",
                    "wpcom_endpoint_error_api_error_code": error.apiErrorCode?.description ?? "–",
                    "wpcom_endpoint_error_api_error_message": error.apiErrorMessage ?? "–"
                ]
            case let error as WordPressOrgXMLRPCApiFault:
                return [
                    "category": "xmlrpc_endpoint_error",
                    "xmlrpc_endpoint_error_api_error_code": error.code?.description ?? "–",
                    "xmlrpc_endpoint_error_api_error_message": error.message ?? "–"
                ]
            default:
                return ["category": "unexpected_endpoint_error"]
            }
        case let .unacceptableStatusCode(response, _):
            return [
                "category": "unacceptable_status_code",
                "status_code": response.statusCode.description
            ]
        case let .unparsableResponse(_, _, error):
            return getUserInfo(for: error, category: "unparsable_response")
        case .unknown(let error):
            return getUserInfo(for: error, category: "unknown")
        }
    }
}

extension WPAnalyticsEvent {
    static func makeUserInfo(for error: Error) -> [String: String] {
        if let error = error as? TrackableErrorProtocol, let userInfo = error.getTrackingUserInfo() {
            return userInfo
        }
        let nsError = error as NSError
        return [
            "category": "other",
            "error_code": nsError.code.description,
            "error_domain": nsError.domain
        ]
    }
}

private func getUserInfo(for error: Error, category: String) -> [String: String] {
    return [
        "category": category,
        "\(category)_error_domain": (error as NSError).domain,
        "\(category)_error_code": (error as NSError).code.description
    ]
}
