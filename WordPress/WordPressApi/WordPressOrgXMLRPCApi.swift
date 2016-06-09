import Foundation
import wpxmlrpc

public class WordPressOrgXMLRPCApi: NSObject
{
    public typealias SuccessResponseBlock = (responseObject: AnyObject, httpResponse: NSHTTPURLResponse?) -> ()
    public typealias FailureReponseBlock = (error: NSError, httpResponse: NSHTTPURLResponse?) -> ()

    private let endpoint: NSURL
    private let userAgent: String?
    private var ongoingProgress = [NSURLSessionTask:NSProgress]()

    private lazy var session: NSURLSession = {
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        var additionalHeaders: [String : AnyObject] = ["Accept-Encoding":"gzip, deflate"]
        if let userAgent = self.userAgent {
            additionalHeaders["User-Agent"] = userAgent
        }
        sessionConfiguration.HTTPAdditionalHeaders = additionalHeaders
        let session = NSURLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: nil)
        return session
    }()

    public init(endpoint: NSURL, userAgent: String? = nil) {
        self.endpoint = endpoint
        self.userAgent = userAgent
        super.init()
    }

    deinit {
        session.finishTasksAndInvalidate()
    }

    /**
     Cancels all ongoing and makes the session so the object will not fullfil any more request
     */
    public func invalidateAndCancelTasks() {
        session.invalidateAndCancel()
    }

    //MARK: - Network requests

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
    public func callMethod(method: String,
                           parameters: [AnyObject]?,
                           success: SuccessResponseBlock,
                           failure: FailureReponseBlock) -> NSProgress?
    {
        //Encode request
        let request: NSURLRequest
        do {
            request = try requestWithMethod(method, parameters: parameters)
        } catch let encodingError as NSError {
            failure(error: encodingError, httpResponse: nil)
            return nil
        }

        // Create task
        let task = session.dataTaskWithRequest(request) { (data, urlResponse, error) in
            do {
                let responseObject = try self.handleResponseWithData(data, urlResponse: urlResponse, error: error)
                success(responseObject: responseObject, httpResponse: urlResponse as? NSHTTPURLResponse)
            } catch let error as NSError {
                failure(error: error, httpResponse: urlResponse as? NSHTTPURLResponse)
                return
            }
        }
        task.resume()
        return createProgresForTask(task)
    }

    /**
     Executes a XMLRPC call for the method specificied with the arguments provided, by streaming the request from a file.
     The locaiton of the file used to stream the request is the one provided in usingFileURLForCache parameter.

     - parameter method:  the xmlrpc method to be invoked
     - parameter parameters: the parameters to be encoded on the request
     - parameter usingFileURLForCache: the file URL where to store the request data to sent to the server
     - parameter success:    callback to be called on successful request
     - parameter failure:    callback to be called on failed request

     - returns:  a NSProgress object that can be used to track the progress of the request and to cancel the request. If the method
     returns nil it's because something happened on the request serialization and the network request was not started, but the failure callback
     will be invoked with the error specificing the serialization issues.
     */
    public func callStreamingMethod(method: String,
                           parameters: [AnyObject]?,
                           usingFileURLForCache fileURL: NSURL,
                           success: SuccessResponseBlock,
                           failure: FailureReponseBlock) -> NSProgress?
    {
        //Encode request
        let request: NSURLRequest
        do {
            request = try streamingRequestWithMethod(method, parameters: parameters, usingFileURLForCache: fileURL)
        } catch let encodingError as NSError {
            failure(error: encodingError, httpResponse: nil)
            return nil
        }

        // Create task
        let task = session.uploadTaskWithRequest(request, fromFile: fileURL, completionHandler: { (data, urlResponse, error) in
            do {
                let responseObject = try self.handleResponseWithData(data, urlResponse: urlResponse, error: error)
                success(responseObject: responseObject, httpResponse: urlResponse as? NSHTTPURLResponse)
            } catch let error as NSError {
                failure(error: error, httpResponse: urlResponse as? NSHTTPURLResponse)
            }
        })
        task.resume()

        return createProgresForTask(task)
    }

    //MARK: - Request Building

    private func requestWithMethod(method: String, parameters: [AnyObject]?) throws -> NSURLRequest {
        let mutableRequest = NSMutableURLRequest(URL: endpoint)
        mutableRequest.HTTPMethod = "POST"
        mutableRequest.setValue("text/xml", forHTTPHeaderField:"Content-Type")
        let encoder = WPXMLRPCEncoder(method: method, andParameters: parameters)
        mutableRequest.HTTPBody = try encoder.dataEncoded()

        return mutableRequest
    }

    private func streamingRequestWithMethod(method: String, parameters: [AnyObject]?, usingFileURLForCache fileURL: NSURL) throws -> NSURLRequest {
        let mutableRequest = NSMutableURLRequest(URL: endpoint)
        mutableRequest.HTTPMethod = "POST"
        mutableRequest.setValue("text/xml", forHTTPHeaderField:"Content-Type")
        let encoder = WPXMLRPCEncoder(method: method, andParameters: parameters)
        try encoder.encodeToFile(fileURL.path)
        var optionalFileSize: AnyObject?
        try fileURL.getResourceValue(&optionalFileSize, forKey: NSURLFileSizeKey)
        if let fileSize = optionalFileSize as? NSNumber {
            mutableRequest.setValue(fileSize.stringValue, forHTTPHeaderField:"Content-Length")
        }

        return mutableRequest
    }

    //MARK: - Progress reporting

    private func createProgresForTask(task: NSURLSessionTask) -> NSProgress {
        // Progress report
        let progress = NSProgress(parent: NSProgress.currentProgress(), userInfo: nil)
        progress.totalUnitCount = 1
        if let contentLengthString = task.originalRequest?.allHTTPHeaderFields?["Content-Length"],
            let contentLength = Int64(contentLengthString) {
            progress.totalUnitCount = contentLength
        }
        progress.cancellationHandler = {
            task.cancel()
        }
        ongoingProgress[task] = progress

        return progress
    }

    //MARK: - Handling of data

    private func handleResponseWithData(data: NSData?, urlResponse:NSURLResponse?, error: NSError?) throws -> AnyObject {
        guard let data = data,
            let httpResponse = urlResponse as? NSHTTPURLResponse,
            let contentType = httpResponse.allHeaderFields["Content-Type"] as? String
            where error == nil else {
                if let unwrappedError = error {
                    throw unwrappedError
                } else {
                    throw WordPressOrgXMLRPCApiError.Unknown
                }
        }

        if ["application/xml", "text/xml"].filter({ (type) -> Bool in return contentType.hasPrefix(type)}).count == 0 {
            throw WordPressOrgXMLRPCApiError.ResponseSerializationFailed
        }

        let decoder = WPXMLRPCDecoder(data: data)

        guard !decoder.isFault(),
            let responseXML = decoder.object() else {
                let decoderError = decoder.error()
                throw decoderError
        }

        return responseXML
    }
}

