import Foundation
import wpxmlrpc

/// Class to connect to the XMLRPC API on self hosted sites.
open class WordPressOrgXMLRPCApi: NSObject {
    public typealias SuccessResponseBlock = (AnyObject, HTTPURLResponse?) -> Void
    public typealias FailureReponseBlock = (_ error: NSError, _ httpResponse: HTTPURLResponse?) -> Void

    @available(*, deprecated, message: "This property is no longer being used because WordPressKit now sends all HTTP requests using `URLSession` directly.")
    public static var useURLSession = true

    private let endpoint: URL
    private let userAgent: String?
    private var backgroundUploads: Bool
    private var backgroundSessionIdentifier: String
    @objc public static let defaultBackgroundSessionIdentifier = "org.wordpress.wporgxmlrpcapi"

    /// onChallenge's Callback Closure Signature. Host Apps should call this method, whenever a proper AuthChallengeDisposition has been
    /// picked up (optionally with URLCredentials!).
    ///
    public typealias AuthenticationHandler = (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

    /// Closure to be executed whenever we receive a URLSession Authentication Challenge.
    ///
    public static var onChallenge: ((URLAuthenticationChallenge, @escaping AuthenticationHandler) -> Void)?

    /// Minimum WordPress.org Supported Version.
    ///
    @objc public static let minimumSupportedVersion = "4.0"

    private lazy var urlSession: URLSession = makeSession(configuration: .default)
    private lazy var uploadURLSession: URLSession = {
        backgroundUploads
            ? makeSession(configuration: .background(withIdentifier: self.backgroundSessionIdentifier))
            : urlSession
    }()

    private func makeSession(configuration sessionConfiguration: URLSessionConfiguration) -> URLSession {
        var additionalHeaders: [String: AnyObject] = ["Accept-Encoding": "gzip, deflate" as AnyObject]
        if let userAgent = self.userAgent {
            additionalHeaders["User-Agent"] = userAgent as AnyObject?
        }
        sessionConfiguration.httpAdditionalHeaders = additionalHeaders
        // When using a background URLSession, we don't need to apply the authentication challenge related
        // implementations in `SessionDelegate`.
        if sessionConfiguration.identifier != nil {
            return URLSession.backgroundSession(configuration: sessionConfiguration)
        } else {
            return URLSession(configuration: sessionConfiguration, delegate: sessionDelegate, delegateQueue: nil)
        }
    }

    // swiftlint:disable weak_delegate
    /// `URLSessionDelegate` for the URLSession instances in this class.
    private let sessionDelegate = SessionDelegate()
    // swiftlint:enable weak_delegate

    /// Creates a new API object to connect to the WordPress XMLRPC API for the specified endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: the endpoint to connect to the xmlrpc api interface.
    ///   - userAgent: the user agent to use on the connection.
    ///   - backgroundUploads:  If this value is true the API object will use a background session to execute uploads requests when using the `multipartPOST` function. The default value is false.
    ///   - backgroundSessionIdentifier: The session identifier to use for the background session. This must be unique in the system.
    @objc public init(endpoint: URL, userAgent: String? = nil, backgroundUploads: Bool = false, backgroundSessionIdentifier: String) {
        self.endpoint = endpoint
        self.userAgent = userAgent
        self.backgroundUploads = backgroundUploads
        self.backgroundSessionIdentifier = backgroundSessionIdentifier
        super.init()
    }

    /// Creates a new API object to connect to the WordPress XMLRPC API for the specified endpoint. The background uploads are disabled when using this initializer.
    ///
    /// - Parameters:
    ///   - endpoint:  the endpoint to connect to the xmlrpc api interface.
    ///   - userAgent: the user agent to use on the connection.
    @objc convenience public init(endpoint: URL, userAgent: String? = nil) {
        self.init(endpoint: endpoint, userAgent: userAgent, backgroundUploads: false, backgroundSessionIdentifier: WordPressOrgXMLRPCApi.defaultBackgroundSessionIdentifier + "." + endpoint.absoluteString)
    }

    deinit {
        for session in [urlSession, uploadURLSession] {
            session.finishTasksAndInvalidate()
        }
    }

    /**
     Cancels all ongoing and makes the session so the object will not fullfil any more request
     */
    @objc open func invalidateAndCancelTasks() {
        for session in [urlSession, uploadURLSession] {
            session.invalidateAndCancel()
        }
    }

    // MARK: - Network requests
    /**
     Check if username and password are valid credentials for the xmlrpc endpoint.

     - parameter username: username to check
     - parameter password: password to check
     - parameter success:  callback block to be invoked if credentials are valid, the object returned in the block is the options dictionary for the site.
     - parameter failure:  callback block to be invoked is credentials fail
     */
    @objc open func checkCredentials(_ username: String,
                                 password: String,
                                 success: @escaping SuccessResponseBlock,
                                 failure: @escaping FailureReponseBlock) {
        let parameters: [AnyObject] = [0 as AnyObject, username as AnyObject, password as AnyObject]
        callMethod("wp.getOptions", parameters: parameters, success: success, failure: failure)
    }
    /**
     Executes a XMLRPC call for the method specificied with the arguments provided.

     - parameter method:  the xmlrpc method to be invoked
     - parameter parameters: the parameters to be encoded on the request
     - parameter success:    callback to be called on successful request
     - parameter failure:    callback to be called on failed request

     - returns:  a NSProgress object that can be used to track the progress of the request and to cancel the request. If the method
     returns nil it's because something happened on the request serialization and the network request was not started, but the failure callback
     will be invoked with the error specificing the serialization issues.
     */
    @objc @discardableResult open func callMethod(_ method: String,
                           parameters: [AnyObject]?,
                           success: @escaping SuccessResponseBlock,
                           failure: @escaping FailureReponseBlock) -> Progress? {
        let progress = Progress.discreteProgress(totalUnitCount: 100)
        Task { @MainActor in
            let result = await self.call(method: method, parameters: parameters, fulfilling: progress, streaming: false)
            switch result {
            case let .success(response):
                success(response.body, response.response)
            case let .failure(error):
                failure(error.asNSError(), error.response)
            }
        }
        return progress
    }

    /**
     Executes a XMLRPC call for the method specificied with the arguments provided, by streaming the request from a file.
     This allows to do requests that can use a lot of memory, like media uploads.

     - parameter method:  the xmlrpc method to be invoked
     - parameter parameters: the parameters to be encoded on the request
     - parameter success:    callback to be called on successful request
     - parameter failure:    callback to be called on failed request

     - returns:  a NSProgress object that can be used to track the progress of the request and to cancel the request. If the method
     returns nil it's because something happened on the request serialization and the network request was not started, but the failure callback
     will be invoked with the error specificing the serialization issues.
     */
    @objc @discardableResult open func streamCallMethod(_ method: String,
                                 parameters: [AnyObject]?,
                                 success: @escaping SuccessResponseBlock,
                                 failure: @escaping FailureReponseBlock) -> Progress? {
        let progress = Progress.discreteProgress(totalUnitCount: 100)
        Task { @MainActor in
            let result = await self.call(method: method, parameters: parameters, fulfilling: progress, streaming: true)
            switch result {
            case let .success(response):
                success(response.body, response.response)
            case let .failure(error):
                failure(error.asNSError(), error.response)
            }
        }
        return progress
    }

    /// Call an XMLRPC method.
    ///
    /// ## Error handling
    ///
    /// Unlike the closure-based APIs, this method returns a concrete error type. You should consider handling the errors
    /// as they are, instead of casting them to `NSError` instance. But in case you do need to cast them to `NSError`,
    /// considering using the `asNSError` function if you need backward compatibility with existing code.
    ///
    /// - Parameters:
    ///   - streaming: set to `true` if there are large data (i.e. uploading files) in given `parameters`. `false` by default.
    /// - Returns: A `Result` type that contains the XMLRPC success or failure result.
    func call(method: String, parameters: [AnyObject]?, fulfilling progress: Progress? = nil, streaming: Bool = false) async -> WordPressAPIResult<HTTPAPIResponse<AnyObject>, WordPressOrgXMLRPCApiFault> {
        let session = streaming ? uploadURLSession : urlSession
        let builder = HTTPRequestBuilder(url: endpoint)
            .method(.post)
            .body(xmlrpc: method, parameters: parameters)
        return await session
            .perform(
                request: builder,
                // All HTTP responses are treated as successful result. Error handling will be done in `decodeXMLRPCResult`.
                acceptableStatusCodes: [1...999],
                fulfilling: progress,
                errorType: WordPressOrgXMLRPCApiFault.self
            )
            .decodeXMLRPCResult()
    }

    @objc public static let WordPressOrgXMLRPCApiErrorKeyData: NSError.UserInfoKey = "WordPressOrgXMLRPCApiErrorKeyData"
    @objc public static let WordPressOrgXMLRPCApiErrorKeyDataString: NSError.UserInfoKey = "WordPressOrgXMLRPCApiErrorKeyDataString"
    @objc public static let WordPressOrgXMLRPCApiErrorKeyStatusCode: NSError.UserInfoKey = "WordPressOrgXMLRPCApiErrorKeyStatusCode"

    fileprivate static func convertError(_ error: NSError, data: Data?, statusCode: Int? = nil) -> NSError {
        let responseCode = statusCode == 403 ? 403 : error.code
        if let data = data {
            var userInfo: [String: Any] = error.userInfo
            userInfo[Self.WordPressOrgXMLRPCApiErrorKeyData as String] = data
            userInfo[Self.WordPressOrgXMLRPCApiErrorKeyDataString as String] = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            userInfo[Self.WordPressOrgXMLRPCApiErrorKeyStatusCode as String] = statusCode
            userInfo[NSLocalizedFailureErrorKey] = error.localizedDescription

            if let statusCode = statusCode, (400..<600).contains(statusCode) {
                let formatString = NSLocalizedString("An HTTP error code %i was returned.", comment: "A failure reason for when an error HTTP status code was returned from the site, with the specific error code.")
                userInfo[NSLocalizedFailureReasonErrorKey] = String(format: formatString, statusCode)
            } else {
                userInfo[NSLocalizedFailureReasonErrorKey] = error.localizedFailureReason
            }

            return NSError(domain: error.domain, code: responseCode, userInfo: userInfo)
        }
        return error
    }
}

private class SessionDelegate: NSObject, URLSessionDelegate {

