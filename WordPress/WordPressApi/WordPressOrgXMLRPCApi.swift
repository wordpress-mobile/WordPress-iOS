import Foundation
import wpxmlrpc

public class WordPressOrgXMLRPCApi: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate
{
    public typealias SuccessResponseBlock = (responseObject: AnyObject, httpResponse: NSHTTPURLResponse?) -> ()
    public typealias FailureReponseBlock = (error: NSError, httpResponse: NSHTTPURLResponse?) -> ()

    private let endpoint: NSURL
    private let userAgent: String?

    private lazy var session: NSURLSession = {
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        var additionalHeaders: [String : AnyObject] = ["Accept-Encoding":"gzip, deflate"]
        if let userAgent = self.userAgent {
            additionalHeaders["User-Agent"] = userAgent
        }
        sessionConfiguration.HTTPAdditionalHeaders = additionalHeaders
        let session = NSURLSession(configuration: sessionConfiguration)
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
        var request: NSURLRequest? = nil
        do {
            request = try requestWithMethod(method, parameters: parameters)
        } catch let encodingError as NSError {
            failure(error: encodingError, httpResponse: nil)
            return nil
        }

        // Create task
        let task = session.dataTaskWithRequest(request!) { (data, urlResponse, optionalError) in
            guard let data = data,
                let httpResponse = urlResponse as? NSHTTPURLResponse,
                let contentType = httpResponse.allHeaderFields["Content-Type"] as? String
                where optionalError == nil else {
                    if let error = optionalError {
                        failure(error: error, httpResponse: urlResponse as? NSHTTPURLResponse)
                    } else {
                        failure(error: WordPressOrgXMLRPCApiError.Unknown as NSError, httpResponse: urlResponse as? NSHTTPURLResponse)
                    }
                    return
            }

            if ["application/xml", "text/xml"].filter({ (type) -> Bool in return contentType.hasPrefix(type)}).count == 0 {
                failure(error: WordPressOrgXMLRPCApiError.ResponseSerializationFailed as NSError, httpResponse: httpResponse)
                return
            }

            let decoder = WPXMLRPCDecoder(data: data)

            guard !decoder.isFault(),
                let responseXML = decoder.object() else {
                    let decoderError = decoder.error()
                    failure(error: decoderError,  httpResponse: httpResponse)
                    return
            }

            success(responseObject: responseXML, httpResponse: httpResponse)
        }

        // Progress report
        let progress = NSProgress()
        progress.totalUnitCount = 1
        progress.cancellationHandler = {
            task.cancel()
        }
        task.resume()
        return progress
    }

    private func requestWithMethod(method: String, parameters: [AnyObject]?) throws -> NSURLRequest {
        let mutableRequest = NSMutableURLRequest(URL: endpoint)
        mutableRequest.HTTPMethod = "POST"
        mutableRequest.setValue("text/xml", forHTTPHeaderField:"Content-Type")
        let encoder = WPXMLRPCEncoder(method: method, andParameters: parameters)
        mutableRequest.HTTPBody = try encoder.dataEncoded()

        return mutableRequest
    }
}

extension NSURLSession: NSURLSessionDelegate {

    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
            switch challenge.protectionSpace.authenticationMethod {
            case NSURLAuthenticationMethodServerTrust:
                var result = SecTrustResultType(kSecTrustResultInvalid)
                if let serverTrust = challenge.protectionSpace.serverTrust {
                    let certificateStatus = SecTrustEvaluate(serverTrust, &result)
                    if certificateStatus == 0 && result == SecTrustResultType(kSecTrustResultRecoverableTrustFailure) {
                        //                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        //                        [WPHTTPAuthenticationAlertController presentWithChallenge:challenge];
                        //                        });
                    } else {
                        completionHandler(.PerformDefaultHandling, nil)
                        //[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
                    }
                }
            case NSURLAuthenticationMethodClientCertificate:
                completionHandler(.PerformDefaultHandling, nil)
            case NSURLAuthenticationMethodHTTPBasic:
                completionHandler(.PerformDefaultHandling, nil)
            default:
                completionHandler(.PerformDefaultHandling, nil)
            }
    }
}

extension NSURLSession: NSURLSessionTaskDelegate {
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        completionHandler(.PerformDefaultHandling, nil)
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
