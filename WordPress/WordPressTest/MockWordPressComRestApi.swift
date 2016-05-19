import Foundation

class MockWordPressComRestApi : WordPressComRestApi {
    var getMethodCalled = false
    var postMethodCalled = false
    var URLStringPassedIn:String?
    var parametersPassedIn:AnyObject?
    var successBlockPassedIn:((AnyObject, NSHTTPURLResponse?) -> Void)?
    var failureBlockPassedIn:((NSError, NSHTTPURLResponse?) -> Void)?

    override func GET(URLString: String?, parameters: [String:AnyObject]?, success: ((AnyObject, NSHTTPURLResponse?) -> Void), failure: ((NSError, NSHTTPURLResponse?) -> Void)) -> NSProgress? {
        getMethodCalled = true
        URLStringPassedIn = URLString
        parametersPassedIn = parameters
        successBlockPassedIn = success
        failureBlockPassedIn = failure

        return NSProgress()
    }

    override func POST(URLString: String?, parameters: [String:AnyObject]?, success: ((AnyObject, NSHTTPURLResponse?) -> Void), failure: ((NSError, NSHTTPURLResponse?) -> Void)) -> NSProgress? {
        postMethodCalled = true
        URLStringPassedIn = URLString
        parametersPassedIn = parameters
        successBlockPassedIn = success
        failureBlockPassedIn = failure

        return NSProgress()
    }
}
