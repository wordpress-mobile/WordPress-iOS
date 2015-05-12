import Foundation

class MockWordPressComApi : WordPressComApi {
    var postMethodCalled = false
    var URLStringPassedIn:String?
    var parametersPassedIn:AnyObject?
    var successBlockPassedIn:((AFHTTPRequestOperation!, AnyObject!) -> Void)?
    var failureBlockPassedIn:((AFHTTPRequestOperation!, NSError!) -> Void)?
    
    override func POST(URLString: String!, parameters: AnyObject!, success: ((AFHTTPRequestOperation!, AnyObject!) -> Void)!, failure: ((AFHTTPRequestOperation!, NSError!) -> Void)!) -> AFHTTPRequestOperation! {
        postMethodCalled = true
        URLStringPassedIn = URLString
        parametersPassedIn = parameters
        successBlockPassedIn = success
        failureBlockPassedIn = failure
        
        return AFHTTPRequestOperation()
    }
}
