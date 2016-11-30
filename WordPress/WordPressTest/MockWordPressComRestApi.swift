import Foundation

class MockWordPressComRestApi : WordPressComRestApi {
    var getMethodCalled = false
    var postMethodCalled = false
    var URLStringPassedIn:String?
    var parametersPassedIn:AnyObject?
    var successBlockPassedIn:((AnyObject, HTTPURLResponse?) -> Void)?
    var failureBlockPassedIn:((NSError, HTTPURLResponse?) -> Void)?

    override func GET(_ URLString: String?, parameters: [String:AnyObject]?, success: @escaping ((AnyObject, HTTPURLResponse?) -> Void), failure: @escaping ((NSError, HTTPURLResponse?) -> Void)) -> Progress? {
        getMethodCalled = true
        URLStringPassedIn = URLString
        parametersPassedIn = parameters as AnyObject?
        successBlockPassedIn = success
        failureBlockPassedIn = failure

        return Progress()
    }

    override func POST(_ URLString: String?, parameters: [String:AnyObject]?, success: @escaping ((AnyObject, HTTPURLResponse?) -> Void), failure: @escaping ((NSError, HTTPURLResponse?) -> Void)) -> Progress? {
        postMethodCalled = true
        URLStringPassedIn = URLString
        parametersPassedIn = parameters as AnyObject?
        successBlockPassedIn = success
        failureBlockPassedIn = failure

        return Progress()
    }

    override func multipartPOST(URLString: String,
                                parameters: [String : AnyObject]?,
                                fileParts: [FilePart],
                                success: SuccessResponseBlock,
                                failure: FailureReponseBlock) -> NSProgress? {

        postMethodCalled = true
        URLStringPassedIn = URLString
        parametersPassedIn = parameters
        successBlockPassedIn = success
        failureBlockPassedIn = failure
        return NSProgress()
    }

    func methodCalled() -> String {

        var method = "Unknown"
        if getMethodCalled {
            method = "GET"
        } else if postMethodCalled {
            method = "POST"
        }

        return method
    }
}
