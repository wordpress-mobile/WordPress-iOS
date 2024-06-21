#if SWIFT_PACKAGE
import APIInterface
#endif
import Foundation
import WordPressShared

// MARK: - WordPressComRestApiError

@available(*, deprecated, renamed: "WordPressComRestApiErrorCode", message: "`WordPressComRestApiError` is renamed to `WordPressRestApiErrorCode`, and no longer conforms to `Swift.Error`")
public typealias WordPressComRestApiError = WordPressComRestApiErrorCode

/**
 Error constants for the WordPress.com REST API

 - InvalidInput:                   The parameters sent to the server where invalid
 - InvalidToken:                   The token provided was invalid
 - AuthorizationRequired:          Permission required to access resource
 - UploadFailed:                   The upload failed
 - RequestSerializationFailed:     The serialization of the request failed
 - Unknown:                        Unknow error happen
 */
@objc public enum WordPressComRestApiErrorCode: Int, CaseIterable {
    case invalidInput
    case invalidToken
    case authorizationRequired
    case uploadFailed
    case requestSerializationFailed
    case responseSerializationFailed
    case tooManyRequests
    case unknown
    case preconditionFailure
    case malformedURL
    case invalidQuery
}

public struct WordPressComRestApiEndpointError: Error {
    public var code: WordPressComRestApiErrorCode
    var response: HTTPURLResponse?

    public var apiErrorCode: String?
    public var apiErrorMessage: String?
    public var apiErrorData: AnyObject?

    var additionalUserInfo: [String: Any]?
}

extension WordPressComRestApiEndpointError: LocalizedError {
    public var errorDescription: String? {
        apiErrorMessage
    }
}

extension WordPressComRestApiEndpointError: HTTPURLResponseProviding {
    var httpResponse: HTTPURLResponse? {
        response
    }
}

public enum ResponseType {
    case json
    case data
}

// MARK: - WordPressComRestApi

open class WordPressComRestApi: NSObject {

    /// Use `URLSession` directly (instead of Alamofire) to send API requests.
    @available(*, deprecated, message: "This property is no longer being used because WordPressKit now sends all HTTP requests using `URLSession` directly.")
    public static var useURLSession = true

    // MARK: Properties

    @objc public static let ErrorKeyErrorCode       = "WordPressComRestApiErrorCodeKey"
    @objc public static let ErrorKeyErrorMessage    = "WordPressComRestApiErrorMessageKey"
    @objc public static let ErrorKeyErrorData       = "WordPressComRestApiErrorDataKey"
    @objc public static let ErrorKeyErrorDataEmail  = "email"

    @objc public static let LocaleKeyDefault        = "locale"  // locale is specified with this for v1 endpoints
    @objc public static let LocaleKeyV2             = "_locale" // locale is prefixed with an underscore for v2

    public typealias RequestEnqueuedBlock = (_ taskID: NSNumber) -> Void
    public typealias SuccessResponseBlock = (_ responseObject: AnyObject, _ httpResponse: HTTPURLResponse?) -> Void
    public typealias FailureReponseBlock = (_ error: NSError, _ httpResponse: HTTPURLResponse?) -> Void
    public typealias APIResult<T> = WordPressAPIResult<HTTPAPIResponse<T>, WordPressComRestApiEndpointError>

    @objc public static let apiBaseURL: URL = URL(string: "https://public-api.wordpress.com/")!

    @objc public static let defaultBackgroundSessionIdentifier = "org.wordpress.wpcomrestapi"

    private let oAuthToken: String?

    private let userAgent: String?

    @objc public let backgroundSessionIdentifier: String

    @objc public let sharedContainerIdentifier: String?

    private let backgroundUploads: Bool

    private let localeKey: String

    @objc public let baseURL: URL

    private var invalidTokenHandler: (() -> Void)?

    /**
     Configure whether or not the user's preferred language locale should be appended. Defaults to true.
     */
    @objc open var appendsPreferredLanguageLocale = true

    // MARK: WordPressComRestApi

    @objc convenience public init(oAuthToken: String? = nil, userAgent: String? = nil) {
        self.init(oAuthToken: oAuthToken, userAgent: userAgent, backgroundUploads: false, backgroundSessionIdentifier: WordPressComRestApi.defaultBackgroundSessionIdentifier)
    }

