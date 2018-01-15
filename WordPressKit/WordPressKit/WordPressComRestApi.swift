import Foundation
import AFNetworking
import WordPressShared

/**
 Error constants for the WordPress.com REST API

 - InvalidInput:                   The parameters sent to the server where invalid
 - InvalidToken:                   The token provided was invalid
 - AuthorizationRequired:          Permission required to access resource
 - UploadFailed:                   The upload failed
 - RequestSerializationFailed:     The serialization of the request failed
 - Unknown:                        Unknow error happen
 */
@objc public enum WordPressComRestApiError: Int, Error {
    case invalidInput
    case invalidToken
    case authorizationRequired
    case uploadFailed
    case requestSerializationFailed
    case responseSerializationFailed
    case tooManyRequests
    case unknown
}

open class WordPressComRestApi: NSObject {
    @objc open static let ErrorKeyResponseData: String = AFNetworkingOperationFailingURLResponseDataErrorKey
    @objc open static let ErrorKeyErrorCode: String = "WordPressComRestApiErrorCodeKey"
    @objc open static let ErrorKeyErrorMessage: String = "WordPressComRestApiErrorMessageKey"

    public typealias RequestEnqueuedBlock = (_ taskID : NSNumber) -> Void
    public typealias SuccessResponseBlock = (_ responseObject: AnyObject, _ httpResponse: HTTPURLResponse?) -> ()
    public typealias FailureReponseBlock = (_ error: NSError, _ httpResponse: HTTPURLResponse?) -> ()

    @objc open static let apiBaseURLString: String = "https://public-api.wordpress.com/"
    
    @objc open static let defaultBackgroundSessionIdentifier = "org.wordpress.wpcomrestapi"
    
    @objc open let backgroundSessionIdentifier: String

    @objc open let sharedContainerIdentifier: String?
    
    fileprivate let backgroundUploads: Bool

    fileprivate static let localeKey = "locale"

    fileprivate let oAuthToken: String?
    fileprivate let userAgent: String?

    /**
     Configure whether or not the user's preferred language locale should be appended. Defaults to true.
     */
    @objc open var appendsPreferredLanguageLocale = true

    fileprivate lazy var sessionManager: AFHTTPSessionManager = {
        let sessionConfiguration = URLSessionConfiguration.default
        let sessionManager = self.makeSessionManager(configuration: sessionConfiguration)
        return sessionManager
    }()

    fileprivate lazy var uploadSessionManager: AFHTTPSessionManager = {
        if self.backgroundUploads {
            let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: self.backgroundSessionIdentifier)
            sessionConfiguration.sharedContainerIdentifier = self.sharedContainerIdentifier
            let sessionManager = self.makeSessionManager(configuration: sessionConfiguration)
            return sessionManager
        }
        
