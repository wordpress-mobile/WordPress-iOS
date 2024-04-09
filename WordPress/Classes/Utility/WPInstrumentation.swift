import Foundation
import Sentry

// MARK: - Assertions

func wpAssert(_ closure: @autoclosure () -> Bool, _ message: StaticString = "–", file: StaticString = #file, line: UInt = #line) {
    guard !closure() else {
        return
    }

    let filename = (file.description as NSString).lastPathComponent
    DDLogError("WPAssertionFailure in \(filename)–\(line): \(message)")

    WPAnalytics.track(.assertionFailure, properties: [
        "file": filename,
        "line": line,
        "message": "\(filename)–\(line): \(message)"
    ])

#if DEBUG
    assertionFailure(message.description, file: file, line: line)
#endif
}

func wpAssertionFailure(_ message: StaticString, file: StaticString = #file, line: UInt = #line) {
    wpAssert(false, message, file: file, line: line)
}

// MARK: - Error Tracking

protocol TrackableErrorProtocol {
    func getTrackingUserInfo() -> [String: String]?
}

extension WordPressAPIError: TrackableErrorProtocol {
    /// Returns a Tracks-compatible user info.
    func getTrackingUserInfo() -> [String: String]? {
        switch self {
        case .requestEncodingFailure(let underlyingError):
            return getUserInfo(for: underlyingError, category: "request-encoding-failure")
        case .connection(let error):
            return getUserInfo(for: error, category: "connection")
        case .endpointError(let endpointError):
            switch endpointError {
            case let error as WordPressComRestApiEndpointError:
                return [
                    "category": "wpcom-endpoint-error",
                    "wpcom-endpoint-error-api-error-code": error.apiErrorCode?.description ?? "–",
                    "wpcom-endpoint-error-api-error-message": error.apiErrorMessage ?? "–"
                ]
            case let error as WordPressOrgXMLRPCApiFault:
                return [
                    "category": "xmlrpc-endpoint-error",
                    "xmlrpc-endpoint-error-api-error-code": error.code?.description ?? "–",
                    "xmlrpc-endpoint-error-api-error-message": error.message ?? "–"
                ]
            default:
                return ["category": "unexpected-endpoint-error"]
            }
        case let .unacceptableStatusCode(response, _):
            return [
                "category": "unacceptable-status-code",
                "status-code": response.statusCode.description
            ]
        case let .unparsableResponse(_, _, error):
            return getUserInfo(for: error, category: "unparsable-response")
        case .unknown(let error):
            return getUserInfo(for: error, category: "unknown")
        }
    }
}

private func getUserInfo(for error: Error, category: String) -> [String: String] {
    return [
        "category": category,
        "\(category)-error-domain": (error as NSError).domain,
        "\(category)-error-code": (error as NSError).code.description
    ]
}
