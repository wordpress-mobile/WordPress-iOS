import Foundation
import AFNetworking

/**
 Error constants for the WordPress.com REST API

 - InvalidInput:                   The parameters sent to the server where invalid
 - InvalidToken:                   The token provided was invalid
 - AuthorizationRequired:          Permission required to access resource
 - UploadFailed:                   The upload failed
 - Unknown:                        Unknow error happen
 */
public enum WordPressComRestApiError: Int, ErrorType {
    case InvalidInput
    case InvalidToken
    case AuthorizationRequired
    case UploadFailed
    case Unknown
}

public final class WordPressComRestApi: NSObject
{
    public typealias SuccessResponseBlock = (responseObject: AnyObject, httpResponse: NSHTTPURLResponse?) -> ()
    public typealias FailureReponseBlock = (error: NSError, httpResponse: NSHTTPURLResponse?) -> ()

    private static let endpointURL: String = "https://public-api.wordpress.com/rest/"

    private let oAuthToken: String

    private lazy var sessionManager: AFHTTPSessionManager = {
        let baseURL = NSURL(string:WordPressComRestApi.endpointURL)
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfiguration.HTTPAdditionalHeaders = ["Authorization": "Bearer \(self.oAuthToken)"]
        let sessionManager = AFHTTPSessionManager(baseURL:baseURL, sessionConfiguration:sessionConfiguration)
        sessionManager.responseSerializer = WordPressComRestAPIResponseSerializer()
        sessionManager.requestSerializer = AFJSONRequestSerializer()
        return sessionManager
    }()

    public init(oAuthToken: String) {
        self.oAuthToken = oAuthToken
    }

    deinit {
        sessionManager.invalidateSessionCancelingTasks(true);
    }
    /**
     Reset the API instance

     Invalidates the session and cancel all pending requests
     */
    public func reset() {        
        sessionManager.invalidateSessionCancelingTasks(true);
    }

    //MARK: - Network requests

    public func GET(URLString: String,
                     parameters:[NSString:AnyObject]?,
                     success:SuccessResponseBlock,
                     failure:FailureReponseBlock) -> NSProgress
    {
        let progress = NSProgress()
        progress.totalUnitCount = 1
        let task = sessionManager.GET(URLString, parameters: parameters, success: { (dataTask, result) in
                success(responseObject: result, httpResponse: dataTask.response as? NSHTTPURLResponse)
                progress.completedUnitCount = 1;
            }, failure: { (dataTask, error) in
                failure(error: error, httpResponse: dataTask?.response as? NSHTTPURLResponse)
                progress.completedUnitCount = 1;
            }
        )
        progress.cancellationHandler = {
            task?.cancel()
        }
        return progress
    }

    public func POST(URLString: String,
                     parameters:[NSString:AnyObject]?,
                     success:SuccessResponseBlock,
                     failure:FailureReponseBlock) -> NSProgress
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
        progress.cancellationHandler = {
            task?.cancel()
        }
        return progress
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

        let mappedCode = errorsMap[errorCode]?.rawValue ?? WordPressComRestApiError.Unknown.rawValue;

        error.memory = NSError(domain:String(WordPressComRestApiError),
                               code:mappedCode,
                               userInfo:[NSLocalizedDescriptionKey: errorDescription])
        return responseObject
    }
}
