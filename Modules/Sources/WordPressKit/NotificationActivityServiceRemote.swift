import Foundation
import WordPressKitObjC

/// Account-scoped remote for the in-app Notifications activity indicator.
///
/// The bell state comes from the account-wide `has_unseen_notes` flag exposed by
/// the `me` endpoint. `markSeen` reports the newest observed notification
/// timestamp so the backend can recompute that flag. Both use the authenticated
/// WordPress.com REST API supplied at construction time.
public final class NotificationActivityServiceRemote: ServiceRemoteWordPressComREST {

    /// The server did not accept the seen write: it answered without
    /// `success: true`, with an unparsable body, or with a client error that a
    /// retry cannot fix. `markSeen` rethrows transport,
    /// authentication, rate-limit, and server errors unchanged, because a later
    /// retry can succeed.
    public struct SeenRejectedError: Error {
        public init() {}
    }

    /// Fetches the account-wide "has unseen notes" flag.
    ///
    /// A missing or non-Boolean value throws rather than defaulting to `false`,
    /// so callers can preserve the last known state instead of inventing a
    /// cleared one.
    public func fetchHasUnseenNotes() async throws -> Bool {
        struct Response: Decodable {
            let hasUnseenNotes: Bool
        }

        let path = path(forEndpoint: "me", withVersion: ._1_1)
        let response = await wordPressComRestApi.perform(
            .get,
            URLString: path,
            parameters: ["fields": "has_unseen_notes"],
            jsonDecoder: .apiDecoder,
            type: Response.self
        )
        return try response.get().body.hasUnseenNotes
    }

    /// Reports the newest seen notification timestamp to the backend.
    ///
    /// Only a response with `success: true` acknowledges the write.
    ///
    /// - Parameter timestamp: The timestamp of the newest notification observed
    ///   by the list. This marks notifications as *seen*, not *read*.
    /// - Throws: ``SeenRejectedError`` when the server rejects the write;
    ///   otherwise the underlying error, which a retry can overcome.
    public func markSeen(timestamp: Date) async throws {
        struct Response: Decodable {
            let success: Bool
        }

        // The endpoint casts `time` to an integer: anything but Unix seconds
        // (an ISO 8601 string becomes its year) reports success without
        // advancing last-seen.
        let path = path(forEndpoint: "notifications/seen", withVersion: ._1_1)
        let result = await wordPressComRestApi.perform(
            .post,
            URLString: path,
            parameters: ["time": Int(timestamp.timeIntervalSince1970)],
            type: Response.self
        )

        switch result {
        case .success(let response):
            guard response.body.success else {
                throw SeenRejectedError()
            }
        case .failure(let error):
            throw Self.isRejection(error) ? SeenRejectedError() : error
        }
    }

    /// Whether a failed seen write was rejected by the server, as opposed to a
    /// failure that a later retry can overcome.
    static func isRejection(_ error: WordPressAPIError<WordPressComRestApiEndpointError>) -> Bool {
        switch error {
        case .connection, .unknown:
            return false
        case .requestEncodingFailure:
            return true
        case .unparsableResponse(let response, _, _):
            return isRejectingUnparsableResponse(response)
        case .endpointError(let endpointError):
            switch endpointError.code {
            case .invalidToken, .authorizationRequired, .reauthorizationRequired, .tooManyRequests:
                return false
            case .unknown:
                // An unrecognized error code can be a client or a server error.
                return isRejectingStatus(endpointError.response?.statusCode)
            case .responseSerializationFailed:
                // WordPressComRestApi reports an unparsable body this way, with
                // its response: a 2xx without a valid `success`, or an error page.
                return isRejectingUnparsableResponse(endpointError.response)
            case .invalidInput, .invalidQuery, .uploadFailed, .preconditionFailure,
                .malformedURL, .requestSerializationFailed:
                return true
            }
        case .unacceptableStatusCode(let response, _):
            return isRejectingStatus(response.statusCode)
        }
    }

    /// A successful response without a valid `success` field does not confirm the
    /// write. An unparsable error page falls back to its status.
    private static func isRejectingUnparsableResponse(_ response: HTTPURLResponse?) -> Bool {
        guard let status = response?.statusCode, !(200..<300).contains(status) else {
            return true
        }
        return isRejectingStatus(status)
    }

    /// A 4xx status rejects the request, except 401 (credentials), 408
    /// (timeout), and 429 (rate limit), which a retry can overcome.
    private static func isRejectingStatus(_ status: Int?) -> Bool {
        guard let status else {
            return false
        }
        return (400..<500).contains(status) && ![401, 408, 429].contains(status)
    }
}