    @objc convenience public init(oAuthToken: String? = nil, userAgent: String? = nil, baseURL: URL = WordPressComRestApi.apiBaseURL) {
        self.init(oAuthToken: oAuthToken, userAgent: userAgent, backgroundUploads: false, backgroundSessionIdentifier: WordPressComRestApi.defaultBackgroundSessionIdentifier, baseURL: baseURL)
    }

    /// Creates a new API object to connect to the WordPress Rest API.
    ///
    /// - Parameters:
    ///   - oAuthToken: the oAuth token to be used for authentication.
    ///   - userAgent: the user agent to identify the client doing the connection.
    ///   - backgroundUploads: If this value is true the API object will use a background session to execute uploads requests when using the `multipartPOST` function. The default value is false.
    ///   - backgroundSessionIdentifier: The session identifier to use for the background session. This must be unique in the system.
    ///   - sharedContainerIdentifier: An optional string used when setting up background sessions for use in an app extension. Default is nil.
    ///   - localeKey: The key with which to specify locale in the parameters of a request.
    ///   - baseURL: The base url to use for API requests. Default is https://public-api.wordpress.com/
    ///
    /// - Discussion: When backgroundUploads are activated any request done by the multipartPOST method will use background session. This background session is shared for all multipart
    ///   requests and the identifier used must be unique in the system, Apple recomends to use invert DNS base on your bundle ID. Keep in mind these requests will continue even
    ///   after the app is killed by the system and the system will retried them until they are done. If the background session is initiated from an app extension, you *must* provide a value
    ///   for the sharedContainerIdentifier.
    ///
    @objc public init(oAuthToken: String? = nil, userAgent: String? = nil,
                backgroundUploads: Bool = false,
                backgroundSessionIdentifier: String = WordPressComRestApi.defaultBackgroundSessionIdentifier,
                sharedContainerIdentifier: String? = nil,
                localeKey: String = WordPressComRestApi.LocaleKeyDefault,
                baseURL: URL = WordPressComRestApi.apiBaseURL) {
        self.oAuthToken = oAuthToken
        self.userAgent = userAgent
        self.backgroundUploads = backgroundUploads
        self.backgroundSessionIdentifier = backgroundSessionIdentifier
        self.sharedContainerIdentifier = sharedContainerIdentifier
        self.localeKey = localeKey
        self.baseURL = baseURL

        super.init()
    }

    deinit {
        for session in [urlSession, uploadURLSession] {
            session.finishTasksAndInvalidate()
        }
    }

    /// Cancels all outgoing tasks asynchronously without invalidating the session.
    public func cancelTasks() {
        for session in [urlSession, uploadURLSession] {
            session.getAllTasks { tasks in
                tasks.forEach({ $0.cancel() })
            }
        }
    }

    /**
     Cancels all ongoing taks and makes the session invalid so the object will not fullfil any more request
     */
    @objc open func invalidateAndCancelTasks() {
        for session in [urlSession, uploadURLSession] {
            session.invalidateAndCancel()
        }
    }

    @objc func setInvalidTokenHandler(_ handler: @escaping () -> Void) {
        invalidTokenHandler = handler
    }

    // MARK: Network requests

    /**
     Executes a GET request to the specified endpoint defined on URLString

     - parameter URLString:  the url string to be added to the baseURL
     - parameter parameters: the parameters to be encoded on the request
     - parameter success:    callback to be called on successful request
     - parameter failure:    callback to be called on failed request

     - returns:  a NSProgress object that can be used to track the progress of the request and to cancel the request. If the method
     returns nil it's because something happened on the request serialization and the network request was not started, but the failure callback
     will be invoked with the error specificing the serialization issues.
     */
    @objc @discardableResult open func GET(_ URLString: String,
                     parameters: [String: AnyObject]?,
                     success: @escaping SuccessResponseBlock,
                     failure: @escaping FailureReponseBlock) -> Progress? {
        let progress = Progress.discreteProgress(totalUnitCount: 100)

        Task { @MainActor in
            let result = await self.perform(.get, URLString: URLString, parameters: parameters, fulfilling: progress)

            switch result {
            case let .success(response):
                success(response.body, response.response)
            case let .failure(error):
                failure(error.asNSError(), error.response)
            }
        }

        return progress
    }

