import XCTest
import WordPressKit

class TimeZoneServiceRemoteTests: RemoteTestCase, RESTTestable {
    func testGetTimeZones() {
        stubRemoteResponse("timezones", filename: "timezones.json", contentType: .ApplicationJSON)

        let expect = expectation(description: "Get time zones")
        let remote = TimeZoneServiceRemote(wordPressComRestApi: getRestApi())!
        remote.getTimezones(success: { (results) in
            XCTAssertEqual(results.count, 10)
            XCTAssertEqual(results[0].name, "Africa")
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
