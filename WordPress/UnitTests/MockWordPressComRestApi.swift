import Foundation
@testable import WordPressKit

class MockWordPressComRestApi: WordPressComRestApi {
    var getMethodCalled = false
    var postMethodCalled = false
    var URLStringPassedIn: String?
    var parametersPassedIn: AnyObject?
    var successBlockPassedIn: ((AnyObject, HTTPURLResponse?) -> Void)?
    var failureBlockPassedIn: ((NSError, HTTPURLResponse?) -> Void)?

    override func GET(_ URLString: String?, parameters: [String: AnyObject]?, success: @escaping ((AnyObject, HTTPURLResponse?) -> Void), failure: @escaping ((NSError, HTTPURLResponse?) -> Void)) -> Progress? {
        getMethodCalled = true
        URLStringPassedIn = URLString
        parametersPassedIn = parameters as AnyObject?
        successBlockPassedIn = success
        failureBlockPassedIn = failure

        return Progress()
    }

    override func POST(_ URLString: String?, parameters: [String: AnyObject]?, success: @escaping ((AnyObject, HTTPURLResponse?) -> Void), failure: @escaping ((NSError, HTTPURLResponse?) -> Void)) -> Progress? {
        postMethodCalled = true
        URLStringPassedIn = URLString
        parametersPassedIn = parameters as AnyObject?
        successBlockPassedIn = success
        failureBlockPassedIn = failure

        return Progress()
    }

    override func multipartPOST(_ URLString: String,
                                parameters: [String: AnyObject]?,
                                fileParts: [FilePart],
                                requestEnqueued: RequestEnqueuedBlock? = nil,
                                success: @escaping SuccessResponseBlock,
                                failure: @escaping FailureReponseBlock) -> Progress? {

        postMethodCalled = true
        URLStringPassedIn = URLString
        parametersPassedIn = parameters as AnyObject?
        successBlockPassedIn = success
        failureBlockPassedIn = failure
        return Progress()
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

class MockWordPressOrgRestApi: WordPressOrgRestApi {
    var getMethodCalled = false
    var URLStringPassedIn: String?
    var parametersPassedIn: AnyObject?
    var completionPassedIn: WordPressOrgRestApi.Completion?

    init() {
        super.init(apiBase: URL(string: "https://example.com")!)
    }

    override func GET(_ path: String, parameters: [String: AnyObject]?, completion: @escaping WordPressOrgRestApi.Completion) -> Progress? {
        getMethodCalled = true
        URLStringPassedIn = path
        parametersPassedIn = parameters as AnyObject?
        completionPassedIn = completion

        return Progress()
    }

    @objc func methodCalled() -> String {

        var method = "Unknown"
        if getMethodCalled {
            method = "GET"
        }

        return method
    }
}
