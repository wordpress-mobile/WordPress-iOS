import Foundation
#if SWIFT_PACKAGE
import APIInterface
#endif

/// Custom `NSError` bridge implementation.
///
/// The implementation ensures `NSError` instances that are casted from `WordPressAPIError<EndpointError>.endpointError`
/// are the same as those instances that are casted directly from the underlying `EndpointError` instances.
///
/// In theory, we should not need to implement this bridging, because we should never cast errors to `NSError`
/// instances in any error handling code. But since there are still Objective-C callers, providing this custom bridging
/// implementation comes in handy for those cases. See the `WordPressComRestApiEndpointError` extension below.
extension WordPressAPIError: CustomNSError {

    public static var errorDomain: String {
        (EndpointError.self as? CustomNSError.Type)?.errorDomain
            ?? String(describing: Self.self)
    }

    public var errorCode: Int {
        switch self {
        case let .endpointError(endpointError):
            return (endpointError as NSError).code
        // Use negative values for other cases to reduce chances of collision with `EndpointError`.
        case .requestEncodingFailure:
            return -100000
        case .connection:
            return -100001
        case .unacceptableStatusCode:
            return -100002
        case .unparsableResponse:
            return -100003
        case .unknown:
            return -100004
        }
    }

    public var errorUserInfo: [String: Any] {
        switch self {
        case let .endpointError(endpointError):
            return (endpointError as NSError).userInfo
        case .connection(let error):
            return [NSUnderlyingErrorKey: error]
        case .requestEncodingFailure, .unacceptableStatusCode, .unparsableResponse,
                .unknown:
            return [:]
        }
    }
}

// MARK: - Bridge WordPressComRestApiEndpointError to NSError

/// A custom NSError bridge implementation to ensure `NSError` instances converted from `WordPressComRestApiEndpointError`
/// are the same as the ones converted from their underlying error (the `code: WordPressComRestApiError` property in
/// `WordPressComRestApiEndpointError`).
///
/// Along with `WordPressAPIError`'s conformance to `CustomNSError`, the three `NSError` instances below have the
/// same domain and code.
///
/// ```
/// let error: WordPressComRestApiError = // ...
/// let newError: WordPressComRestApiEndpointError = .init(code: error)
/// let apiError: WordPressAPIError<WordPressComRestApiEndpointError> = .endpointError(newError)
///
/// // Following `NSError` instance have the same domain and code.
/// let errorNSError = error as NSError
/// let newErrorNSError = newError as NSError
/// let apiErrorNSError = apiError as NSError
/// ```
///
/// ## Why implementing this custom NSError brdige?
///
/// `WordPressComRestApi` returns `NSError` instances to their callers. Since `WordPressComRestApi` is used in many
/// Objective-C file, we can't change the API to return an `Error` type that's Swift-only (i.e. `WordPressAPIError`).
/// If the day where there are no Objective-C callers finally comes, we definitely should stop returning `NSError` and
/// start using a concrete error type instead. But for now, we have to provide backwards compatiblity to those
/// Objective-C code while using `WordPressAPIError` internally in `WordPressComRestApi`.
///
/// The `NSError` instances returned by `WordPressComRestApi` is one of the following:
/// - `WordPressComRestApiError` enum cases that are directly converted to `NSError`
/// - `NSError` instances that have domain and code from `WordPressComRestApiError`, with additional `userInfo` (error
///     code, message, etc).
/// - Error instances returned by Alamofire 4: `AFError`, or maybe other errors.
///
/// Alamofire will be removed from this library, there is no point (also not possible) in providing backwards
/// compatiblity to `AFError`. That means, we need to make sure the `NSError` instances that are converted from
/// `WordPressAPIError` have the same error domain and code as the underlying `WordPressComRestApiError` enum.
/// And in cases where additional user info was provided, they need to be carried over to the `NSError` instances.
extension WordPressComRestApiEndpointError: CustomNSError {

    public static let errorDomain = WordPressComRestApiErrorDomain

    public var errorCode: Int {
        code.rawValue
    }

    public var errorUserInfo: [String: Any] {
        var userInfo = additionalUserInfo ?? [:]

        if let code = apiErrorCode {
            userInfo[WordPressComRestApi.ErrorKeyErrorCode] = code
        }
        if let message = apiErrorMessage {
            userInfo[WordPressComRestApi.ErrorKeyErrorMessage] = message
            userInfo[NSLocalizedDescriptionKey] = message
        }
        if let data = apiErrorData {
            userInfo[WordPressComRestApi.ErrorKeyErrorData] = data
        }

        return userInfo

    }

}
