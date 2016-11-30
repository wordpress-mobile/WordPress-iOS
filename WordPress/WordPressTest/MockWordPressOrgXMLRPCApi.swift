import Foundation

@objc class MockWordPressOrgXMLRPCApi: NSObject, WordPressOrgXMLRPC {

    var methodPassedIn: String? = nil
    var parametersPassedIn: [AnyObject]? = nil
    var successBlockPassedIn: ((AnyObject, NSHTTPURLResponse?) -> Void)? = nil
    var failureBlockPassedIn: ((NSError, NSHTTPURLResponse?) -> Void)? = nil

    required init(endpoint: NSURL = NSURL(fileURLWithPath: ""), userAgent: String? = nil) {}

    func invalidateAndCancelTasks() {}
    func checkCredentials(username: String,
                          password: String,
                          success: (AnyObject, NSHTTPURLResponse?) -> Void,
                          failure: (NSError, NSHTTPURLResponse?) -> Void) {}

    func callMethod(method: String,
                    parameters: [AnyObject]?,
                    success: (AnyObject, NSHTTPURLResponse?) -> Void,
                    failure: (NSError, NSHTTPURLResponse?) -> Void) -> NSProgress? {

        return capture(method, parameters: parameters, success: success, failure: failure)
    }

    func streamCallMethod(method: String,
                          parameters: [AnyObject]?,
                          success: (AnyObject, NSHTTPURLResponse?) -> Void,
                          failure: (NSError, NSHTTPURLResponse?) -> Void) -> NSProgress? {

        return capture(method, parameters: parameters, success: success, failure: failure)
    }

    private func capture(method: String,
                         parameters: [AnyObject]?,
                         success: (AnyObject, NSHTTPURLResponse?) -> Void,
                         failure: (NSError, NSHTTPURLResponse?) -> Void) -> NSProgress {
        methodPassedIn = method
        parametersPassedIn = parameters
        successBlockPassedIn = success
        failureBlockPassedIn = failure
        return NSProgress()
    }
}
