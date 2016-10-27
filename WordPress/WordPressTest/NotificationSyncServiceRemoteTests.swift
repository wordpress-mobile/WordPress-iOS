import Foundation
import XCTest
import OHHTTPStubs
@testable import WordPress


// MARK: - NotificationSyncServiceRemoteTests
//
class NotificationSyncServiceRemoteTests: XCTestCase
{
    // MARK: - Properties

    private var mockRemoteApi: WordPressComRestApi?
    private var serviceRemote: NotificationSyncServiceRemote!
    private let requestTimeout = NSTimeInterval(0.5)


    // MARK: - Overriden Methods
    override func setUp() {
        super.setUp()
        mockRemoteApi = WordPressComRestApi(oAuthToken: nil, userAgent: nil)
        serviceRemote = NotificationSyncServiceRemote(wordPressComRestApi: mockRemoteApi)
    }

    override func tearDown() {
        super.tearDown()
        removeAllStubs()
    }


    /// Vefifies that loadNotes retrieves a notification with all of its fields populated
    ///
    func testLoadNotesEffectivelyRetrievesAllOfTheNotificationFields() {
        let endpoint = "notifications/"
        let response = "notifications-load-all.json"
        stubRequest(forEndpoint: endpoint, withFileAtPath: response)

        let expectation = expectationWithDescription("Load All")
        serviceRemote.loadNotes { notes in

            guard let notes = notes, let note = notes.first else {
                XCTFail()
                return
            }

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

            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(requestTimeout, handler: nil)
    }


    /// Verifies that LoadHashes retrieves a collection of Remote Notifications with only their ID + Hash set
    ///
    func testLoadHashesRetrievesOnlyTheNotificationHashes() {
        let endpoint = "notifications/"
        let response = "notifications-load-hash.json"
        stubRequest(forEndpoint: endpoint, withFileAtPath: response)

        let expectation = expectationWithDescription("Load Hashes")
        serviceRemote.loadHashes { notes in

            guard let notes = notes else {
                XCTFail()
                return
            }

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

            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(requestTimeout, handler: nil)
    }


    /// Verifies that Mark as Read successfully parses the backend's response
    ///
    func testUpdateReadStatus() {
        let endpoint = "notifications/read"
        let response = "notifications-mark-as-read.json"
        stubRequest(forEndpoint: endpoint, withFileAtPath: response)

        let expectation = expectationWithDescription("Mark as Read")
        serviceRemote.updateReadStatus("1234", read: true) { success in

            XCTAssertTrue(success)
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(requestTimeout, handler: nil)
    }


    /// Verifies that Update Last Seen successfully parses the backend's response
    ///
    func testUpdateLastSeen() {
        let endpoint = "notifications/seen"
        let response = "notifications-last-seen.json"
        stubRequest(forEndpoint: endpoint, withFileAtPath: response)

        let expectation = expectationWithDescription("Update Last Seen")
        serviceRemote.updateLastSeen("1234") { success in
            XCTAssertTrue(success)
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(requestTimeout, handler: nil)
    }
}


// MARK: - Private helpers
//
private extension NotificationSyncServiceRemoteTests
{
    func stubRequest(forEndpoint endpoint: String, withFileAtPath path: String) {
        stub({ request in
            return request.URL?.absoluteString?.rangeOfString(endpoint) != nil
        }) { _ in
            let stubPath = OHPathForFile(path, self.dynamicType)!
            return fixture(stubPath, headers: ["Content-Type": "application/json"])
        }
    }

    func removeAllStubs() {
        OHHTTPStubs.removeAllStubs()
    }
}