    open func GETData(_ URLString: String,
                                         parameters: [String: AnyObject]?,
                                         completion: @escaping (Swift.Result<(Data, HTTPURLResponse?), Error>) -> Void) {
        Task { @MainActor in
            let result = await perform(.get, URLString: URLString, parameters: parameters, fulfilling: nil, decoder: { $0 })

            completion(
                result
                    .map { ($0.body, $0.response) }
                    .eraseToError()
            )
        }
    }

    /**
     Executes a POST request to the specified endpoint defined on URLString

     - parameter URLString:  the url string to be added to the baseURL
     - parameter parameters: the parameters to be encoded on the request
     - parameter success:    callback to be called on successful request
     - parameter failure:    callback to be called on failed request

     - returns:  a NSProgress object that can be used to track the progress of the upload and to cancel the upload. If the method
     returns nil it's because something happened on the request serialization and the network request was not started, but the failure callback
     will be invoked with the error specificing the serialization issues.
     */
    @objc @discardableResult open func POST(_ URLString: String,
                     parameters: [String: AnyObject]?,
                     success: @escaping SuccessResponseBlock,
                     failure: @escaping FailureReponseBlock) -> Progress? {
        let progress = Progress.discreteProgress(totalUnitCount: 100)

        Task { @MainActor in
            let result = await self.perform(.post, URLString: URLString, parameters: parameters, fulfilling: progress)

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
     Executes a multipart POST using the current serializer, the parameters defined and the fileParts defined in the request
     This request will be streamed from disk, so it's ideally to be used for large media post uploads.

     - parameter URLString:  the endpoint to connect
     - parameter parameters: the parameters to use on the request
     - parameter fileParts:  the file parameters that are added to the multipart request
     - parameter requestEnqueued: callback to be called when the fileparts are serialized and request is added to the background session. Defaults to nil
     - parameter success:    callback to be called on successful request
     - parameter failure:    callback to be called on failed request

     - returns:  a `Progerss` object that can be used to track the progress of the upload and to cancel the upload. If the method
     returns nil it's because something happened on the request serialization and the network request was not started, but the failure callback
     will be invoked with the error specificing the serialization issues.
     */
    @nonobjc @discardableResult open func multipartPOST(
        _ URLString: String,
        parameters: [String: AnyObject]?,
        fileParts: [FilePart],
        requestEnqueued: RequestEnqueuedBlock? = nil,
        success: @escaping SuccessResponseBlock,
        failure: @escaping FailureReponseBlock
    ) -> Progress? {
        let progress = Progress.discreteProgress(totalUnitCount: 100)

        Task { @MainActor in
            let result = await upload(URLString: URLString, parameters: parameters, fileParts: fileParts, requestEnqueued: requestEnqueued, fulfilling: progress)
            switch result {
            case let .success(response):
                success(response.body, response.response)
            case let .failure(error):
                failure(error.asNSError(), error.response)
            }
        }

        return progress
    }

    @objc open func hasCredentials() -> Bool {
        guard let authToken = oAuthToken else {
            return false
        }
        return !(authToken.isEmpty)
    }

    override open var hash: Int {
        return "\(String(describing: oAuthToken)),\(String(describing: userAgent))".hashValue
    }

    func requestBuilder(URLString: String) throws -> HTTPRequestBuilder {
        guard let url = URL(string: URLString, relativeTo: baseURL) else {
            throw URLError(.badURL)
        }

        var builder = HTTPRequestBuilder(url: url)

        if appendsPreferredLanguageLocale {
            let preferredLanguageIdentifier = WordPressComLanguageDatabase().deviceLanguage.slug
            builder = builder.query(defaults: [URLQueryItem(name: localeKey, value: preferredLanguageIdentifier)])
        }

        return builder
    }

    @objc public func temporaryFileURL(withExtension fileExtension: String) -> URL {
        assert(!fileExtension.isEmpty, "file Extension cannot be empty")
        let fileName = "\(ProcessInfo.processInfo.globallyUniqueString)_file.\(fileExtension)"
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        return fileURL
    }

    // MARK: - Async

    private lazy var urlSession: URLSession = {
        URLSession(configuration: sessionConfiguration(background: false))
    }()

    private lazy var uploadURLSession: URLSession = {
        let configuration = sessionConfiguration(background: backgroundUploads)
        configuration.sharedContainerIdentifier = self.sharedContainerIdentifier
        if configuration.identifier != nil {
            return URLSession.backgroundSession(configuration: configuration)
        } else {
            return URLSession(configuration: configuration)
        }
    }()

    private func sessionConfiguration(background: Bool) -> URLSessionConfiguration {
        let configuration = background ? URLSessionConfiguration.background(withIdentifier: self.backgroundSessionIdentifier) : URLSessionConfiguration.default

        var additionalHeaders: [String: AnyObject] = [:]
        if let oAuthToken = self.oAuthToken {
            additionalHeaders["Authorization"] = "Bearer \(oAuthToken)" as AnyObject
        }
        if let userAgent = self.userAgent {
            additionalHeaders["User-Agent"] = userAgent as AnyObject
        }

        configuration.httpAdditionalHeaders = additionalHeaders

        return configuration
    }

    func perform(
        _ method: HTTPRequestBuilder.Method,
        URLString: String,
        parameters: [String: AnyObject]? = nil,
        fulfilling progress: Progress? = nil
    ) async -> APIResult<AnyObject> {
        await perform(method, URLString: URLString, parameters: parameters, fulfilling: progress) {
            try (JSONSerialization.jsonObject(with: $0) as AnyObject)
        }
    }

    func perform<T: Decodable>(
        _ method: HTTPRequestBuilder.Method,
        URLString: String,
        parameters: [String: AnyObject]? = nil,
        fulfilling progress: Progress? = nil,
        jsonDecoder: JSONDecoder? = nil,
        type: T.Type = T.self
    ) async -> APIResult<T> {
        await perform(method, URLString: URLString, parameters: parameters, fulfilling: progress) {
            let decoder = jsonDecoder ?? JSONDecoder()
            return try decoder.decode(type, from: $0)
        }
    }

    private func perform<T>(
        _ method: HTTPRequestBuilder.Method,
        URLString: String,
        parameters: [String: AnyObject]?,
        fulfilling progress: Progress?,
        decoder: @escaping (Data) throws -> T
    ) async -> APIResult<T> {
        var builder: HTTPRequestBuilder
        do {
            builder = try requestBuilder(URLString: URLString)
                .method(method)
        } catch {
            return .failure(.requestEncodingFailure(underlyingError: error))
        }

        if let parameters {
            if builder.method.allowsHTTPBody {
                builder = builder.body(json: parameters as Any)
            } else {
                builder = builder.query(parameters)
            }
        }

        return await perform(request: builder, fulfilling: progress, decoder: decoder)
    }

    func perform<T>(
        request: HTTPRequestBuilder,
        fulfilling progress: Progress? = nil,
        decoder: @escaping (Data) throws -> T,
        taskCreated: ((Int) -> Void)? = nil,
        session: URLSession? = nil
    ) async -> APIResult<T> {
        await (session ?? self.urlSession)
            .perform(request: request, taskCreated: taskCreated, fulfilling: progress, errorType: WordPressComRestApiEndpointError.self)
            .mapSuccess { response -> HTTPAPIResponse<T> in
                let object = try decoder(response.body)

                return HTTPAPIResponse(response: response.response, body: object)
            }
            .mapUnacceptableStatusCodeError { response, body in
                if let error = self.processError(response: response, body: body, additionalUserInfo: nil) {
                    return error
                }

                throw URLError(.cannotParseResponse)
            }
            .mapError { error -> WordPressAPIError<WordPressComRestApiEndpointError> in
                switch error {
                case .requestEncodingFailure:
                    return .endpointError(.init(code: .requestSerializationFailed))
                case let .unparsableResponse(response, _, _):
                    return .endpointError(.init(code: .responseSerializationFailed, response: response))
                default:
                    return error
                }
            }
    }

    public func upload(
        URLString: String,
        parameters: [String: AnyObject]? = nil,
        httpHeaders: [String: String]? = nil,
        fileParts: [FilePart],
        requestEnqueued: RequestEnqueuedBlock? = nil,
        fulfilling progress: Progress? = nil
    ) async -> APIResult<AnyObject> {
        let builder: HTTPRequestBuilder
        do {
            let form = try fileParts.map {
                try MultipartFormField(fileAtPath: $0.url.path, name: $0.parameterName, filename: $0.fileName, mimeType: $0.mimeType)
            }
            builder = try requestBuilder(URLString: URLString)
                .method(.post)
                .body(form: form)
                .headers(httpHeaders ?? [:])
        } catch {
            return .failure(.requestEncodingFailure(underlyingError: error))
        }

        return await perform(
            request: builder.query(parameters ?? [:]),
            fulfilling: progress,
            decoder: { try JSONSerialization.jsonObject(with: $0) as AnyObject },
            taskCreated: { taskID in
                DispatchQueue.main.async {
                    requestEnqueued?(NSNumber(value: taskID))
                }
            },
            session: uploadURLSession
        )
    }

}

// MARK: - Error processing

extension WordPressComRestApi {

    func processError(response httpResponse: HTTPURLResponse, body data: Data, additionalUserInfo: [String: Any]?) -> WordPressComRestApiEndpointError? {
        // Not sure if it's intentional to include 500 status code, but the code seems to be there from the very beginning.
        // https://github.com/wordpress-mobile/WordPressKit-iOS/blob/1.0.1/WordPressKit/WordPressComRestApi.swift#L374
        guard (400...500).contains(httpResponse.statusCode) else {
            return nil
        }

        guard let responseObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
            let responseDictionary = responseObject as? [String: AnyObject] else {

            if let error = checkForThrottleErrorIn(response: httpResponse, data: data) {
                return error
            }
            return .init(code: .unknown, response: httpResponse)
        }

        // FIXME: A hack to support free WPCom sites and Rewind. Should be obsolote as soon as the backend
        // stops returning 412's for those sites.
        if httpResponse.statusCode == 412, let code = responseDictionary["code"] as? String, code == "no_connected_jetpack" {
            return .init(code: .preconditionFailure, response: httpResponse)
        }

        var errorDictionary: AnyObject? = responseDictionary as AnyObject?
        if let errorArray = responseDictionary["errors"] as? [AnyObject], errorArray.count > 0 {
            errorDictionary = errorArray.first
        }
        guard let errorEntry = errorDictionary as? [String: AnyObject],
            let errorCode = errorEntry["error"] as? String,
            let errorDescription = errorEntry["message"] as? String
            else {
                return .init(code: .unknown, response: httpResponse)
        }

        let errorsMap: [String: WordPressComRestApiErrorCode] = [
            "invalid_input": .invalidInput,
            "invalid_token": .invalidToken,
            "authorization_required": .authorizationRequired,
            "upload_error": .uploadFailed,
            "unauthorized": .authorizationRequired,
            "invalid_query": .invalidQuery
        ]

        let mappedError = errorsMap[errorCode] ?? .unknown
        if mappedError == .invalidToken {
            // Call `invalidTokenHandler in the main thread since it's typically used by the apps to present an authentication UI.
            DispatchQueue.main.async {
                self.invalidTokenHandler?()
            }
        }

        var originalErrorUserInfo = additionalUserInfo ?? [:]
        originalErrorUserInfo.removeValue(forKey: NSLocalizedDescriptionKey)

        return .init(
            code: mappedError,
            apiErrorCode: errorCode,
            apiErrorMessage: errorDescription,
            apiErrorData: errorEntry["data"],
            additionalUserInfo: originalErrorUserInfo
        )
    }

    func checkForThrottleErrorIn(response: HTTPURLResponse, data: Data) -> WordPressComRestApiEndpointError? {
        // This endpoint is throttled, so check if we've sent too many requests and fill that error in as
        // when too many requests occur the API just spits out an html page.
        guard let responseString = String(data: data, encoding: .utf8),
            responseString.contains("Limit reached") else {
                return nil
        }

        let message = NSLocalizedString(
            "wordpresskit.api.message.endpoint_throttled",
            value: "Limit reached. You can try again in 1 minute. Trying again before that will only increase the time you have to wait before the ban is lifted. If you think this is in error, contact support.",
            comment: "Message to show when a request for a WP.com API endpoint is throttled"
        )
        return .init(
            code: .tooManyRequests,
            apiErrorCode: "too_many_requests",
            apiErrorMessage: message
        )
    }
}
// MARK: - Anonymous API support

extension WordPressComRestApi {

    /// Returns an API object without an OAuth token defined & with the userAgent set for the WordPress App user agent
    ///
    @objc class public func anonymousApi(userAgent: String) -> WordPressComRestApi {
        return WordPressComRestApi(oAuthToken: nil, userAgent: userAgent)
    }

    /// Returns an API object without an OAuth token defined & with both the userAgent & localeKey set for the WordPress App user agent
    ///
    @objc class public func anonymousApi(userAgent: String, localeKey: String) -> WordPressComRestApi {
        return WordPressComRestApi(oAuthToken: nil, userAgent: userAgent, localeKey: localeKey)
    }
}

// MARK: - Constants

private extension WordPressComRestApi {

    enum Constants {
        static let buildRequestError = NSError(domain: WordPressComRestApiEndpointError.errorDomain,
                                               code: WordPressComRestApiErrorCode.requestSerializationFailed.rawValue,
                                               userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Failed to serialize request to the REST API.",
                                                                                                       comment: "Error message to show when wrong URL format is used to access the REST API")])
    }
}

