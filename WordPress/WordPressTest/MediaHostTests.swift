import XCTest
@testable import WordPress

class MediaHostTests: XCTestCase {
    func testInitializationWithPublicSite() {
        let host = MediaHost(isAccessibleThroughWPCom: false, isPrivate: false, isAtomic: false) { error in
            XCTFail("This should not be called.")
        }

        XCTAssertEqual(host, .publicSite)
    }

    func testInitializationWithPublicWPComSite() {
        let host = MediaHost(isAccessibleThroughWPCom: true, isPrivate: false, isAtomic: false) { error in
            XCTFail("This should not be called.")
        }

        XCTAssertEqual(host, .publicWPComSite)
    }

    func testInitializationWithPrivateSelfHostedSite() {
        let host = MediaHost(isAccessibleThroughWPCom: false, isPrivate: true, isAtomic: false) { error in
            XCTFail("This should not be called.")
        }

        XCTAssertEqual(host, .privateSelfHostedSite)
    }

    func testInitializationWithPrivateWPComSite() {
        let host = MediaHost(isAccessibleThroughWPCom: true, isPrivate: true, isAtomic: false) { error in
            XCTFail("This should not be called.")
        }

        XCTAssertEqual(host, .privateWPComSite)
    }

    func testInitializationWithPrivateAtomicWPComSite() {
        let siteID = 16557

        let host = MediaHost(isAccessibleThroughWPCom: true, isPrivate: true, isAtomic: true, siteID: siteID) { error in
            XCTFail("This should not be called.")
        }

        XCTAssertEqual(host, .privateAtomicWPComSite(siteID: siteID))
    }

    func testInitializationWithPrivateAtomicWPComSiteWithoutSiteIDFails() {
        let expectation = self.expectation(description: "The error closure will be called")

        let _ = MediaHost(isAccessibleThroughWPCom: true, isPrivate: true, isAtomic: true) { error in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 0.05)
    }
}
