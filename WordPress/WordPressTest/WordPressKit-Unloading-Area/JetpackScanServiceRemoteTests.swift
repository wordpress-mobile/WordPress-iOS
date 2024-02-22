import XCTest

@testable import WordPressKit

class JetpackScanServiceRemoteTests: RemoteTestCase, RESTTestable {
    let mockRemoteApi = MockWordPressComRestApi()
    var service: JetpackScanServiceRemote!

    override func setUp() {
        super.setUp()

        service = JetpackScanServiceRemote(wordPressComRestApi: getRestApi())
    }

    /// Scan service is not available
    func testUnavailableScan() {
        let expect = expectation(description: "Get the scan availability successfully")
        stubRemoteResponse("wpcom/v2/sites/1/scan/", filename: "jetpack-scan-unavailable.json", contentType: .ApplicationJSON)

        service.getScanAvailableForSite(1, success: { isAvailable in
            XCTAssertTrue(isAvailable == false)
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    /// Scan status is being returned correctly
    func testIdleScan() {
        let expect = expectation(description: "Gets scan status")
        stubRemoteResponse("wpcom/v2/sites/1/scan/", filename: "jetpack-scan-idle-success-no-threats.json", contentType: .ApplicationJSON)

        service.getScanForSite(1, success: { scan in
            XCTAssertTrue(scan.state == .idle)
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    /// Failure block is fired correctly
    func testFailure() {
        let expect = expectation(description: "Failure block is fired")
        stubRemoteResponse("wpcom/v2/sites/1/scan/", filename: "jetpack-scan-idle-success-no-threats.json", contentType: .ApplicationJSON, status: 503)

        service.getScanForSite(1, success: { _ in }, failure: { error in
            XCTAssertNotNil(error)
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    /// Scan state and current object are being set
    func testScanInProgress() {
        let expect = expectation(description: "Get the current scan object successfully")
        stubRemoteResponse("wpcom/v2/sites/1/scan/", filename: "jetpack-scan-in-progress.json", contentType: .ApplicationJSON)

        service.getCurrentScanStatusForSite(1, success: { currentScan in
            XCTAssertNotNil(currentScan)
            XCTAssertNotNil(currentScan?.startDate)
            XCTAssertTrue(currentScan?.progress == 78)
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    /// Most recent scan object is being set correctly
    func testMostRecentScan() {
        let expect = expectation(description: "Get the most recent object successfully")
        stubRemoteResponse("wpcom/v2/sites/1/scan/", filename: "jetpack-scan-idle-success-no-threats.json", contentType: .ApplicationJSON)

        service.getScanForSite(1, success: { scan in
            XCTAssertNotNil(scan.mostRecent)
            XCTAssertTrue(scan.mostRecent?.duration == 24)
            XCTAssertTrue(scan.mostRecent?.progress == 100)
            XCTAssertTrue(scan.mostRecent?.didFail == false)
            XCTAssertNotNil(scan.mostRecent?.startDate)
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    /// Most recent scan object is being set correctly
    func testReturnCredentials() {
        let expect = expectation(description: "Get the credentials object successfully")
        stubRemoteResponse("wpcom/v2/sites/1/scan/", filename: "jetpack-scan-idle-success-no-threats.json", contentType: .ApplicationJSON)

        service.getScanForSite(1, success: { scan in
            XCTAssertNotNil(scan.credentials)

            let credentials = scan.credentials?.first

            XCTAssertTrue(credentials?.host == "example.com")
            XCTAssertTrue(credentials?.port == 21)
            XCTAssertTrue(credentials?.user == "example")
            XCTAssertTrue(credentials?.path == "/")
            XCTAssertTrue(credentials?.type == "ftp")
            XCTAssertTrue(credentials?.role == "main")
            XCTAssertTrue(credentials?.stillValid == true)

            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Start Scan

    /// The scan starts successfully
    func testStartScan() {
        let expect = expectation(description: "The scan starts successfully")
        stubRemoteResponse("wpcom/v2/sites/1/scan/enqueue", filename: "jetpack-scan-enqueue-success.json", contentType: .ApplicationJSON)

        service.startScanForSite(1, success: { success in
            XCTAssertTrue(success)
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testStartScanFailed() {
        let expect = expectation(description: "The scan does not startsuccessfully")
        stubRemoteResponse("wpcom/v2/sites/1/scan/enqueue", filename: "jetpack-scan-enqueue-failure.json", contentType: .ApplicationJSON)

        service.startScanForSite(1, success: { success in
            XCTAssertFalse(success)
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Threat Tests

    /// Threats are returned
    func testReturnThreats() {
        let expect = expectation(description: "Threats are returned successfully")
        stubRemoteResponse("wpcom/v2/sites/1/scan/", filename: "jetpack-scan-idle-success-threats.json", contentType: .ApplicationJSON)

        service.getThreatsForSite(1, success: { threats in
            XCTAssertNotNil(threats)
            XCTAssertTrue(threats?.count == 5)
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    /// Threat types are returned correctly
    func testReturnCorrectThreatTypes() {
        let expect = expectation(description: "Threat types are returned correctly")
        stubRemoteResponse("wpcom/v2/sites/1/scan/", filename: "jetpack-scan-idle-success-threats.json", contentType: .ApplicationJSON)

        service.getThreatsForSite(1, success: { threats in
            let types = threats?.map { $0.type }
            let expectedTypes: [JetpackScanThreat.ThreatType] = [.file, .core, .database, .plugin, .theme]
            XCTAssertTrue(types == expectedTypes)
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    /// Threat extension object is set correctly
    func testReturnThreatExtension() {
        let expect = expectation(description: "Threat extension object is set correctly")
        stubRemoteResponse("wpcom/v2/sites/1/scan/", filename: "jetpack-scan-idle-success-threats.json", contentType: .ApplicationJSON)

        service.getThreatsForSite(1, success: { threats in
            let threat = threats?[3]
            XCTAssertNotNil(threat)
            XCTAssertNotNil(threat?.extension)
            XCTAssertTrue(threat?.extension?.type == .plugin)
            XCTAssertTrue(threat?.extension?.slug == "calendar")
            XCTAssertTrue(threat?.extension?.name == "Calendar")
            XCTAssertTrue(threat?.extension?.version == "1.3.1")
            XCTAssertTrue(threat?.extension?.isPremium == false)

            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    /// Fixable threat object is set correctly
    func testFixableThreat() {
        let expect = expectation(description: "Threat is fixable")
        stubRemoteResponse("wpcom/v2/sites/1/scan/", filename: "jetpack-scan-idle-success-threats.json", contentType: .ApplicationJSON)

        service.getThreatsForSite(1, success: { threats in
            let threat = threats?[3]
            XCTAssertNotNil(threat)
            XCTAssertNotNil(threat?.fixable)

            XCTAssertTrue(threat?.fixable?.type == .update)
            XCTAssertTrue(threat?.fixable?.target == "1.3.14")

            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    /// Fixable property is set correctly for unfixable threats
    func testNotFixableThreat() {
        let expect = expectation(description: "Threat is not fixable")
        stubRemoteResponse("wpcom/v2/sites/1/scan/", filename: "jetpack-scan-idle-success-threats.json", contentType: .ApplicationJSON)

        service.getThreatsForSite(1, success: { threats in
            let threat = threats?[2]
            XCTAssertNotNil(threat)
            XCTAssertNil(threat?.fixable)
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    /// Make sure the threat context object is set correctly
    func testThreatContext() {
        let expect = expectation(description: "Get the threat context object successfully")
        stubRemoteResponse("wpcom/v2/sites/1/scan/", filename: "jetpack-scan-idle-success-threats.json", contentType: .ApplicationJSON)

        service.getThreatsForSite(1, success: { threats in
            let threat = threats?[0]
            XCTAssertNotNil(threat)
            XCTAssertNotNil(threat?.context)

            XCTAssertTrue(threat?.context?.lines.count == 3)
            XCTAssertTrue(threat?.context?.lines[1].highlights == [NSRange(location: 0, length: 68)])
            XCTAssertTrue(threat?.context?.lines[1].lineNumber == 4)

            XCTAssertTrue(threat?.context?.lines[2].contents == "HTML;")
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