extension WordPressOrgXMLRPCApi: NSURLSessionTaskDelegate, NSURLSessionDelegate {

    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        guard let progress = ongoingProgress[task] else {
            return
        }        
        progress.completedUnitCount = totalBytesSent
        if (totalBytesSent == totalBytesExpectedToSend) {
            ongoingProgress.removeValueForKey(task)
        }
    }

    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodServerTrust:
            if let credential = NSURLCredentialStorage.sharedCredentialStorage().defaultCredentialForProtectionSpace(challenge.protectionSpace)
                where challenge.previousFailureCount == 0 {
                completionHandler(.UseCredential, credential)
                return
            }
            var result = SecTrustResultType(kSecTrustResultInvalid)
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let certificateStatus = SecTrustEvaluate(serverTrust, &result)
                if certificateStatus == 0 && result == SecTrustResultType(kSecTrustResultRecoverableTrustFailure) {
                    dispatch_async(dispatch_get_main_queue(), { () in
                        HTTPAuthenticationAlertController.presentWithChallenge(challenge, handler: completionHandler)
                    })
                } else {
                    completionHandler(.PerformDefaultHandling, nil)
                }
            }
        default:
            completionHandler(.PerformDefaultHandling, nil)
        }
    }

    public func URLSession(session: NSURLSession,
                           task: NSURLSessionTask,
                           didReceiveChallenge challenge: NSURLAuthenticationChallenge,
                                       completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        switch challenge.protectionSpace.authenticationMethod {
        case NSURLAuthenticationMethodHTTPBasic:
            if let credential = NSURLCredentialStorage.sharedCredentialStorage().defaultCredentialForProtectionSpace(challenge.protectionSpace)
                where challenge.previousFailureCount == 0 {
                completionHandler(.UseCredential, credential)
            } else {
                dispatch_async(dispatch_get_main_queue(), { () in
                    HTTPAuthenticationAlertController.presentWithChallenge(challenge, handler: completionHandler)
                })
            }
        default:
            completionHandler(.PerformDefaultHandling, nil)
        }
    }
}

/**
 Error constants for the WordPress XMLRPC API
 - RequestSerializationFailed:     The serialization of the request failed
 - ResponseSerializationFailed:     The serialization of the response failed
 - Unknown:                        Unknow error happen
 */
@objc public enum WordPressOrgXMLRPCApiError: Int, ErrorType {
    case RequestSerializationFailed
    case ResponseSerializationFailed
    case Unknown
}