// MARK: - POST encoding

extension WordPressAPIError<WordPressComRestApiEndpointError> {
    func asNSError() -> NSError {
        // When encoutering `URLError`, return `URLError` to avoid potentially breaking existing error handling code in the apps.
        if case let .connection(urlError) = self {
            return urlError as NSError
        }

        return self as NSError
    }
}

extension WordPressComRestApi: WordPressComRESTAPIInterfacing {
    // A note on the naming: Even if defined as `GET` in Objective-C, then method gets converted to Swift as `get`.
    //
    // Also, there is no Objective-C direct equivalent of `AnyObject`, which here is used in `parameters: [String: AnyObject]?`.
    //
    // For those reasons, we can't immediately conform to `WordPressComRESTAPIInterfacing` and need instead to use this kind of wrapping.
    // The same applies for the other methods below.
    public func get(
        _ URLString: String,
        parameters: [String: Any]?,
        success: @escaping (Any, HTTPURLResponse?) -> Void,
        failure: @escaping (any Error, HTTPURLResponse?) -> Void
    ) -> Progress? {
        GET(
            URLString,
            // It's possible `WordPressComRestApi` could be updated to use `[String: Any]` instead.
            // But leaving that investigation for later.
            parameters: parameters as? [String: AnyObject],
            success: success,
            failure: failure
        )
    }

