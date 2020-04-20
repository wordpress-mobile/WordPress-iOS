import XCTest
@testable import WordPress

class MediaHostTests: XCTestCase {
    func testInitializationWithPublicSite() {
        let host = MediaHost(
            isAccessibleThroughWPCom: false,
            isPrivate: false,
            isAtomic: false,
            siteID: nil,
            username: nil,
            authToken: nil) { error in
                XCTFail("This should not be called.")
        }

        XCTAssertEqual(host, .publicSite)
    }

    func testInitializationWithPublicWPComSite() {
        let host = MediaHost(
            isAccessibleThroughWPCom: true,
            isPrivate: false,
            isAtomic: false,
            siteID: nil,
            username: nil,
            authToken: nil) { error in
                XCTFail("This should not be called.")
        }

        XCTAssertEqual(host, .publicWPComSite)
    }

    func testInitializationWithPrivateSelfHostedSite() {
        let host = MediaHost(
            isAccessibleThroughWPCom: false,
            isPrivate: true,
            isAtomic: false,
            siteID: nil,
            username: nil,
            authToken: nil) { error in
                XCTFail("This should not be called.")
        }

        XCTAssertEqual(host, .privateSelfHostedSite)
    }

    func testInitializationWithPrivateWPComSite() {
        let authToken = "letMeIn!"

        let host = MediaHost(
            isAccessibleThroughWPCom: true,
            isPrivate: true,
            isAtomic: false,
            siteID: nil,
            username: nil,
            authToken: authToken) { error in

            XCTFail("This should not be called.")
        }

        XCTAssertEqual(host, .privateWPComSite(authToken: authToken))
    }

    func testInitializationWithPrivateAtomicWPComSite() {
        let siteID = 16557
        let username = "demouser"
        let authToken = "letMeIn!"

        let host = MediaHost(
            isAccessibleThroughWPCom: true,
            isPrivate: true,
            isAtomic: true,
            siteID: siteID,
            username: username,
            authToken: authToken) { error in

            XCTFail("This should not be called.")
        }

        XCTAssertEqual(host, .privateAtomicWPComSite(siteID: siteID, username: username, authToken: authToken))
    }

    func testInitializationWithPrivateAtomicWPComSiteWithoutAuthTokenFails() {
        let siteID = 16557
        let username = "demouser"
        let expectation = self.expectation(description: "We're expecting an error to be triggered.")

        let _ = MediaHost(
            isAccessibleThroughWPCom: true,
            isPrivate: true,
            isAtomic: true,
            siteID: siteID,
            username: username,
            authToken: nil) { error in
                if error == .wpComPrivateSiteWithoutAuthToken {
                    expectation.fulfill()
                }
        }

        waitForExpectations(timeout: 0.05)
    }

    func testInitializationWithPrivateAtomicWPComSiteWithoutUsernameFails() {
        let siteID = 16557
        let authToken = "letMeIn!"
        let expectation = self.expectation(description: "We're expecting an error to be triggered.")

        let _ = MediaHost(
            isAccessibleThroughWPCom: true,
            isPrivate: true,
            isAtomic: true,
            siteID: siteID,
            username: nil,
            authToken: authToken) { error in
                if error == .wpComPrivateSiteWithoutUsername {
                    expectation.fulfill()
                }
        }

        waitForExpectations(timeout: 0.05)
    }

    func testInitializationWithPrivateAtomicWPComSiteWithoutSiteIDFails() {
        let expectation = self.expectation(description: "The error closure will be called")

        let _ = MediaHost(
            isAccessibleThroughWPCom: true,
            isPrivate: true,
            isAtomic: true,
            siteID: nil,
            username: nil,
            authToken: nil) { error in
                expectation.fulfill()
        }

        waitForExpectations(timeout: 0.05)
    }
}
