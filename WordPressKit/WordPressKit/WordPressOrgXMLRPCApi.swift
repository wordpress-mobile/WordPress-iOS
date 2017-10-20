import Foundation
import wpxmlrpc

open class WordPressOrgXMLRPCApi: NSObject {
    public typealias SuccessResponseBlock = (AnyObject, HTTPURLResponse?) -> ()
    public typealias FailureReponseBlock = (_ error: NSError, _ httpResponse: HTTPURLResponse?) -> ()

    fileprivate let endpoint: URL
    fileprivate let userAgent: String?
    fileprivate var ongoingUploads = [URLSessionTask: TaskAction]()
    fileprivate var backgroundUploads: Bool
    fileprivate var backgroundSessionIdentifier: String
    open static let defaultBackgroundSessionIdentifier = "org.wordpress.wporgxmlrpcapi"

    fileprivate lazy var session: URLSession = {
        let sessionConfiguration = URLSessionConfiguration.default
        let session = self.makeSession(configuration: sessionConfiguration)
        return session
    }()

    fileprivate lazy var uploadSession: URLSession = {
        if self.backgroundUploads {
            let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: self.backgroundSessionIdentifier)
            let session = self.makeSession(configuration: sessionConfiguration)
            return session
        }

        return self.session
    }()

    fileprivate func makeSession(configuration sessionConfiguration: URLSessionConfiguration) -> URLSession {
        var additionalHeaders: [String : AnyObject] = ["Accept-Encoding": "gzip, deflate" as AnyObject]
        if let userAgent = self.userAgent {
            additionalHeaders["User-Agent"] = userAgent as AnyObject?
        }
        sessionConfiguration.httpAdditionalHeaders = additionalHeaders
        let session = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        return session
    }

    /// Creates a new API object to connect to the WordPress XMLRPC API for the specified endpoint.
    ///
    /// - Parameters:
    ///   - endpoint: the endpoint to connect to the xmlrpc api interface.
    ///   - userAgent: the user agent to use on the connection.
    ///   - backgroundUploads:  If this value is true the API object will use a background session to execute uploads requests when using the `multipartPOST` function. The default value is false.
    ///   - backgroundSessionIdentifier: The session identifier to use for the background session. This must be unique in the system.
    public init(endpoint: URL, userAgent: String? = nil, backgroundUploads: Bool = false, backgroundSessionIdentifier: String) {
        self.endpoint = endpoint
        self.userAgent = userAgent
        self.backgroundUploads = backgroundUploads
        self.backgroundSessionIdentifier = backgroundSessionIdentifier
        super.init()
    }

    convenience public init(endpoint: URL, userAgent: String? = nil) {
        self.init(endpoint: endpoint, userAgent: userAgent, backgroundUploads: true, backgroundSessionIdentifier: WordPressOrgXMLRPCApi.defaultBackgroundSessionIdentifier + "." + endpoint.absoluteString)
    }

    deinit {
        session.finishTasksAndInvalidate()
        uploadSession.finishTasksAndInvalidate()
    }

    /**
     Cancels all ongoing and makes the session so the object will not fullfil any more request
     */
    open func invalidateAndCancelTasks() {
        session.invalidateAndCancel()
        uploadSession.finishTasksAndInvalidate()
    }

    // MARK: - Network requests
    /**
     Check if username and password are valid credentials for the xmlrpc endpoint.

     - parameter username: username to check
     - parameter password: password to check
     - parameter success:  callback block to be invoked if credentials are valid, the object returned in the block is the options dictionary for the site.
     - parameter failure:  callback block to be invoked is credentials fail
     */
    open func checkCredentials(_ username: String,
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
    @discardableResult open func callMethod(_ method: String,
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

        var progress: Progress?
        // Create task
        let task = session.dataTask(with: request, completionHandler: { (data, urlResponse, error) in
            if let uploadProgress = progress {
                uploadProgress.completedUnitCount = uploadProgress.totalUnitCount
            }
            do {
                let responseObject = try self.handleResponseWithData(data, urlResponse: urlResponse, error: error as NSError?)
                DispatchQueue.main.async {
                    success(responseObject, urlResponse as? HTTPURLResponse)
                }
            } catch let error as NSError {
                DispatchQueue.main.async {
                    failure(error, urlResponse as? HTTPURLResponse)
                }
                return
            }
        })
        let action = createUploadAction(task: task, success: nil, failure: nil)
        progress = action.progress
        task.resume()
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
    @discardableResult open func streamCallMethod(_ method: String,
                                 parameters: [AnyObject]?,
                                 success: @escaping SuccessResponseBlock,
                                 failure: @escaping FailureReponseBlock) -> Progress? {
        let fileURL = URLForTemporaryFile()
        //Encode request
        let request: URLRequest
        do {
            request = try streamingRequestWithMethod(method, parameters: parameters, usingFileURLForCache: fileURL)
        } catch let encodingError as NSError {
            failure(encodingError, nil)
            return nil
        }

        // Create task
        let session = uploadSession
        var progress: Progress?
        let task = session.uploadTask(with: request, fromFile: fileURL, completionHandler: { (data, urlResponse, error) in
            let _ = try? FileManager.default.removeItem(at: fileURL)
            do {
                let responseObject = try self.handleResponseWithData(data, urlResponse: urlResponse, error: error as NSError?)
                success(responseObject, urlResponse as? HTTPURLResponse)
            } catch let error as NSError {
                failure(error, urlResponse as? HTTPURLResponse)
            }
            if let uploadProgress = progress {
                uploadProgress.completedUnitCount = uploadProgress.totalUnitCount
            }
        })
        let action = createUploadAction(task: task, success: success, failure: failure)
        progress = action.progress

        task.resume()

        return action.progress
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

    // MARK: - Progress reporting

    struct TaskAction {
        let progress: Progress
        let success: SuccessResponseBlock?
        let failure: FailureReponseBlock?
    }

    fileprivate func createUploadAction(task: URLSessionTask, success: SuccessResponseBlock?,
                                               failure: FailureReponseBlock?) -> TaskAction {
        // Progress report
        let progress = Progress(parent: Progress.current(), userInfo: nil)
        progress.totalUnitCount = 1
        if let contentLengthString = task.originalRequest?.allHTTPHeaderFields?["Content-Length"],
            let contentLength = Int64(contentLengthString) {
            // Sergio Estevao: Add an extra 1 unit to the progress to take in account the upload response and not only the uploading of data
            progress.totalUnitCount = contentLength + 1
        }
        progress.cancellationHandler = {
            task.cancel()
        }
        let action = TaskAction(progress: progress, success: success, failure: failure)
        ongoingUploads[task] = action

        return action
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

    open static let WordPressOrgXMLRPCApiErrorKeyData = "WordPressOrgXMLRPCApiErrorKeyData"
    open static let WordPressOrgXMLRPCApiErrorKeyDataString = "WordPressOrgXMLRPCApiErrorKeyDataString"

    fileprivate func convertError(_ error: NSError, data: Data?) -> NSError {
        if let data = data {
            var userInfo: [AnyHashable: Any] = error.userInfo
            userInfo[type(of: self).WordPressOrgXMLRPCApiErrorKeyData] = data
            userInfo[type(of: self).WordPressOrgXMLRPCApiErrorKeyDataString] = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
            return NSError(domain: error.domain, code: error.code, userInfo: userInfo)
        }
        return error
    }
}

extension WordPressOrgXMLRPCApi: URLSessionTaskDelegate, URLSessionDelegate {

    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let action = ongoingUploads[task] else {
            return
        }
        action.progress.completedUnitCount = totalBytesSent
        if (totalBytesSent == totalBytesExpectedToSend) {
            ongoingUploads.removeValue(forKey: task)
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let action = ongoingUploads[task] else {
            return
        }
        if let error = error {
            action.failure?(error as NSError, task.response as? HTTPURLResponse)
        } else {
            action.success?(NSObject(), task.response  as? HTTPURLResponse)
        }

        ongoingUploads.removeValue(forKey: task)
    }
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
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

    public func urlSession(_ session: URLSession,
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