        return self.sessionManager
    }()

    fileprivate func makeSessionManager(configuration sessionConfiguration: URLSessionConfiguration) -> AFHTTPSessionManager {
        let baseURL = URL(string: WordPressComRestApi.apiBaseURLString)
        var additionalHeaders: [String : AnyObject] = [:]
        if let oAuthToken = self.oAuthToken {
            additionalHeaders["Authorization"] = "Bearer \(oAuthToken)" as AnyObject?
        }
        if let userAgent = self.userAgent {
            additionalHeaders["User-Agent"] = userAgent as AnyObject?
        }
        sessionConfiguration.httpAdditionalHeaders = additionalHeaders
        let sessionManager = AFHTTPSessionManager(baseURL: baseURL, sessionConfiguration: sessionConfiguration)
        sessionManager.responseSerializer = WordPressComRestAPIResponseSerializer()
        sessionManager.requestSerializer = AFJSONRequestSerializer()
        return sessionManager
    }
    
    @objc convenience public init(oAuthToken: String? = nil, userAgent: String? = nil) {
        self.init(oAuthToken: oAuthToken, userAgent: userAgent, backgroundUploads: false, backgroundSessionIdentifier: WordPressComRestApi.defaultBackgroundSessionIdentifier)
    }
    
    /// Creates a new API object to connect to the WordPress Rest API.
    ///
    /// - Parameters:
    ///   - oAuthToken: the oAuth token to be used for authentication.
    ///   - userAgent: the user agent to identify the client doing the connection.
    ///   - backgroundUploads: If this value is true the API object will use a background session to execute uploads requests when using the `multipartPOST` function. The default value is false.
    ///   - backgroundSessionIdentifier: The session identifier to use for the background session. This must be unique in the system.
    ///   - sharedContainerIdentifier: An optional string used when setting up background sessions for use in an app extension. Default is nil.
    ///
    /// - Discussion: When backgroundUploads are activated any request done by the multipartPOST method will use background session. This background session is shared for all multipart
    ///   requests and the identifier used must be unique in the system, Apple recomends to use invert DNS base on your bundle ID. Keep in mind these requests will continue even
    ///   after the app is killed by the system and the system will retried them until they are done. If the background session is initiated from an app extension, you *must* provide a value
    ///   for the sharedContainerIdentifier.
    ///
    @objc public init(oAuthToken: String? = nil, userAgent: String? = nil,
                backgroundUploads: Bool = false,
                backgroundSessionIdentifier: String = WordPressComRestApi.defaultBackgroundSessionIdentifier,
                sharedContainerIdentifier: String? = nil) {
        self.oAuthToken = oAuthToken
        self.userAgent = userAgent
        self.backgroundUploads = backgroundUploads
        self.backgroundSessionIdentifier = backgroundSessionIdentifier
        self.sharedContainerIdentifier = sharedContainerIdentifier
        super.init()
    }

    deinit {
        sessionManager.invalidateSessionCancelingTasks(false)
        uploadSessionManager.invalidateSessionCancelingTasks(false)
    }

    /**
     Cancels all ongoing taks and makes the session invalid so the object will not fullfil any more request
     */
    @objc open func invalidateAndCancelTasks() {
        sessionManager.invalidateSessionCancelingTasks(true)
        uploadSessionManager.invalidateSessionCancelingTasks(true)
    }

    // MARK: - Network requests

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
        let URLString = appendLocaleIfNeeded(URLString)
        let progress = Progress(totalUnitCount: 1)
        let progressUpdater = {(taskProgress: Progress) in
            progress.totalUnitCount = taskProgress.totalUnitCount
            progress.completedUnitCount = taskProgress.completedUnitCount
        }

        let task = sessionManager.get(URLString, parameters: parameters, progress: progressUpdater, success: { (dataTask, result) in
                guard let responseObject = result else {
                    failure(WordPressComRestApiError.unknown as NSError , dataTask.response as? HTTPURLResponse)
                    return
                }
                success(responseObject as AnyObject, dataTask.response as? HTTPURLResponse)
                progress.completedUnitCount = progress.totalUnitCount
        }, failure: { (dataTask: URLSessionDataTask?, error) in
                failure(error as NSError, dataTask?.response as? HTTPURLResponse)
            }
        )
        if let task = task {
            progress.cancellationHandler = {
                task.cancel()
            }
            return progress
        } else {
            return nil
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
        let URLString = appendLocaleIfNeeded(URLString)
        let progress = Progress(totalUnitCount: 1)
        let progressUpdater = {(taskProgress: Progress) in
            progress.totalUnitCount = taskProgress.totalUnitCount
            progress.completedUnitCount = taskProgress.completedUnitCount
        }
        let task = sessionManager.post(URLString, parameters: parameters, progress: progressUpdater, success: { (dataTask, result) in
                guard let responseObject = result else {
                    failure(WordPressComRestApiError.unknown as NSError , dataTask.response as? HTTPURLResponse)
                    return
                }
                success(responseObject as AnyObject, dataTask.response as? HTTPURLResponse)
                progress.completedUnitCount = progress.totalUnitCount
        }, failure: { (dataTask: URLSessionDataTask?, error) in
            failure(error as NSError, dataTask?.response as? HTTPURLResponse)
            }
        )
        if let task = task {
            progress.cancellationHandler = {
                task.cancel()
            }
            return progress
        } else {
            return nil
        }
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

     - returns:  a NSProgress object that can be used to track the progress of the upload and to cancel the upload. If the method
     returns nil it's because something happened on the request serialization and the network request was not started, but the failure callback
     will be invoked with the error specificing the serialization issues.
     */
    @objc @discardableResult open func multipartPOST(_ URLString: String,
                              parameters: [String: AnyObject]?,
                              fileParts: [FilePart],
                              requestEnqueued: RequestEnqueuedBlock? = nil,
                              success: @escaping SuccessResponseBlock,
                              failure: @escaping FailureReponseBlock) -> Progress? {
        
        let progress = Progress(totalUnitCount: 1)
        let progressUpdater = {(taskProgress: Progress) in
            // Sergio Estevao: Add an extra 1 unit to the progress to take in account the upload response and not only the uploading of data
            progress.totalUnitCount = taskProgress.totalUnitCount + 1
            progress.completedUnitCount = taskProgress.completedUnitCount
        }
        serializeRequest(URLString, parameters: parameters, fileParts: fileParts, success:{ (request, temporaryURL) in
            let task = self.uploadSessionManager.uploadTask(with: request as URLRequest, fromFile: temporaryURL, progress: progressUpdater) { (response, result, error) in
                progress.completedUnitCount = progress.totalUnitCount
                if let error = error {
                    failure(error as NSError, response as? HTTPURLResponse)
                } else {
                    guard let responseObject = result else {
                        failure(WordPressComRestApiError.unknown as NSError , response as? HTTPURLResponse)
                        return
                    }
                    success(responseObject as AnyObject, response as? HTTPURLResponse)
                }
            }
            requestEnqueued?(NSNumber(value: task.taskIdentifier))
            task.resume()
            progress.cancellationHandler = {
                task.cancel()
            }
            if let sizeString = request.allHTTPHeaderFields?["Content-Length"],
                let size = Int64(sizeString) {
                progress.totalUnitCount = size
            }
        }, failure: failure)

        return progress
    }

    private func serializeRequest(_ URLString: String,
                                  parameters: [String: AnyObject]?,
                                  fileParts: [FilePart],
                                  success: @escaping (_ request: URLRequest, _ requestFileURL: URL) -> (),
                                  failure: @escaping FailureReponseBlock) {
        let URLString = appendLocaleIfNeeded(URLString)
        guard
            let baseURL = URL(string: WordPressComRestApi.apiBaseURLString),
            let requestURLString = URL(string: URLString, relativeTo: baseURL)?.absoluteString
            else {
                let error = NSError(domain: String(describing: WordPressComRestApiError.self),
                                    code: WordPressComRestApiError.requestSerializationFailed.rawValue,
                                    userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("Failed to serialize request to the REST API.", comment: "Error message to show when wrong URL format is used to access the REST API")])
                failure(error, nil)
                return
        }
        var serializationError: NSError?
        var filePartError: NSError?
        let uploadSessionManager = self.uploadSessionManager
        let request = uploadSessionManager.requestSerializer.multipartFormRequest(
            withMethod: "POST",
            urlString: requestURLString,
            parameters: parameters,
            constructingBodyWith: { (formData: AFMultipartFormData ) in
                do {
                    for filePart in fileParts {
                        let url = filePart.url
                        try formData.appendPart(withFileURL: url, name: filePart.parameterName, fileName: filePart.filename, mimeType: filePart.mimeType)
                    }
                } catch let error as NSError {
                    filePartError = error
                }
        },
            error: &serializationError
        )
        if let error = filePartError {
            failure(error, nil)
            return
        }
        if let error = serializationError {
            failure(error, nil)
            return
        }
        let temporaryURL = self.temporaryFileURL(withExtension: "dat")
        uploadSessionManager.requestSerializer.request(withMultipartForm: request as URLRequest, writingStreamContentsToFile: temporaryURL) { (error) in
            if let error = error {
                failure(error as NSError, nil)
                return
            }
            success(request as URLRequest, temporaryURL)
        }
    }

    @objc open func hasCredentials() -> Bool {
        guard let authToken = oAuthToken else {
            return false
        }
        return !(authToken.isEmpty)
    }

    override open var hashValue: Int {
        return "\(String(describing: oAuthToken)),\(String(describing: userAgent))".hashValue
    }

    fileprivate func appendLocaleIfNeeded(_ path: String) -> String {
        guard appendsPreferredLanguageLocale else {
            return path
        }
        return WordPressComRestApi.pathByAppendingPreferredLanguageLocale(path)
    }

    @objc open static let WordPressComRestCApiErrorKeyData = "WordPressOrgXMLRPCApiErrorKeyData"

    @objc public func temporaryFileURL(withExtension fileExtension: String) -> URL {
        assert(!fileExtension.isEmpty, "file Extension cannot be empty")
        let fileName = "\(ProcessInfo.processInfo.globallyUniqueString)_file.\(fileExtension)"
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        return fileURL
    }
}

