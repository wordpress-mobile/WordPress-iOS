import Foundation

@objc class MockWordPressOrgXMLRPCApi: NSObject, WordPressOrgXMLRPC {

    var methodPassedIn: String? = nil
    var parametersPassedIn: [AnyObject]? = nil
    var successBlockPassedIn: WordPressOrgXMLRPCApi.SuccessResponseBlock? = nil
    var failureBlockPassedIn: WordPressOrgXMLRPCApi.FailureReponseBlock? = nil

    required init(endpoint: NSURL = NSURL(fileURLWithPath: ""), userAgent: String? = nil) {}

    func invalidateAndCancelTasks() {}
    func checkCredentials(username: String,
                          password: String,
                          success: WordPressOrgXMLRPCApi.SuccessResponseBlock,
                          failure: WordPressOrgXMLRPCApi.FailureReponseBlock) {}

    func callMethod(method: String,
                    parameters: [AnyObject]?,
                    success: WordPressOrgXMLRPCApi.SuccessResponseBlock,
                    failure: WordPressOrgXMLRPCApi.FailureReponseBlock) -> NSProgress? {

        return capture(method, parameters: parameters, success: success, failure: failure)
    }

    func streamCallMethod(method: String,
                          parameters: [AnyObject]?,
                          success: WordPressOrgXMLRPCApi.SuccessResponseBlock,
                          failure: WordPressOrgXMLRPCApi.FailureReponseBlock) -> NSProgress? {

        return capture(method, parameters: parameters, success: success, failure: failure)
    }

    private func capture(method: String,
                         parameters: [AnyObject]?,
                         success: WordPressOrgXMLRPCApi.SuccessResponseBlock,
                         failure: WordPressOrgXMLRPCApi.FailureReponseBlock) -> NSProgress {
        methodPassedIn = method
        parametersPassedIn = parameters
        successBlockPassedIn = success
        failureBlockPassedIn = failure
        return NSProgress()
    }
}
