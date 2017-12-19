import Foundation
import wpxmlrpc
import Alamofire

/// Class to connect to the XMLRPC API on self hosted sites.
open class WordPressOrgXMLRPCApi: NSObject {
    public typealias SuccessResponseBlock = (AnyObject, HTTPURLResponse?) -> ()
    public typealias FailureReponseBlock = (_ error: NSError, _ httpResponse: HTTPURLResponse?) -> ()

    fileprivate let endpoint: URL
    fileprivate let userAgent: String?
    fileprivate var backgroundUploads: Bool
    fileprivate var backgroundSessionIdentifier: String
    @objc open static let defaultBackgroundSessionIdentifier = "org.wordpress.wporgxmlrpcapi"

    fileprivate lazy var sessionManager: Alamofire.SessionManager = {
        let sessionConfiguration = URLSessionConfiguration.default
        let sessionManager = self.makeSessionManager(configuration: sessionConfiguration)
        return sessionManager
    }()

    fileprivate lazy var uploadSessionManager: Alamofire.SessionManager = {
        if self.backgroundUploads {
            let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: self.backgroundSessionIdentifier)
            let sessionManager = self.makeSessionManager(configuration: sessionConfiguration)
            return sessionManager
        }

        return self.sessionManager
    }()

    fileprivate func makeSessionManager(configuration sessionConfiguration: URLSessionConfiguration) -> Alamofire.SessionManager {
        var additionalHeaders: [String : AnyObject] = ["Accept-Encoding": "gzip, deflate" as AnyObject]
        if let userAgent = self.userAgent {
            additionalHeaders["User-Agent"] = userAgent as AnyObject?
        }
        sessionConfiguration.httpAdditionalHeaders = additionalHeaders
        let sessionManager = Alamofire.SessionManager(configuration: sessionConfiguration)

        let sessionDidReceiveChallengeWithCompletion: ((URLSession, URLAuthenticationChallenge, @escaping(URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void) = { session, authenticationChallenge, completionHandler in
            return self.urlSession(session, didReceive: authenticationChallenge, completionHandler: completionHandler)
        }
        sessionManager.delegate.sessionDidReceiveChallengeWithCompletion = sessionDidReceiveChallengeWithCompletion

        let  taskDidReceiveChallengeWithCompletion: ((URLSession, URLSessionTask, URLAuthenticationChallenge,  @escaping(URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void) = { session, task, authenticationChallenge, completionHandler in
            return self.urlSession(session, task: task, didReceive: authenticationChallenge, completionHandler: completionHandler)
        }
        sessionManager.delegate.taskDidReceiveChallengeWithCompletion = taskDidReceiveChallengeWithCompletion
        return sessionManager
    }

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
        sessionManager.session.finishTasksAndInvalidate()
        uploadSessionManager.session.finishTasksAndInvalidate()
    }

    /**
     Cancels all ongoing and makes the session so the object will not fullfil any more request
     */
    @objc open func invalidateAndCancelTasks() {
        sessionManager.session.invalidateAndCancel()
        uploadSessionManager.session.invalidateAndCancel()
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
        //Encode request
        let request: URLRequest
        do {
            request = try requestWithMethod(method, parameters: parameters)
        } catch let encodingError as NSError {
            failure(encodingError, nil)
            return nil
        }

        let progress: Progress = Progress.discreteProgress(totalUnitCount: 1)
        sessionManager.request(request)
            .downloadProgress { (requestProgress) in
                progress.totalUnitCount = requestProgress.totalUnitCount + 1
                progress.completedUnitCount = requestProgress.completedUnitCount
            }.response(queue: DispatchQueue.global()) { (response) in
                progress.completedUnitCount = progress.totalUnitCount
                do {
                    let responseObject = try self.handleResponseWithData(response.data, urlResponse: response.response, error: response.error as NSError?)
                    DispatchQueue.main.async {
                        success(responseObject, response.response)
                    }
                } catch let error as NSError {
                    DispatchQueue.main.async {
                        failure(error, response.response)
                    }
                    return
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
        let progress: Progress = Progress.discreteProgress(totalUnitCount: 1)
        DispatchQueue.global().async {
            let fileURL = self.URLForTemporaryFile()
            //Encode request
            let request: URLRequest
            do {
                request = try self.streamingRequestWithMethod(method, parameters: parameters, usingFileURLForCache: fileURL)
            } catch let encodingError as NSError {
                failure(encodingError, nil)
                return
            }

            self.uploadSessionManager.upload(fileURL, with: request)
                .uploadProgress { (requestProgress) in
                    progress.totalUnitCount = requestProgress.totalUnitCount + 1
                    progress.completedUnitCount = requestProgress.completedUnitCount
                }.response(queue: DispatchQueue.global()) { (response) in
                    progress.completedUnitCount = progress.totalUnitCount
                    do {
                        let responseObject = try self.handleResponseWithData(response.data, urlResponse: response.response, error: response.error as NSError?)
                        DispatchQueue.main.async {
                            success(responseObject, response.response)
                        }
                    } catch let error as NSError {
                        DispatchQueue.main.async {
                            failure(error, response.response)
                        }
                        return
                    }
            }
        }

        return progress
    }

    // MARK: - Request Building

    fileprivate func requestWithMethod(_ method: String, parameters: [AnyObject]?) throws -> URLRequest {
        let mutableRequest = NSMutableURLRequest(url: endpoint)
        mutableRequest.httpMethod = "POST"
        mutableRequest.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        let encoder = WPXMLRPCEncoder(method: method, andParameters: parameters)
        mutableRequest.httpBody = try encoder.dataEncoded()

        return mutableRequest as URLRequest
    }

    fileprivate func streamingRequestWithMethod(_ method: String, parameters: [AnyObject]?, usingFileURLForCache fileURL: URL) throws -> URLRequest {
        let mutableRequest = NSMutableURLRequest(url: endpoint)
        mutableRequest.httpMethod = "POST"
        mutableRequest.setValue("text/xml", forHTTPHeaderField: "Content-Type")
        let encoder = WPXMLRPCEncoder(method: method, andParameters: parameters)
        try encoder.encode(toFile: fileURL.path)
        var optionalFileSize: AnyObject?
        try (fileURL as NSURL).getResourceValue(&optionalFileSize, forKey: URLResourceKey.fileSizeKey)
        if let fileSize = optionalFileSize as? NSNumber {
            mutableRequest.setValue(fileSize.stringValue, forHTTPHeaderField: "Content-Length")
        }

        return mutableRequest as URLRequest
    }

    fileprivate func URLForTemporaryFile() -> URL {
        let fileName = "\(ProcessInfo.processInfo.globallyUniqueString)_file.xmlrpc"
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        return fileURL
    }

    // MARK: - Handling of data

    fileprivate func handleResponseWithData(_ originalData: Data?, urlResponse: URLResponse?, error: NSError?) throws -> AnyObject {
        guard let data = originalData,
            let httpResponse = urlResponse as? HTTPURLResponse,
            let contentType = httpResponse.allHeaderFields["Content-Type"] as? String, error == nil else {
                if let unwrappedError = error {
                    throw convertError(unwrappedError, data: originalData)
                } else {
                    throw convertError(WordPressOrgXMLRPCApiError.unknown as NSError, data: originalData)
                }
        }

        if ["application/xml", "text/xml"].filter({ (type) -> Bool in return contentType.hasPrefix(type)}).count == 0 {
            throw convertError(WordPressOrgXMLRPCApiError.responseSerializationFailed as NSError, data: originalData)
        }

        guard let decoder = WPXMLRPCDecoder(data: data) else {
            throw WordPressOrgXMLRPCApiError.responseSerializationFailed
        }
        guard !(decoder.isFault()), let responseXML = decoder.object() else {
            if let decoderError = decoder.error() {
                throw convertError(decoderError as NSError, data: data)
            } else {
                throw WordPressOrgXMLRPCApiError.responseSerializationFailed
            }
        }

        return responseXML as AnyObject
    }

    @objc open static let WordPressOrgXMLRPCApiErrorKeyData = "WordPressOrgXMLRPCApiErrorKeyData"
    @objc open static let WordPressOrgXMLRPCApiErrorKeyDataString = "WordPressOrgXMLRPCApiErrorKeyDataString"

    fileprivate func convertError(_ error: NSError, data: Data?) -> NSError {
        if let data = data {
            var userInfo: [AnyHashable: Any] = error.userInfo
            userInfo[type(of: self).WordPressOrgXMLRPCApiErrorKeyData] = data
            userInfo[type(of: self).WordPressOrgXMLRPCApiErrorKeyDataString] = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            return NSError(domain: error.domain, code: error.code, userInfo: userInfo as? [String : Any])
        }
        return error
    }
}

extension WordPressOrgXMLRPCApi {

    @objc public func urlSession(_ session: URLSession,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodServerTrust:
            if let credential = URLCredentialStorage.shared.defaultCredential(for: challenge.protectionSpace), challenge.previousFailureCount == 0 {
                completionHandler(.useCredential, credential)
                return
            }
            var result = SecTrustResultType.invalid
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let certificateStatus = SecTrustEvaluate(serverTrust, &result)
                if certificateStatus == 0 && result == SecTrustResultType.recoverableTrustFailure {
                    DispatchQueue.main.async(execute: { () in
                        HTTPAuthenticationAlertController.presentWithChallenge(challenge, handler: completionHandler)
                    })
                } else {
                    completionHandler(.performDefaultHandling, nil)
                }
            }
        default:
            completionHandler(.performDefaultHandling, nil)
        }
    }

    @objc public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didReceive challenge: URLAuthenticationChallenge,
                                       completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodHTTPBasic:
            if let credential = URLCredentialStorage.shared.defaultCredential(for: challenge.protectionSpace), challenge.previousFailureCount == 0 {
                completionHandler(.useCredential, credential)
            } else {
                DispatchQueue.main.async(execute: { () in
                    HTTPAuthenticationAlertController.presentWithChallenge(challenge, handler: completionHandler)
                })
            }
        default:
            completionHandler(.performDefaultHandling, nil)
        }
    }


}

/**
 Error constants for the WordPress XMLRPC API
 - RequestSerializationFailed:     The serialization of the request failed
 - ResponseSerializationFailed:     The serialization of the response failed
 - Unknown:                        Unknow error happen
 */
@objc public enum WordPressOrgXMLRPCApiError: Int, Error {
    case requestSerializationFailed
    case responseSerializationFailed
    case unknown
}
