import Foundation
@testable import WordPress

class MockWordPressOrgXMLRPCApi: WordPressOrgXMLRPC {

    var methodPassedIn: String? = nil
    var parametersPassedIn: AnyObject? = nil
    var successBlockPassedIn: WordPressOrgXMLRPCApi.SuccessResponseBlock? = nil
    var failureBlockPassedIn: WordPressOrgXMLRPCApi.FailureReponseBlock? = nil

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
