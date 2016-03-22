import Foundation
import AFNetworking

class MockWordPressComApi : WordPressComApi {
    var getMethodCalled = false
    var postMethodCalled = false
    var URLStringPassedIn:String?
    var parametersPassedIn:AnyObject?
    var successBlockPassedIn:((AFHTTPRequestOperation!, AnyObject!) -> Void)?
    var failureBlockPassedIn:((AFHTTPRequestOperation!, NSError!) -> Void)?
    
    override func GET(URLString: String?, parameters: AnyObject!, success: ((AFHTTPRequestOperation!, AnyObject!) -> Void)!, failure: ((AFHTTPRequestOperation!, NSError!) -> Void)!) -> AFHTTPRequestOperation {
        getMethodCalled = true
        URLStringPassedIn = URLString
        parametersPassedIn = parameters
        successBlockPassedIn = success
        failureBlockPassedIn = failure
        
        return AFHTTPRequestOperation()
    }

    override func POST(URLString: String?, parameters: AnyObject!, success: ((AFHTTPRequestOperation!, AnyObject!) -> Void)!, failure: ((AFHTTPRequestOperation!, NSError!) -> Void)!) -> AFHTTPRequestOperation {
        postMethodCalled = true
        URLStringPassedIn = URLString
        parametersPassedIn = parameters
        successBlockPassedIn = success
        failureBlockPassedIn = failure
        
        return AFHTTPRequestOperation()
    }
}
