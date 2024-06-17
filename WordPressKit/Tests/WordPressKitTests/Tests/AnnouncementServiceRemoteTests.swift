import Foundation
import XCTest
import OHHTTPStubs

@testable import WordPressKit

class AnnouncementServiceRemoteTests: XCTestCase {

    func testNoAnnouncement() {
        stub(condition: isPath("/wpcom/v2/mobile/feature-announcements") && containsQueryParams(["app_id": "test-app"])) { _ in
            HTTPStubsResponse(jsonObject: ["announcements": [String]()], statusCode: 200, headers: nil)
        }

        let remote = AnnouncementServiceRemote(wordPressComRestApi: .init(oAuthToken: "fake"))
        var result: Result<[Announcement], Error>? = nil
        let completed = expectation(description: "API call completed")
        remote.getAnnouncements(appId: "test-app", appVersion: "2.0", locale: "en") {
            result = $0
            completed.fulfill()
        }
        wait(for: [completed], timeout: 0.3)

        try XCTAssertEqual(XCTUnwrap(result).get().count, 0)
    }

}
