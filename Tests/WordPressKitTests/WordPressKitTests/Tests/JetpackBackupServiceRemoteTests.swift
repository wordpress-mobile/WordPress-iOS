import XCTest

@testable import WordPressKit

class JetpackBackupServiceRemoteTests: RemoteTestCase, RESTTestable {

    let mockRemoteApi = MockWordPressComRestApi()
    var service: JetpackBackupServiceRemote!

    // MARK: - Constants

    let siteID = 1
    let downloadID = 283844

    let prepareBackupSuccessMockFilename = "backup-prepare-backup-success.json"
    let getBackupStatusCompleteMockFilename = "backup-get-backup-status-complete-success.json"
    let getBackupStatusInProgressMockFilename = "backup-get-backup-status-in-progress-success.json"
    let getBackupStatusCompleteWithoutDownloadIDMockFilename = "backup-get-backup-status-complete-without-download-id-success.json"

    var backupEndpoint: String { return "sites/\(siteID)/rewind/downloads" }

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        service = JetpackBackupServiceRemote(wordPressComRestApi: getRestApi())
    }

    // MARK: - Prepare Backup

    func testPrepareBackup() {
        let expect = expectation(description: "Create backup snapshot success")
        stubRemoteResponse(backupEndpoint,
                           filename: prepareBackupSuccessMockFilename,
                           contentType: .ApplicationJSON)

        service.prepareBackup(siteID, success: { backup in
            XCTAssertEqual(backup.downloadID, 283844)
            XCTAssertEqual(backup.rewindID, "1608510088.971")
            XCTAssertEqual(backup.progress, 0)
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testPrepareBackupWithParameters() {
        let expect = expectation(description: "Create backup snapshot success")
        stubRemoteResponse(backupEndpoint,
                           filename: prepareBackupSuccessMockFilename,
                           contentType: .ApplicationJSON)

        let restoreTypes = JetpackRestoreTypes(themes: true,
                                               plugins: true,
                                               uploads: true,
                                               sqls: true,
                                               roots: true,
                                               contents: true)

        service.prepareBackup(siteID, types: restoreTypes, success: { backup in
            XCTAssertEqual(backup.downloadID, 283844)
            XCTAssertEqual(backup.rewindID, "1608510088.971")
            XCTAssertEqual(backup.progress, 0)
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testPrepareBackupFailure() {
        let expect = expectation(description: "Create backup snapshot failure")
        stubRemoteResponse(backupEndpoint,
                           filename: prepareBackupSuccessMockFilename,
                           contentType: .ApplicationJSON,
                           status: 503)

        service.prepareBackup(siteID, success: { _ in }, failure: { error in
            XCTAssertNotNil(error)
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Get Backup Status

    func testGetBackupStatusInProgress() {
        let expect = expectation(description: "Get backup status in progress success")
        stubRemoteResponse(backupEndpoint,
                           filename: getBackupStatusInProgressMockFilename,
                           contentType: .ApplicationJSON)

        service.getBackupStatus(siteID, downloadID: downloadID, success: { backup in
            XCTAssertEqual(backup.downloadID, 283987)
            XCTAssertEqual(backup.rewindID, "1608555731.536")
            XCTAssertEqual(backup.progress, 88)
            XCTAssertNil(backup.downloadCount)
            XCTAssertNil(backup.url)
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetBackupStatusComplete() {
        let expect = expectation(description: "Get backup status complete success")
        stubRemoteResponse(backupEndpoint,
                           filename: getBackupStatusCompleteMockFilename,
                           contentType: .ApplicationJSON)

        service.getBackupStatus(siteID, downloadID: downloadID, success: { backup in
            XCTAssertEqual(backup.downloadID, 283844)
            XCTAssertEqual(backup.rewindID, "1608510088.971")
            XCTAssertEqual(backup.downloadCount, 0)
            XCTAssertNil(backup.progress)
            XCTAssertNotNil(backup.url)
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetBackupStatusCompleteWithDownloadID() {
        let expect = expectation(description: "Get backup status complete with download ID success")
        stubRemoteResponse(backupEndpoint,
                           filename: getBackupStatusCompleteMockFilename,
                           contentType: .ApplicationJSON)

        service.getBackupStatus(siteID, downloadID: downloadID, success: { backup in
            XCTAssertEqual(backup.downloadID, 283844)
            XCTAssertEqual(backup.rewindID, "1608510088.971")
            XCTAssertEqual(backup.downloadCount, 0)
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetBackupFailure() {
        let expect = expectation(description: "Get backup status complete failure")
        stubRemoteResponse(backupEndpoint,
                           filename: prepareBackupSuccessMockFilename,
                           contentType: .ApplicationJSON,
                           status: 503)

        service.getBackupStatus(siteID, downloadID: downloadID, success: { _ in }, failure: { error in
            XCTAssertNotNil(error)
            expect.fulfill()
        })

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testGetBackupStatusCompleteWithoutDownloadID() {
        let expect = expectation(description: "Get backup status complete with download ID success")
        stubRemoteResponse(backupEndpoint,
                           filename: getBackupStatusCompleteWithoutDownloadIDMockFilename,
                           contentType: .ApplicationJSON)

        service.getAllBackupStatus(siteID, success: { backup in
            XCTAssertEqual(backup.first?.downloadID, 283844)
            XCTAssertEqual(backup.first?.rewindID, "1608510088.971")
            XCTAssertEqual(backup.first?.downloadCount, 0)
            expect.fulfill()
        }, failure: { _ in })

        waitForExpectations(timeout: timeout, handler: nil)
    }

}
