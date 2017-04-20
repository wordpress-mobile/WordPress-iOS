import Foundation
import XCTest
import OHHTTPStubs
@testable import WordPress

class RemoteTestCase: XCTestCase {

    // MARK: - Constants

    let contentTypeJson     = "application/json"
    let contentTypeJS       = "text/javascript;charset=utf-8"
    let contentTypeHTML     = "application/html"
    let timeout             = TimeInterval(1000)

    // MARK: - Properties

    var restApi: WordPressComRestApi!
    var testContextManager: TestContextManager!

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        testContextManager = TestContextManager()
        restApi = WordPressComRestApi(oAuthToken: nil, userAgent: nil)
        stubAllNetworkRequestsWithNotConnectedError()
    }

    override func tearDown() {
        super.tearDown()

        ContextManager.overrideSharedInstance(nil)
        testContextManager.mainContext.reset()
        testContextManager = nil
        restApi = nil
        OHHTTPStubs.removeAllStubs()
    }

    // MARK: - Helpers

    func stubRemoteResponse(_ endpoint: String, filename: String, contentType: String, status: Int32 = 200) {
        stub(condition: { request in
            return request.url?.absoluteString.range(of: endpoint) != nil
        }) { _ in
            let stubPath = OHPathForFile(filename, type(of: self))
            return fixture(filePath: stubPath!, status: status, headers: ["Content-Type" as NSObject: contentType as AnyObject])
        }
    }

    func stubRemoteResponse(_ endpoint: String, data: Data, contentType: String?, status: Int32 = 200) {
        stub(condition: { request in
            return request.url?.absoluteString.range(of: endpoint) != nil
        }) { _ in
            var headers: Dictionary<NSObject, AnyObject>?
            if let contentType = contentType {
                headers = ["Content-Type" as NSObject: contentType as AnyObject]
            }
            return OHHTTPStubsResponse(data: data, statusCode: status, headers: headers)
        }
    }

    func stubAllNetworkRequestsWithNotConnectedError() {
        stub(condition: { request in
            return true
        }) { response in
            XCTFail("Unexpected network request was made to: \(response.url!.absoluteString)")
            let notConnectedError = NSError(domain:NSURLErrorDomain, code:Int(CFNetworkErrors.cfurlErrorNotConnectedToInternet.rawValue), userInfo:nil)
            return OHHTTPStubsResponse(error:notConnectedError)
        }
    }
}
