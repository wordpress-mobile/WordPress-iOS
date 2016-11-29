import Foundation

@objc protocol WordPressOrgXMLRPC {

    /**
     Cancels all ongoing and makes the session so the object will not fullfil any more request
     */
    func invalidateAndCancelTasks()

    //MARK: - Network requests
    /**
     Check if username and password are valid credentials for the xmlrpc endpoint.

     - Parameters:
        - username: username to check
        - password: password to check
        - success:  callback block to be invoked if credentials are valid, the object returned in the block is the options dictionary for the site.
        - failure:  callback block to be invoked is credentials fail
     */
    func checkCredentials(username: String,
                          password: String,
                          success: SuccessResponseBlock,
                          failure: FailureReponseBlock)

    /**
     Executes a XMLRPC call for the method specificied with the arguments provided.

     - Parameters:
        - method:  the xmlrpc method to be invoked
        - parameters: the parameters to be encoded on the request
        - success:    callback to be called on successful request
        - failure:    callback to be called on failed request

     - Returns:  a NSProgress object that can be used to track the progress of the request and to cancel the request. If the method
     returns nil it's because something happened on the request serialization and the network request was not started, but the failure callback
     will be invoked with the error specificing the serialization issues.
     */
    func callMethod(method: String,
                    parameters: [AnyObject]?,
                    success: SuccessResponseBlock,
                    failure: FailureReponseBlock) -> NSProgress?

    /**
     Executes a XMLRPC call for the method specificied with the arguments provided, by streaming the request from a file.
     This allows to do requests that can use a lot of memory, like media uploads.

     - Parameters:
        - method:  the xmlrpc method to be invoked
        - parameters: the parameters to be encoded on the request
        - success:    callback to be called on successful request
        - failure:    callback to be called on failed request

     - Returns:  a NSProgress object that can be used to track the progress of the request and to cancel the request. If the method
     returns nil it's because something happened on the request serialization and the network request was not started, but the failure callback
     will be invoked with the error specificing the serialization issues.
     */

    func streamCallMethod(method: String,
                          parameters: [AnyObject]?,
                          success: SuccessResponseBlock,
                          failure: FailureReponseBlock) -> NSProgress?
}

extension WordPressOrgXMLRPC {

    typealias SuccessResponseBlock = (AnyObject, NSHTTPURLResponse?) -> ()
    typealias FailureReponseBlock = (error: NSError, httpResponse: NSHTTPURLResponse?) -> ()
}
