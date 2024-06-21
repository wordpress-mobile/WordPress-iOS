import Foundation
@testable import WordPressKit

class MockWordPressComRestApi: WordPressComRestApi {
    @objc var getMethodCalled = false
    @objc var postMethodCalled = false
    @objc var URLStringPassedIn: String?
    @objc var parametersPassedIn: AnyObject?
    @objc var successBlockPassedIn: ((AnyObject, HTTPURLResponse?) -> Void)?
    @objc var failureBlockPassedIn: ((NSError, HTTPURLResponse?) -> Void)?

    var performMethodCall: HTTPRequestBuilder.Method?

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

    override func perform<T: Decodable>(
        _ method: HTTPRequestBuilder.Method,
        URLString: String,
        parameters: [String: AnyObject]? = nil,
        fulfilling progress: Progress? = nil,
        jsonDecoder: JSONDecoder? = nil,
        type: T.Type = T.self
    ) async -> APIResult<T> {
        performMethodCall = method
        URLStringPassedIn = URLString
        return .failure(.connection(.init(.cancelled)))
    }

    @objc func methodCalled() -> String {

        var method = "Unknown"
        if getMethodCalled {
            method = "GET"
        } else if postMethodCalled {
            method = "POST"
        }

        return method
    }
}
