import Foundation

class MockWordPressComApi : WordPressComApi {
    var postMethodCalled = false
    var URLStringPassedIn:String?
    var parametersPassedIn:AnyObject?
    
    var shouldCallSuccessCallback = false
    func callSuccessCallback() {
        shouldCallSuccessCallback = true
    }
    
    var shouldCallFailureCallback = false
    func callFailureCallback() {
        shouldCallFailureCallback = true
    }
    
    override func POST(URLString: String!, parameters: AnyObject!, success: ((AFHTTPRequestOperation!, AnyObject!) -> Void)!, failure: ((AFHTTPRequestOperation!, NSError!) -> Void)!) -> AFHTTPRequestOperation! {
        postMethodCalled = true
        URLStringPassedIn = URLString
        parametersPassedIn = parameters
        
        if (shouldCallSuccessCallback) {
            success?(AFHTTPRequestOperation(), [])
        } else if (shouldCallFailureCallback) {
            failure?(AFHTTPRequestOperation(), NSError())
        }
        
        return AFHTTPRequestOperation()
    }
}
