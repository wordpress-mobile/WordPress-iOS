import Foundation
import OHHTTPStubs



// MARK: - Private helpers
//
public extension OHHTTPStubs {
    static func stubRequest(forEndpoint endpoint: String, withFileAtPath path: String) {
        stub(condition: { request in
            return request.url?.absoluteString.range(of: endpoint) != nil
        }) { _ in
            return fixture(filePath: path, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }
    }

    static func stubRequest(for endpoint: String, jsonObject: [AnyHashable: Any]) {
        stub(condition: { request in
            return request.url?.absoluteString.range(of: endpoint) != nil
        }) { _ in
            return OHHTTPStubsResponse(jsonObject: jsonObject, statusCode: 200, headers: nil)
        }
    }

    static func stubRequest(for endpoint: String, stubResponse: OHHTTPStubsResponse) {
        stub(condition: { request in
            return request.url?.absoluteString.range(of: endpoint) != nil
        }) { _ in
            return stubResponse
        }
    }
}
