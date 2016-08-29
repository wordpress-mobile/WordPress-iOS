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
    case ResponseSerializationFailed
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
    private var ongoingProgress = [NSURLSessionTask:NSProgress]()

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

    private var uploadSession: NSURLSession {
        get {
            let sessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
            sessionConfiguration.URLCache = nil
            sessionConfiguration.requestCachePolicy = .ReloadIgnoringLocalCacheData
            var additionalHeaders: [String : AnyObject] = [:]
            if let oAuthToken = self.oAuthToken {
                additionalHeaders["Authorization"] = "Bearer \(oAuthToken)"
            }
            if let userAgent = self.userAgent {
                additionalHeaders["User-Agent"] = userAgent
            }
            sessionConfiguration.HTTPAdditionalHeaders = additionalHeaders
            let uploadSession = NSURLSession(configuration:sessionConfiguration, delegate: self, delegateQueue: nil)
            return uploadSession
        }
    }

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

        let task = sessionManager.GET(URLString, parameters: parameters, progress: progressUpdater, success: { (dataTask, result) in
                guard let responseObject = result else {
                    failure(error:WordPressComRestApiError.Unknown as NSError , httpResponse: dataTask.response as? NSHTTPURLResponse)
                    return
                }
                success(responseObject: responseObject, httpResponse: dataTask.response as? NSHTTPURLResponse)
                progress.completedUnitCount = progress.totalUnitCount
            }, failure: { (dataTask, error) in
                failure(error: error, httpResponse: dataTask?.response as? NSHTTPURLResponse)
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
        let task = sessionManager.POST(URLString, parameters: parameters, progress: progressUpdater, success: { (dataTask, result) in
                guard let responseObject = result else {
                    failure(error:WordPressComRestApiError.Unknown as NSError , httpResponse: dataTask.response as? NSHTTPURLResponse)
                    return
                }
                success(responseObject: responseObject, httpResponse: dataTask.response as? NSHTTPURLResponse)
                progress.completedUnitCount = progress.totalUnitCount
            }, failure: { (dataTask, error) in
                failure(error: error, httpResponse: dataTask?.response as? NSHTTPURLResponse)
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
        let fileURL = URLForTemporaryFile()
        guard
            let request = multipartRequestWithURLString(URLString,
                                                        parameters: parameters ?? [:],
                                                        fileParts: fileParts,
                                                        encodedToFileURL: fileURL)
        else {
            let error = NSError(domain:String(WordPressComRestApiError),
                                code:WordPressComRestApiError.RequestSerializationFailed.rawValue,
                                userInfo:[NSLocalizedDescriptionKey: NSLocalizedString("Failed to serialize request to the REST API.", comment: "Error message to show when wrong URL format is used to access the REST API")])
            failure(error: error, httpResponse: nil)
            return nil
        }
        let progress = NSProgress.discreteProgressWithTotalUnitCount(1)
        let session = uploadSession
        var referenceToTask: NSURLSessionTask?
        let task = session.uploadTaskWithRequest(request, fromFile: fileURL) { (data, response, error) in
            if let taskToRemove = referenceToTask {
                self.ongoingProgress.removeValueForKey(taskToRemove)
            }
            session.finishTasksAndInvalidate()
            let _ = try? NSFileManager.defaultManager().removeItemAtURL(fileURL)
            do {
                let responseObject = try self.handleResponseWithData(data, urlResponse: response, error: error)
                progress.completedUnitCount = progress.totalUnitCount
                success(responseObject: responseObject, httpResponse: response as? NSHTTPURLResponse)
            } catch let error as NSError {
                failure(error: error, httpResponse: response as? NSHTTPURLResponse)
            }
        }
        referenceToTask = task
        task.resume()

        associate(progress: progress, toTask:task)

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

    private func URLForTemporaryFile() -> NSURL {
        let fileName = "\(NSProcessInfo.processInfo().globallyUniqueString)_file.tmp"
        let fileURL = NSURL.fileURLWithPath(NSTemporaryDirectory()).URLByAppendingPathComponent(fileName)
        return fileURL
    }

    private func multipartRequestWithURLString(urlString:String, parameters: [String:AnyObject], fileParts: [FilePart], encodedToFileURL fileURL:NSURL) -> NSURLRequest? {
        let urlStringWithLocale = appendLocaleIfNeeded(urlString)
        guard let baseURL = NSURL(string: WordPressComRestApi.apiBaseURLString),
              let url = NSURL(string:urlStringWithLocale, relativeToURL:baseURL)
        else {
            return nil
        }
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        let boundary = NSUUID().UUIDString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField:"Content-Type")
        let body = NSMutableData()

        for (key, text) in parameters where text is String {
            body.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            body.appendData("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            body.appendData("\(text)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        body.writeToURL(fileURL, atomically:true)
        guard let fileHandle = try? NSFileHandle(forUpdatingURL:fileURL) else {
            return nil
        }
        defer {
            fileHandle.closeFile()
        }
        fileHandle.seekToEndOfFile()
        for filePart in fileParts {
            let filename = filePart.filename
            let mimeType = filePart.mimeType
            guard let data = try? NSData(contentsOfURL:filePart.url, options:[.DataReadingMappedIfSafe]) else {
                return nil
            }
            fileHandle.writeData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            fileHandle.writeData("Content-Disposition: form-data; name=\"\(filePart.parameterName)\"; filename=\"\(filename)\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            fileHandle.writeData("Content-Type: \(mimeType)\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            fileHandle.writeData(data)
            fileHandle.writeData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        fileHandle.writeData("--\(boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        return request
    }

    //MARK: - Progress reporting

    private func associate(progress progress:NSProgress, toTask task: NSURLSessionTask) {
        // Progress report
        progress.totalUnitCount = 1
        if let contentLengthString = task.originalRequest?.allHTTPHeaderFields?["Content-Length"],
           let contentLength = Int64(contentLengthString)
        {
            progress.totalUnitCount = contentLength + 1
        }
        progress.cancellationHandler = {
            task.cancel()
        }
        ongoingProgress[task] = progress
    }

    //MARK: - Response handling

    private func handleResponseWithData(originalData: NSData?, urlResponse:NSURLResponse?, error: NSError?) throws -> AnyObject {
        guard let data = originalData,
              let httpResponse = urlResponse as? NSHTTPURLResponse,
              let contentType = httpResponse.allHeaderFields["Content-Type"] as? String
              where error == nil &&  contentType.hasPrefix("application/json")
        else {
            if let unwrappedError = error {
                throw convertError(unwrappedError, data: originalData)
            } else {
                throw convertError(WordPressComRestApiError.ResponseSerializationFailed as NSError, data: originalData)
            }
        }

        let jsonObject: AnyObject

        do {
            jsonObject = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions())
        } catch {
            throw convertError(WordPressComRestApiError.ResponseSerializationFailed as NSError, data: originalData)
        }
        if (200..<300).contains(httpResponse.statusCode) {
            return jsonObject
        }
        if (400...500).contains(httpResponse.statusCode) {
            throw handleErrorResponseObject(jsonObject, originalData: data)
        }
        throw convertError(WordPressComRestApiError.ResponseSerializationFailed as NSError, data: originalData)
    }

    //MARK: - Error Handling

    private func handleErrorResponseObject(responseObject: AnyObject, originalData:NSData) -> NSError {
        guard let responseDictionary = responseObject as? [String:AnyObject] else {
            return convertError(WordPressComRestApiError.ResponseSerializationFailed as NSError, data: originalData)
        }
        var errorDictionary:AnyObject? = responseDictionary
        if let errorArray = responseDictionary["errors"] as? [AnyObject] where errorArray.count > 0 {
            errorDictionary = errorArray.first
        }
        guard let errorEntry = errorDictionary as? [String:AnyObject],
            let errorCode = errorEntry["error"] as? String,
            let errorDescription = errorEntry["message"] as? String
            else {
                return convertError(WordPressComRestApiError.ResponseSerializationFailed as NSError, data: originalData)
        }

        let errorsMap = [
            "invalid_input" : WordPressComRestApiError.InvalidInput,
            "invalid_token" : WordPressComRestApiError.InvalidToken,
            "authorization_required" : WordPressComRestApiError.AuthorizationRequired,
            "upload_error" : WordPressComRestApiError.UploadFailed,
            "unauthorized" : WordPressComRestApiError.AuthorizationRequired
        ]

        let mappedError = errorsMap[errorCode] ?? WordPressComRestApiError.Unknown
        var userInfo = [String:AnyObject]()
        userInfo[WordPressComRestApi.ErrorKeyErrorCode] = errorCode
        userInfo[WordPressComRestApi.ErrorKeyErrorMessage] = errorDescription
        let nserror = mappedError as NSError
        userInfo[NSLocalizedDescriptionKey] = errorDescription
        return NSError(domain:nserror.domain,
                               code:nserror.code,
                               userInfo:userInfo
        )
    }

    public static let WordPressComRestCApiErrorKeyData = "WordPressOrgXMLRPCApiErrorKeyData"

    private func convertError(error: NSError, data: NSData?) -> NSError {
        guard let data = data else {
            return error
        }
        var userInfo:[NSObject:AnyObject] = error.userInfo ?? [:]
        userInfo[self.dynamicType.WordPressComRestCApiErrorKeyData] = data
        return NSError(domain: error.domain, code: error.code, userInfo: userInfo)
    }
}

extension WordPressComRestApi: NSURLSessionTaskDelegate, NSURLSessionDelegate {

    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let progress = ongoingProgress[task] else {
            return
        }
        progress.totalUnitCount = totalBytesExpectedToSend + 1
        progress.completedUnitCount = totalBytesSent

        if (totalBytesSent == totalBytesExpectedToSend) {
            ongoingProgress.removeValueForKey(task)
        }
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
