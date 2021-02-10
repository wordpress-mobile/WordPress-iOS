import Foundation
import OHHTTPStubs



// MARK: - Private helpers
//
public extension HTTPStubs {
    static func stubRequest(forEndpoint endpoint: String, withFileAtPath path: String) {
        stub(condition: { request in
            return request.url?.absoluteString.range(of: endpoint) != nil
        }) { _ in
            return fixture(filePath: path, headers: ["Content-Type" as NSObject: "application/json" as AnyObject])
        }
    }
}
