import Foundation
import AFNetworking

/**
 Error constants for the WordPress.com REST API

 - InvalidInput:                   The parameters sent to the server where invalid
 - InvalidToken:                   The token provided was invalid
 - AuthorizationRequired:          Permission required to access resource
 - UploadFailed:                   The upload failed
 - RequestSerializationFailed:     The serialization of the request failed
 - Unknown:                        Unknow error happen
 */
@objc public enum WordPressComRestApiError: Int, ErrorType {
    case InvalidInput
    case InvalidToken
    case AuthorizationRequired
    case UploadFailed
    case RequestSerializationFailed
    case TooManyRequests
    case Unknown
}

public class WordPressComRestApi: NSObject
{
    public static let ErrorKeyResponseData: String = AFNetworkingOperationFailingURLResponseDataErrorKey
    public static let ErrorKeyErrorCode: String = "WordPressComRestApiErrorCodeKey"
    public static let ErrorKeyErrorMessage: String = "WordPressComRestApiErrorMessageKey"

    public typealias SuccessResponseBlock = (responseObject: AnyObject, httpResponse: NSHTTPURLResponse?) -> ()
    public typealias FailureReponseBlock = (error: NSError, httpResponse: NSHTTPURLResponse?) -> ()

    public static let apiBaseURLString: String = "https://public-api.wordpress.com/rest/"

    private static let localeKey = "locale"

    private let oAuthToken: String?
    private let userAgent: String?

    /**
     Configure whether or not the user's preferred language locale should be appended. Defaults to true.
     */
    public var appendsPreferredLanguageLocale = true

    private lazy var sessionManager: AFHTTPSessionManager = {
        let baseURL = NSURL(string:WordPressComRestApi.apiBaseURLString)
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        var additionalHeaders: [String : AnyObject] = [:]
        if let oAuthToken = self.oAuthToken {
            additionalHeaders["Authorization"] = "Bearer \(oAuthToken)"
        }
        if let userAgent = self.userAgent {
            additionalHeaders["User-Agent"] = userAgent
        }
        sessionConfiguration.HTTPAdditionalHeaders = additionalHeaders
        let sessionManager = AFHTTPSessionManager(baseURL:baseURL, sessionConfiguration:sessionConfiguration)
        sessionManager.responseSerializer = WordPressComRestAPIResponseSerializer()
        sessionManager.requestSerializer = AFJSONRequestSerializer()
        return sessionManager
    }()

    public init(oAuthToken: String? = nil, userAgent: String? = nil) {
        self.oAuthToken = oAuthToken
        self.userAgent = userAgent
        super.init()
    }

    deinit {
        sessionManager.invalidateSessionCancelingTasks(false)
    }

    /**
     Cancels all ongoing taks and makes the session invalid so the object will not fullfil any more request
     */
    public func invalidateAndCancelTasks() {
        sessionManager.invalidateSessionCancelingTasks(true)
    }

