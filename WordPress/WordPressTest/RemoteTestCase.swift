import Foundation
import XCTest
import OHHTTPStubs
@testable import WordPress

class RemoteTestCase: XCTestCase {

    // MARK: - Constants

    let contentTypeJson     = "application/json"
    let contentTypeHTML     = "application/html"
    let timeout             = TimeInterval(1000)

    // MARK: - Properties

    var restApi: WordPressComRestApi!

    // MARK: - Overriden Methods

    override func setUp() {
        super.setUp()
        restApi = WordPressComRestApi(oAuthToken: nil, userAgent: nil)
    }

    override func tearDown() {
        super.tearDown()
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

}
