import XCTest
import WordPressKit

class TimeZoneServiceRemoteTests: RemoteTestCase, RESTTestable {
    func testOffsetTimeZone() {
        let utc = OffsetTimeZone(offset: 0)

        XCTAssertEqual(utc.label, "UTC")
        XCTAssertEqual(utc.value, "UTC")
        XCTAssertEqual(utc.gmtOffset, 0)
        XCTAssertEqual(utc.timezoneString, "UTC")

        let utcPlusFour = OffsetTimeZone(offset: 4)
        XCTAssertEqual(utcPlusFour.label, "UTC+4")
        XCTAssertEqual(utcPlusFour.value, "UTC+4")
        XCTAssertEqual(utcPlusFour.gmtOffset, 4)
        XCTAssertEqual(utcPlusFour.timezoneString, "UTC+4")

        let utcPlusFourThirty = OffsetTimeZone(offset: 4.5)
        XCTAssertEqual(utcPlusFourThirty.label, "UTC+4:30")
        XCTAssertEqual(utcPlusFourThirty.value, "UTC+4.5")
        XCTAssertEqual(utcPlusFourThirty.gmtOffset, 4.5)
        XCTAssertEqual(utcPlusFourThirty.timezoneString, "UTC+4.5")

        let utcMinusTwo = OffsetTimeZone(offset: -2)
        XCTAssertEqual(utcMinusTwo.label, "UTC-2")
        XCTAssertEqual(utcMinusTwo.value, "UTC-2")
        XCTAssertEqual(utcMinusTwo.gmtOffset, -2)
        XCTAssertEqual(utcMinusTwo.timezoneString, "UTC-2")

        let utcMinusTwoThirty = OffsetTimeZone(offset: -2.5)
        XCTAssertEqual(utcMinusTwoThirty.label, "UTC-2:30")
        XCTAssertEqual(utcMinusTwoThirty.value, "UTC-2.5")
        XCTAssertEqual(utcMinusTwoThirty.gmtOffset, -2.5)
        XCTAssertEqual(utcMinusTwoThirty.timezoneString, "UTC-2.5")
    }

    func testGetTimeZones() {
        stubRemoteResponse("timezones", filename: "timezones.json", contentType: .ApplicationJSON)

        let expect = expectation(description: "Get time zones")
        let remote = TimeZoneServiceRemote(wordPressComRestApi: getRestApi())!
        remote.getTimezones(success: { (results) in
            XCTAssertEqual(results.count, 11)
            XCTAssertEqual(results[0].name, "Africa")
            XCTAssertEqual(results[10].name, "Manual Offsets")
            expect.fulfill()
        }, failure: { error in
            XCTFail("This callback shouldn't get called")
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