    //MARK: - Network requests

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
    public func GET(URLString: String,
                     parameters: [String:AnyObject]?,
                     success: SuccessResponseBlock,
                     failure: FailureReponseBlock) -> NSProgress?
    {
        let URLString = appendLocaleIfNeeded(URLString)
        let progress = NSProgress(totalUnitCount: 1)
        let progressUpdater = {(taskProgress:NSProgress) in
            progress.totalUnitCount = taskProgress.totalUnitCount
            progress.completedUnitCount = taskProgress.completedUnitCount
        }

        let task = sessionManager.GET(URLString, parameters: parameters, progress: progressUpdater, success: { [weak progress] (dataTask, result) in
                guard let responseObject = result else {
                    failure(error:WordPressComRestApiError.Unknown as NSError , httpResponse: dataTask.response as? NSHTTPURLResponse)
                    return
                }
                success(responseObject: responseObject, httpResponse: dataTask.response as? NSHTTPURLResponse)
                progress?.completedUnitCount = 1
            }, failure: { [weak progress] (dataTask, error) in
                failure(error: error, httpResponse: dataTask?.response as? NSHTTPURLResponse)
                progress?.completedUnitCount = 1
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
    public func POST(URLString: String,
                     parameters: [String:AnyObject]?,
                     success: SuccessResponseBlock,
                     failure: FailureReponseBlock) -> NSProgress?
    {
        let URLString = appendLocaleIfNeeded(URLString)
        let progress = NSProgress(totalUnitCount: 1)
        let progressUpdater = {(taskProgress:NSProgress) in
            progress.totalUnitCount = taskProgress.totalUnitCount
            progress.completedUnitCount = taskProgress.completedUnitCount
        }
        let task = sessionManager.POST(URLString, parameters: parameters, progress: progressUpdater, success: { [weak progress] (dataTask, result) in
                guard let responseObject = result else {
                    failure(error:WordPressComRestApiError.Unknown as NSError , httpResponse: dataTask.response as? NSHTTPURLResponse)
                    return
                }
                success(responseObject: responseObject, httpResponse: dataTask.response as? NSHTTPURLResponse)
                progress?.completedUnitCount = 1
            }, failure: { [weak progress] (dataTask, error) in
                failure(error: error, httpResponse: dataTask?.response as? NSHTTPURLResponse)
                progress?.completedUnitCount = 1
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
     - parameter success:    callback to be called on successful request
     - parameter failure:    callback to be called on failed request

     - returns:  a NSProgress object that can be used to track the progress of the upload and to cancel the upload. If the method
     returns nil it's because something happened on the request serialization and the network request was not started, but the failure callback
     will be invoked with the error specificing the serialization issues.
     */
    public func multipartPOST(URLString: String,
                              parameters: [String:AnyObject]?,
                              fileParts: [FilePart],
                              success: SuccessResponseBlock,
                              failure: FailureReponseBlock) -> NSProgress?
    {
        let URLString = appendLocaleIfNeeded(URLString)
        guard let baseURL = NSURL(string: WordPressComRestApi.apiBaseURLString),
            let requestURLString = NSURL(string:URLString,
                                     relativeToURL:baseURL)?.absoluteString else {
            let error = NSError(domain:String(WordPressComRestApiError),
                    code:WordPressComRestApiError.RequestSerializationFailed.rawValue,
                    userInfo:[NSLocalizedDescriptionKey: NSLocalizedString("Failed to serialize request to the REST API.", comment: "Error message to show when wrong URL format is used to access the REST API")])
            failure(error: error, httpResponse: nil)
            return nil
        }
        var serializationError: NSError?
        var filePartError: NSError?
        let request = sessionManager.requestSerializer.multipartFormRequestWithMethod("POST",
          URLString: requestURLString,
          parameters: parameters,
          constructingBodyWithBlock:{ (formData: AFMultipartFormData ) in
            do {
                for filePart in fileParts {
                    let url = filePart.url
                    try formData.appendPartWithFileURL(url, name:filePart.parameterName, fileName:filePart.filename, mimeType:filePart.mimeType)
                }
            } catch let error as NSError {
                filePartError = error
            }
          },
          error: &serializationError
        )
        if let error = filePartError {
            failure(error: error, httpResponse: nil)
            return nil
        }
        if let error = serializationError {
            failure(error: error, httpResponse: nil)
            return nil
        }
        let progress = NSProgress(totalUnitCount: 1)
        let progressUpdater = {(taskProgress:NSProgress) in
            progress.totalUnitCount = taskProgress.totalUnitCount+1
            progress.completedUnitCount = taskProgress.completedUnitCount
        }
        let task = self.sessionManager.uploadTaskWithStreamedRequest(request, progress: progressUpdater) { (response, result, error) in
            progress.completedUnitCount = progress.totalUnitCount

            if let error = error {
                failure(error: error, httpResponse: response as? NSHTTPURLResponse)
            } else {
                guard let responseObject = result else {
                    failure(error:WordPressComRestApiError.Unknown as NSError , httpResponse: response as? NSHTTPURLResponse)
                    return
                }
                success(responseObject: responseObject, httpResponse: response as? NSHTTPURLResponse)
            }
        }
        task.resume()
        progress.cancellationHandler = {
            task.cancel()
        }
        if let sizeString = request.allHTTPHeaderFields?["Content-Length"],
           let size = Int64(sizeString) {
            progress.totalUnitCount = size
        }
        return progress
    }

    public func hasCredentials() -> Bool {
        guard let authToken = oAuthToken else {
            return false
        }
        return !(authToken.isEmpty)
    }

    override public var hashValue: Int {
        return "\(oAuthToken),\(userAgent)".hashValue
    }

    private func appendLocaleIfNeeded(path: String) -> String {
        guard appendsPreferredLanguageLocale else {
            return path
        }
        return WordPressComRestApi.pathByAppendingPreferredLanguageLocale(path)
    }
}

/// FilePart represents the infomartion needed to encode a file on a multipart form request
public final class FilePart : NSObject
{
    let parameterName: String
    let url: NSURL
    let filename: String
    let mimeType: String

    init(parameterName: String, url: NSURL, filename: String, mimeType: String) {
        self.parameterName = parameterName
        self.url = url
        self.filename = filename
        self.mimeType = mimeType
    }
}

/// A custom serializer to handle JSON error responses when status codes are betwen 400 and 500
final class WordPressComRestAPIResponseSerializer: AFJSONResponseSerializer
{
    override init() {
        super.init()
        let extraStatusCodes = NSMutableIndexSet(indexSet: self.acceptableStatusCodes!)
        extraStatusCodes.addIndexesInRange(NSRange(400...500))
        self.acceptableStatusCodes = extraStatusCodes
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func responseObjectForResponse(response: NSURLResponse?, data: NSData?, error: NSErrorPointer) -> AnyObject? {

        let responseObject = super.responseObjectForResponse(response, data: data, error: error)

        guard let httpResponse = response as? NSHTTPURLResponse where (400...500).contains(httpResponse.statusCode) else {
            return responseObject
        }

        var userInfo: [NSObject: AnyObject] = [:]
        if let originalError = error.memory {
            userInfo = originalError.userInfo
        }

        guard let responseDictionary = responseObject as? [String:AnyObject] else {
            return responseObject
        }
        var errorDictionary:AnyObject? = responseDictionary
        if let errorArray = responseDictionary["errors"] as? [AnyObject] where errorArray.count > 0 {
            errorDictionary = errorArray.first
        }
        guard let errorEntry = errorDictionary as? [String:AnyObject],
            let errorCode = errorEntry["error"] as? String,
            let errorDescription = errorEntry["message"] as? String
            else {
                return responseObject
        }

        let errorsMap = [
            "invalid_input" : WordPressComRestApiError.InvalidInput,
            "invalid_token" : WordPressComRestApiError.InvalidToken,
            "authorization_required" : WordPressComRestApiError.AuthorizationRequired,
            "upload_error" : WordPressComRestApiError.UploadFailed,
            "unauthorized" : WordPressComRestApiError.AuthorizationRequired
        ]

        let mappedError = errorsMap[errorCode] ?? WordPressComRestApiError.Unknown
        userInfo[WordPressComRestApi.ErrorKeyErrorCode] = errorCode
        userInfo[WordPressComRestApi.ErrorKeyErrorMessage] = errorDescription
        let nserror = mappedError as NSError
        userInfo[NSLocalizedDescriptionKey] =  errorDescription
        error.memory = NSError(domain:nserror.domain,
                               code:nserror.code,
                               userInfo:userInfo
            )
        return responseObject
    }
}

extension WordPressComRestApi
{
    /// Returns an Api object without an oAuthtoken defined and with the userAgent set for the WordPress App user agent
    class public func anonymousApi() -> WordPressComRestApi {
        return WordPressComRestApi(oAuthToken: nil, userAgent: WPUserAgent.wordPressUserAgent())
    }

    /// Append the user's preferred device locale as a query param to the URL path.
    /// If the locale already exists the original path is returned.
    ///
    /// - Parameters:
    ///     - path: A URL string. Can be an absolute or relative URL string.
    ///
    /// - Returns: The path with the locale appended, or the original path if it already had a locale param.
    ///
    class public func pathByAppendingPreferredLanguageLocale(path: String) -> String {
        let localeKey = WordPressComRestApi.localeKey
        if path.isEmpty || path.containsString("\(localeKey)=") {
            return path
        }
        let preferredLanguageIdentifier = WordPressComLanguageDatabase().deviceLanguage.slug
        let separator = path.containsString("?") ? "&" : "?"
        return "\(path)\(separator)\(localeKey)=\(preferredLanguageIdentifier)"
    }
}