    public func post(
        _ URLString: String,
        parameters: [String: Any]?,
        success: @escaping (Any, HTTPURLResponse?) -> Void,
        failure: @escaping (any Error, HTTPURLResponse?) -> Void
    ) -> Progress? {
        POST(
            URLString,
            // It's possible `WordPressComRestApi` could be updated to use `[String: Any]` instead.
            // But leaving that investigation for later.
            parameters: parameters as? [String: AnyObject],
            success: success,
            failure: failure
        )
    }

    public func multipartPOST(
        _ URLString: String,
        parameters: [String: NSObject]?,
        fileParts: [FilePart],
        // Notice this does not require @escaping because it is Optional.
        //
        // Annotate with @escaping, and the compiler will fail with:
        // > Closure is already escaping in optional type argument
        //
        // It is necessary to explicitly set this as Optional because of the _Nullable parameter requirement in the Objective-C protocol.
        requestEnqueued: ((NSNumber) -> Void)?,
        success: @escaping (Any, HTTPURLResponse?) -> Void,
        failure: @escaping (any Error, HTTPURLResponse?) -> Void
    ) -> Progress? {
        multipartPOST(
            URLString,
            parameters: parameters,
            fileParts: fileParts,
            requestEnqueued: requestEnqueued,
            success: success as SuccessResponseBlock,
            failure: failure as FailureReponseBlock
        )
    }
}
