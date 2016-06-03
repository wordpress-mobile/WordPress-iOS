import Foundation
import AFNetworking
import wpxmlrpc

public class WordPressOrgXMLRPCApi: NSObject
{
    public typealias SuccessResponseBlock = (responseObject: AnyObject, httpResponse: NSHTTPURLResponse?) -> ()
    public typealias FailureReponseBlock = (error: NSError, httpResponse: NSHTTPURLResponse?) -> ()

    private let apiBaseURLString: String
    private let userAgent: String?

    private lazy var sessionManager: AFHTTPSessionManager = {
        let baseURL = NSURL(string:self.apiBaseURLString)
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        var additionalHeaders: [String : AnyObject] = ["Accept-Encoding":"gzip, deflate"]
        if let userAgent = self.userAgent {
            additionalHeaders["User-Agent"] = userAgent
        }
        sessionConfiguration.HTTPAdditionalHeaders = additionalHeaders
        let sessionManager = AFHTTPSessionManager(baseURL:baseURL, sessionConfiguration:sessionConfiguration)
        sessionManager.responseSerializer = WordPressOrgXMLRPCResponseSerializer()
        sessionManager.requestSerializer = WordPressOrgXMLRPCRequestSerializer()
        return sessionManager
    }()

    public init(apiBaseURLString: String, userAgent: String? = nil) {
        self.apiBaseURLString = apiBaseURLString
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
    public func callMethod(method: String,
                    parameters: [AnyObject]?,
                    success: SuccessResponseBlock,
                    failure: FailureReponseBlock) -> NSProgress?
    {
        let progress = NSProgress()
        progress.totalUnitCount = 1
        let xmlRPCParameters = XMLRPCCallParameters(method: method, parameters: parameters)
        let task = sessionManager.POST(apiBaseURLString, parameters: xmlRPCParameters, success: { (dataTask, result) in
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
}

private final class XMLRPCCallParameters {
    let method: String
    let parameters: [AnyObject]?
    let streamingCacheFile: NSURL?

    init(method:String, parameters:[AnyObject]? = nil, streamingCacheFile: NSURL? = nil) {
        self.method = method
        self.parameters = parameters
        self.streamingCacheFile = streamingCacheFile
    }
}

/**
 Error constants for the WordPress XMLRPC API

 - CallNeedtoBePOST:                   The parameters sent to the server where invalid
 - RequestSerializationFailed:     The serialization of the request failed
 - Unknown:                        Unknow error happen
 */
@objc public enum WordPressOrgXMLRPCApiError: Int, ErrorType {
    case CallNeedsToBePOST
    case InvalidArguments
    case RequestSerializationFailed
    case Unknown
}

/// A custom serializer to handle XMLRPC responses
final class WordPressOrgXMLRPCResponseSerializer: AFHTTPResponseSerializer
{
    override init() {
        super.init()
        self.acceptableContentTypes = ["application/xml", "text/xml"]
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func responseObjectForResponse(response: NSURLResponse?, data: NSData?, error: NSErrorPointer) -> AnyObject? {
        let responseObject = super.responseObjectForResponse(response, data: data, error: error)
        guard error.memory == nil,
            let unwrappedData = data else {
            return responseObject
        }
        let decoder = WPXMLRPCDecoder(data:unwrappedData)

        guard !decoder.isFault(),
            let responseXML = decoder.object() else {
            let decoderError = decoder.error()
            error.memory = decoderError
            return responseObject
        }

        return responseXML
    }
}

/// A custom serializer to handle XMLRPC requests
final class WordPressOrgXMLRPCRequestSerializer: AFHTTPRequestSerializer
{
    override func requestBySerializingRequest(request: NSURLRequest, withParameters parameters: AnyObject?, error: NSErrorPointer) -> NSURLRequest?
    {
        if request.HTTPMethod?.uppercaseString != "POST" {
            // return error because XMLRPC only works with POST requests
            let nserror = WordPressOrgXMLRPCApiError.CallNeedsToBePOST as NSError
            error.memory = NSError(domain:nserror.domain,
                                   code:nserror.code,
                                   userInfo:[NSLocalizedDescriptionKey: NSLocalizedString("XMLRPC Calls need to be HTTP POST", comment:"")])
            return nil
        }
        guard let xmlRPCCallParameters = parameters as? XMLRPCCallParameters else {
            // return error because XMLRPC request must have a XMLRPCCallParameters object as parameter
            let nserror = WordPressOrgXMLRPCApiError.InvalidArguments as NSError
            error.memory = NSError(domain:nserror.domain,
                                   code:nserror.code,
                                   userInfo:[NSLocalizedDescriptionKey: NSLocalizedString("XMLRPC Calls need to use a XMLRPCCallParameters class",  comment:"")])
            return nil
        }
        let mutableRequest: NSMutableURLRequest = request.mutableCopy() as! NSMutableURLRequest

        for (field,value) in HTTPRequestHeaders {
            if request.valueForHTTPHeaderField(field as! String) == nil {
                mutableRequest.setValue(value as? String, forHTTPHeaderField: field as! String)
            }
        }

        let encoder = WPXMLRPCEncoder(method:xmlRPCCallParameters.method, andParameters:xmlRPCCallParameters.parameters)
        do {
            mutableRequest.HTTPBody = try encoder.dataEncoded()
        } catch let encodingError as NSError {
            error.memory = encodingError
        }

        return mutableRequest
    }
}