/// FilePart represents the infomartion needed to encode a file on a multipart form request
public final class FilePart: NSObject {
    @objc let parameterName: String
    @objc let url: URL
    @objc let filename: String
    @objc let mimeType: String

    @objc public init(parameterName: String, url: URL, filename: String, mimeType: String) {
        self.parameterName = parameterName
        self.url = url
        self.filename = filename
        self.mimeType = mimeType
    }
}

/// A custom serializer to handle JSON error responses when status codes are betwen 400 and 500
final class WordPressComRestAPIResponseSerializer: AFJSONResponseSerializer {
    override init() {
        super.init()
        var extraStatusCodes = self.acceptableStatusCodes
        extraStatusCodes?.insert(integersIn: 400...500)
        self.acceptableStatusCodes = extraStatusCodes
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func responseObject(for response: URLResponse?, data: Data?, error: NSErrorPointer) -> Any? {

        let responseObject = super.responseObject(for: response, data: data, error: error)

        guard let httpResponse = response as? HTTPURLResponse, (400...500).contains(httpResponse.statusCode) else {
            return responseObject as AnyObject?
        }

        var userInfo: [AnyHashable: Any] = [:]
        if let originalError = error?.pointee {
            userInfo = originalError.userInfo
        }

        guard let responseDictionary = responseObject as? [String: AnyObject] else {
            return responseObject as AnyObject?
        }
        var errorDictionary: AnyObject? = responseDictionary as AnyObject?
        if let errorArray = responseDictionary["errors"] as? [AnyObject], errorArray.count > 0 {
            errorDictionary = errorArray.first
        }
        guard let errorEntry = errorDictionary as? [String: AnyObject],
            let errorCode = errorEntry["error"] as? String,
            let errorDescription = errorEntry["message"] as? String
            else {
                return responseObject as AnyObject?
        }

        let errorsMap = [
            "invalid_input": WordPressComRestApiError.invalidInput,
            "invalid_token": WordPressComRestApiError.invalidToken,
            "authorization_required": WordPressComRestApiError.authorizationRequired,
            "upload_error": WordPressComRestApiError.uploadFailed,
            "unauthorized": WordPressComRestApiError.authorizationRequired
        ]

        let mappedError = errorsMap[errorCode] ?? WordPressComRestApiError.unknown
        userInfo[WordPressComRestApi.ErrorKeyErrorCode] = errorCode
        userInfo[WordPressComRestApi.ErrorKeyErrorMessage] = errorDescription
        let nserror = mappedError as NSError
        userInfo[NSLocalizedDescriptionKey] =  errorDescription
        error?.pointee = NSError(domain: nserror.domain,
                               code: nserror.code,
                               userInfo: userInfo as? [String : Any]
            )
        return responseObject as AnyObject?
    }
}

extension WordPressComRestApi {
    /// Returns an Api object without an oAuthtoken defined and with the userAgent set for the WordPress App user agent
    @objc class public func anonymousApi(userAgent: String) -> WordPressComRestApi {
        return WordPressComRestApi(oAuthToken: nil, userAgent: userAgent)
    }

    /// Append the user's preferred device locale as a query param to the URL path.
    /// If the locale already exists the original path is returned.
    ///
    /// - Parameters:
    ///     - path: A URL string. Can be an absolute or relative URL string.
    ///
    /// - Returns: The path with the locale appended, or the original path if it already had a locale param.
    ///
    @objc class public func pathByAppendingPreferredLanguageLocale(_ path: String) -> String {
        let localeKey = WordPressComRestApi.localeKey
        if path.isEmpty || path.contains("\(localeKey)=") {
            return path
        }
        let preferredLanguageIdentifier = WordPressComLanguageDatabase().deviceLanguage.slug
        let separator = path.contains("?") ? "&" : "?"
        return "\(path)\(separator)\(localeKey)=\(preferredLanguageIdentifier)"
    }
}
