import Foundation
import XCTest
import OHHTTPStubs
@testable import WordPress


// MARK: - NotificationSyncServiceTests
//
class NotificationSyncServiceTests: XCTestCase
{
    func testSomething() {
        let endpoint = "notifications/seen"
        let stubPath = OHPathForFile("notifications-last-seen.json", self.dynamicType)!
        OHHTTPStubs.stubRequest(forEndpoint: endpoint, withFileAtPath: stubPath)

        let expectation = expectationWithDescription("Update Last Seen")
    }
}
