import Foundation
import OHHTTPStubs



// MARK: - Private helpers
//
public extension OHHTTPStubs
{
    static func stubRequest(forEndpoint endpoint: String, withFileAtPath path: String) {
        stub({ request in
            return request.URL?.absoluteString?.rangeOfString(endpoint) != nil
        }) { _ in
            return fixture(path, headers: ["Content-Type": "application/json"])
        }
    }
}
