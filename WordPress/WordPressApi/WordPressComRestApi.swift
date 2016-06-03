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
    case Unknown
}

public class WordPressComRestApi: NSObject
{
    public typealias SuccessResponseBlock = (responseObject: AnyObject, httpResponse: NSHTTPURLResponse?) -> ()
    public typealias FailureReponseBlock = (error: NSError, httpResponse: NSHTTPURLResponse?) -> ()

    public static let apiBaseURLString: String = "https://public-api.wordpress.com/rest/"

    private let oAuthToken: String?
    private var userAgent: String?

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
     Cancels all ongoing and makes the session so the object will not fullfil any more request
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
        let progress = NSProgress()
        progress.totalUnitCount = 1
        let task = sessionManager.GET(URLString, parameters: parameters, success: { (dataTask, result) in
                success(responseObject: result, httpResponse: dataTask.response as? NSHTTPURLResponse)
                progress.completedUnitCount = 1
            }, failure: { (dataTask, error) in
                failure(error: error, httpResponse: dataTask?.response as? NSHTTPURLResponse)
                progress.completedUnitCount = 1
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
        let progress = NSProgress()
        progress.totalUnitCount = 1
        let task = sessionManager.POST(URLString, parameters: parameters, success: { (dataTask, result) in
                success(responseObject: result, httpResponse: dataTask.response as? NSHTTPURLResponse)
                progress.completedUnitCount = 1
            }, failure: { (dataTask, error) in
                failure(error: error, httpResponse: dataTask?.response as? NSHTTPURLResponse)
                progress.completedUnitCount = 1
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
        guard let baseURL = NSURL(string: WordPressComRestApi.apiBaseURLString),
            let requestURLString = NSURL(string:URLString,
                                     relativeToURL:baseURL)?.absoluteString else {
            let error = NSError(domain:String(WordPressComRestApiError),
                    code:WordPressComRestApiError.RequestSerializationFailed.rawValue,
                    userInfo:[NSLocalizedDescriptionKey: NSLocalizedString("Failed to serialize request to the REST API.", comment: "Error message to show when wrong URL format is used to access the REST API")])
            failure(error: error, httpResponse: nil)
            return nil
        }
        var error: NSError?
        let request = sessionManager.requestSerializer.multipartFormRequestWithMethod("POST",
          URLString: requestURLString,
          parameters: parameters!,
          constructingBodyWithBlock:{ (formData: AFMultipartFormData ) in
            for filePart in fileParts {
                let url = filePart.url
                do {
                    try formData.appendPartWithFileURL(url, name:filePart.parameterName, fileName:filePart.filename, mimeType:filePart.mimeType)
                } catch let error as NSError {
                    failure(error: error, httpResponse: nil)
                }
            }
            },
          error: &error
        )
        if let error = error {
            failure(error: error, httpResponse: nil)
            return nil
        }
        var progress : NSProgress?
        let task = self.sessionManager.uploadTaskWithStreamedRequest(request, progress: &progress) { (response, responseObject, error) in
            if let error = error {
                failure(error: error, httpResponse: response as? NSHTTPURLResponse)
            } else {
                success(responseObject: responseObject!, httpResponse: response as? NSHTTPURLResponse)
            }
        }
        task.resume()
        progress?.cancellationHandler = {
            task.cancel()
        }

        return progress
    }

    public func hasCredentials() -> Bool {
        guard let authToken = oAuthToken else {
            return false
        }
        return !(authToken.isEmpty)
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

        var errorObject = responseObject
        if let errorArray = responseObject as? [AnyObject] where errorArray.count > 0 {
            errorObject = errorArray.first
        }
        guard let responseDictionary = errorObject as? [String:AnyObject],
            let errorCode = responseDictionary["error"] as? String,
            let errorDescription = responseDictionary["message"] as? String
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
        let nserror = mappedError as NSError
        error.memory = NSError(domain:nserror.domain,
                               code:nserror.code,
                               userInfo:[NSLocalizedDescriptionKey: errorDescription])
        return responseObject
    }
}