    @objc func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {

        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodServerTrust:
            if let credential = URLCredentialStorage.shared.defaultCredential(for: challenge.protectionSpace), challenge.previousFailureCount == 0 {
                completionHandler(.useCredential, credential)
                return
            }

            guard let serverTrust = challenge.protectionSpace.serverTrust else {
                completionHandler(.performDefaultHandling, nil)
                return
            }

            _ = SecTrustEvaluateWithError(serverTrust, nil)
            var result = SecTrustResultType.invalid
            let certificateStatus = SecTrustGetTrustResult(serverTrust, &result)

            guard let hostAppHandler = WordPressOrgXMLRPCApi.onChallenge, certificateStatus == 0, result == .recoverableTrustFailure else {
                completionHandler(.performDefaultHandling, nil)
                return
            }

            DispatchQueue.main.async {
                hostAppHandler(challenge, completionHandler)
            }

        default:
            completionHandler(.performDefaultHandling, nil)
        }
    }

    @objc func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {

        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodHTTPBasic:
            if let credential = URLCredentialStorage.shared.defaultCredential(for: challenge.protectionSpace), challenge.previousFailureCount == 0 {
                completionHandler(.useCredential, credential)
                return
            }

            guard let hostAppHandler = WordPressOrgXMLRPCApi.onChallenge else {
                completionHandler(.performDefaultHandling, nil)
                return
            }

            DispatchQueue.main.async {
                hostAppHandler(challenge, completionHandler)
            }

        default:
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

/// Error constants for the WordPress XML-RPC API
@objc public enum WordPressOrgXMLRPCApiError: Int, Error {
    /// An error HTTP status code was returned.
    case httpErrorStatusCode
    /// The serialization of the request failed.
    case requestSerializationFailed
    /// The serialization of the response failed.
    case responseSerializationFailed
    /// An unknown error occurred.
    case unknown
}

extension WordPressOrgXMLRPCApiError: LocalizedError {
    public var errorDescription: String? {
        return NSLocalizedString("There was a problem communicating with the site.", comment: "A general error message shown to the user when there was an API communication failure.")
    }

    public var failureReason: String? {
        switch self {
        case .httpErrorStatusCode:
            return NSLocalizedString("An HTTP error code was returned.", comment: "A failure reason for when an error HTTP status code was returned from the site.")
        case .requestSerializationFailed:
            return NSLocalizedString("The serialization of the request failed.", comment: "A failure reason for when the request couldn't be serialized.")
        case .responseSerializationFailed:
            return NSLocalizedString("The serialization of the response failed.", comment: "A failure reason for when the response couldn't be serialized.")
        case .unknown:
            return NSLocalizedString("An unknown error occurred.", comment: "A failure reason for when the error that occured wasn't able to be determined.")
        }
    }
}

public struct WordPressOrgXMLRPCApiFault: LocalizedError, HTTPURLResponseProviding {
    public var response: HTTPAPIResponse<Data>
    public let code: Int?
    public let message: String?

    public init(response: HTTPAPIResponse<Data>, code: Int?, message: String?) {
        self.response = response
        self.code = code
        self.message = message
    }

    public var errorDescription: String? {
        message
    }

    public var httpResponse: HTTPURLResponse? {
        response.response
    }
}

private extension WordPressAPIResult<HTTPAPIResponse<Data>, WordPressOrgXMLRPCApiFault> {

    func decodeXMLRPCResult() -> WordPressAPIResult<HTTPAPIResponse<AnyObject>, WordPressOrgXMLRPCApiFault> {
        // This is a re-implementation of `WordPressOrgXMLRPCApi.handleResponseWithData` function:
        // https://github.com/wordpress-mobile/WordPressKit-iOS/blob/11.0.0/WordPressKit/WordPressOrgXMLRPCApi.swift#L265
        flatMap { response in
            guard let contentType = response.response.allHeaderFields["Content-Type"] as? String else {
                return .failure(.unparsableResponse(response: response.response, body: response.body, underlyingError: WordPressOrgXMLRPCApiError.unknown))
            }

            if (400..<600).contains(response.response.statusCode) {
                if let decoder = WPXMLRPCDecoder(data: response.body), decoder.isFault() {
                    // when XML-RPC is disabled for authenticated calls (e.g. xmlrpc_enabled is false on WP.org),
                    // it will return a valid fault payload with a non-200
                    return .failure(.endpointError(.init(response: response, code: decoder.faultCode(), message: decoder.faultString())))
                } else {
                    return .failure(.unacceptableStatusCode(response: response.response, body: response.body))
                }
            }

            guard contentType.hasPrefix("application/xml") || contentType.hasPrefix("text/xml") else {
                return .failure(.unparsableResponse(response: response.response, body: response.body, underlyingError: WordPressOrgXMLRPCApiError.unknown))
            }

            guard let decoder = WPXMLRPCDecoder(data: response.body) else {
                return .failure(.unparsableResponse(response: response.response, body: response.body))
            }

            guard !decoder.isFault() else {
                return .failure(.endpointError(.init(response: response, code: decoder.faultCode(), message: decoder.faultString())))
            }

            if let decoderError = decoder.error() {
                return .failure(.unparsableResponse(response: response.response, body: response.body, underlyingError: decoderError))
            }

            guard let responseXML = decoder.object() else {
                return .failure(.unparsableResponse(response: response.response, body: response.body))
            }

            return .success(HTTPAPIResponse(response: response.response, body: responseXML as AnyObject))
        }
    }

}

private extension WordPressAPIError where EndpointError == WordPressOrgXMLRPCApiFault {

    /// Convert to NSError for backwards compatiblity.
    ///
    /// Some Objective-C code in the WordPress app checks domain of the errors returned by `WordPressOrgXMLRPCApi`,
    /// which can be WordPressOrgXMLRPCApiError or WPXMLRPCFaultErrorDomain.
    ///
    /// Swift code should avoid dealing with NSError instances. Instead, they should use the strongly typed
    /// `WordPressAPIError<WordPressOrgXMLRPCApiFault>`.
    func asNSError() -> NSError {
        let error: NSError
        let data: Data?
        let statusCode: Int?
        switch self {
        case let .requestEncodingFailure(underlyingError):
            error = underlyingError as NSError
            data = nil
            statusCode = nil
        case let .connection(urlError):
            error = urlError as NSError
            data = nil
            statusCode = nil
        case let .endpointError(fault):
            error = NSError(domain: WPXMLRPCFaultErrorDomain, code: fault.code ?? 0, userInfo: [NSLocalizedDescriptionKey: fault.message].compactMapValues { $0 })
            data = fault.response.body
            statusCode = nil
        case let .unacceptableStatusCode(response, body):
            error = WordPressOrgXMLRPCApiError.httpErrorStatusCode as NSError
            data = body
            statusCode = response.statusCode
        case let .unparsableResponse(_, body, underlyingError):
            error = underlyingError as NSError
            data = body
            statusCode = nil
        case let .unknown(underlyingError):
            error = underlyingError as NSError
            data = nil
            statusCode = nil
        }

        return WordPressOrgXMLRPCApi.convertError(error, data: data, statusCode: statusCode)
    }

}
