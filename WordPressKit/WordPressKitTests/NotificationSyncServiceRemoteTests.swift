import Foundation
import XCTest
@testable import WordPressKit

// MARK: - NotificationSyncServiceRemoteTests
//
class NotificationSyncServiceRemoteTests: RemoteTestCase, RESTTestable {
    
    // MARK: - Constants
    
    let notificationsEndpoint       = "notifications/"
    let notificationsReadEndpoint   = "notifications/read"
    let notificationsSeenEndpoint   = "notifications/seen"
    
    let notificationServiceLoadAllMockFilename      = "notifications-load-all.json"
    let notificationServiceLoadHashMockFilename     = "notifications-load-hash.json"
    let notificationServiceMarkReadMockFilename     = "notifications-mark-as-read.json"
    let notificationServiceLastSeenMockFilename     = "notifications-last-seen.json"

    // MARK: - Properties
    
    var remote: NotificationSyncServiceRemote!

    // MARK: - Overriden Methods
    
    override func setUp() {
        super.setUp()
        
        remote = NotificationSyncServiceRemote(wordPressComRestApi: getRestApi())
    }

    override func tearDown() {
        super.tearDown()
        
        remote = nil
    }

    /// Vefifies that loadNotes retrieves a notification with all of its fields populated
    ///
    func testLoadNotesEffectivelyRetrievesAllOfTheNotificationFields() {
        let expect = expectation(description: "Load all notifications success")
        stubRemoteResponse(notificationsEndpoint, filename: notificationServiceLoadAllMockFilename, contentType: .ApplicationJSON)
        remote.loadNotes { error, notes in
            guard let notes = notes, let note = notes.first else {
                XCTFail()
                return
            }
            XCTAssertNil(error)
            XCTAssertEqual(note.notificationId, "2674124016")
            XCTAssertEqual(note.notificationHash, "4007447833")
            XCTAssertEqual(note.read, true)
            XCTAssertNotNil(note.icon)
            XCTAssertNotNil(note.noticon)
            XCTAssertNotNil(note.timestamp)
            XCTAssertNotNil(note.type)
            XCTAssertNotNil(note.url)
            XCTAssertNotNil(note.title)
            XCTAssertNotNil(note.subject)
            XCTAssertNotNil(note.header)
            XCTAssertNotNil(note.body)
            XCTAssertNotNil(note.meta)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }
    
    func testLoadNotesWithServerErrorFails() {
        let expect = expectation(description: "Load all notifications server error failure")
        
        stubRemoteResponse(notificationsEndpoint, data: Data(), contentType: .NoContentType, status: 500)
        remote.loadNotes { error, notes in
            guard let error = error as NSError? else {
                XCTFail("The returned error could not be cast as NSError")
                expect.fulfill()
                return
            }
            XCTAssertNil(notes)
            XCTAssertEqual(error.domain, String(reflecting: WordPressComRestApiError.self), "The error domain should be WordPressComRestApiError")
            XCTAssertEqual(error.code, WordPressComRestApiError.unknown.rawValue, "The error code should be 7 - unknown")
            expect.fulfill()
        }
        waitForExpectations(timeout: timeout, handler: nil)
    }

    /// Verifies that LoadHashes retrieves a collection of Remote Notifications with only their ID + Hash set
    ///
    func testLoadHashesRetrievesOnlyTheNotificationHashes() {
        let expect = expectation(description: "Load notification hashes success")
        stubRemoteResponse(notificationsEndpoint, filename: notificationServiceLoadHashMockFilename, contentType: .ApplicationJSON)
        remote.loadHashes { error, notes in
            guard let notes = notes else {
                XCTFail()
                return
            }
            XCTAssertNil(error)
            XCTAssertEqual(notes.count, 10)
            for note in notes {
                XCTAssertNotNil(note.notificationId)
                XCTAssertNotNil(note.notificationHash)
                XCTAssertNil(note.icon)
                XCTAssertNil(note.noticon)
                XCTAssertNil(note.timestamp)
                XCTAssertNil(note.type)
                XCTAssertNil(note.url)
                XCTAssertNil(note.title)
                XCTAssertNil(note.subject)
                XCTAssertNil(note.header)
                XCTAssertNil(note.body)
                XCTAssertNil(note.meta)
            }
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    /// Verifies that Mark as Read successfully parses the backend's response
    ///
    func testUpdateReadStatus() {
        let expect = expectation(description: "Mark notifications as read success")
        stubRemoteResponse(notificationsReadEndpoint, filename: notificationServiceMarkReadMockFilename, contentType: .ApplicationJSON)
        remote.updateReadStatus("1234", read: true) { error in
            XCTAssertNil(error)
            expect.fulfill()
        }
        
        waitForExpectations(timeout: timeout, handler: nil)
    }

    /// Verifies that Update Last Seen successfully parses the backend's response
    ///
    func testUpdateLastSeen() {
        let expect = expectation(description: "Update last seen notification success")
        stubRemoteResponse(notificationsSeenEndpoint, filename: notificationServiceLastSeenMockFilename, contentType: .ApplicationJSON)
        remote.updateLastSeen("1234") { error in
            XCTAssertNil(error)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
