import Foundation
import XCTest
import OHHTTPStubs
@testable import WordPress


// MARK: - NotificationSyncMediatorTests
//
class NotificationSyncMediatorTests: CoreDataTestCase {

    /// WordPress REST API
    ///
    fileprivate var dotcomAPI: WordPressComRestApi!

    /// Sync Mediator
    ///
    fileprivate var mediator: NotificationSyncMediator!

    /// Expectation's Timeout
    ///
    fileprivate let timeout = TimeInterval(3)


    // MARK: - Overriden Methods

    override func setUp() {
        super.setUp()

        dotcomAPI = WordPressComRestApi(oAuthToken: "1234", userAgent: "yosemite")
        mediator = NotificationSyncMediator(manager: contextManager, dotcomAPI: dotcomAPI)
    }

    override func tearDown() {
        super.tearDown()

        HTTPStubs.removeAllStubs()
    }


    /// Verifies that NotificationsSyncMediator effectively inserts a single Notification when *sync* is called.
    /// Normally it'd insert 100, but... that's how our Testing Data looks like!
    ///
    func testSyncEffectivelyInsertsASingleNotification() {
        // Stub Endpoint
        let endpoint = "notifications/"
        let stubPath = OHPathForFile("notifications-load-all.json", type(of: self))!
        HTTPStubs.stubRequest(forEndpoint: endpoint, withFileAtPath: stubPath)

        // Make sure the collection is empty, to begin with
        XCTAssert(mainContext.countObjects(ofType: Notification.self) == 0)

        // Mediator Expectations
        let expect = expectation(description: "Sync")

        // Sync!
        mediator.sync { (_, _) in
            XCTAssert(self.mainContext.countObjects(ofType: Notification.self) == 1)
            expect.fulfill()
        }

        wait(for: [expect], timeout: timeout)
    }


    /// Verifies that the Sync call, when called repeatedly, won't duplicate our local dataset.
    ///
//    func testMultipleSyncCallsWontInsertDuplicateNotes() {
//        // Stub Endpoint
//        let endpoint = "notifications/"
//        let stubPath = OHPathForFile("notifications-load-all.json", type(of: self))!
//        OHHTTPStubs.stubRequest(forEndpoint: endpoint, withFileAtPath: stubPath)
//
//        // Make sure the collection is empty, to begin with
//        XCTAssert(mainContext.countObjects(ofType: Notification.self) == 0)
//
//        // Shutdown Expectation Warnings. Please
//        manager.requiresTestExpectation = false
//
//        // Wait until all the workers complete
//        let group = DispatchGroup()
//
//        // CoreData Expectations
//        for _ in 0..<100 {
//            group.enter()
//
//            let newMediator = NotificationSyncMediator(manager: manager, dotcomAPI: dotcomAPI)
//            newMediator?.sync { (_, _) in
//                group.leave()
//            }
//        }
//
//        // Verify there's no duplication
//        let expect = expectation(description: "Async!")
//
//        group.notify(queue: DispatchQueue.main, execute: {
//            XCTAssert(self.mainContext.countObjects(ofType: Notification.self) == 1)
//            expect.fulfill()
//        })
//
//        waitForExpectations(timeout: timeout, handler: nil)
//    }


    /// Verifies that RefreshNotification withID effectively loads a single Notification from the remote endpoint.
    ///
    func testSyncNoteEffectivelyReturnsASingleNotification() {
        // Stub Endpoint
        let endpoint = "notifications/"
        let stubPath = OHPathForFile("notifications-load-all.json", type(of: self))!
        HTTPStubs.stubRequest(forEndpoint: endpoint, withFileAtPath: stubPath)

        // Make sure the collection is empty, to begin with
        XCTAssert(mainContext.countObjects(ofType: Notification.self) == 0)

        // Mediator Expectations
        let expect = expectation(description: "Sync")

        // Sync!
        mediator.syncNote(with: "2674124016") { error, note in
            XCTAssertNil(error)
            XCTAssertNotNil(note)
            expect.fulfill()
        }

        wait(for: [expect], timeout: timeout)
    }


    /// Verifies that Mark as Read effectively toggles a Notification's read flag
    ///
    func testMarkAsReadEffectivelyTogglesNotificationReadStatus() throws {
        // Stub Endpoint
        let endpoint = "notifications/read"
        let stubPath = OHPathForFile("notifications-mark-as-read.json", type(of: self))!
        HTTPStubs.stubRequest(forEndpoint: endpoint, withFileAtPath: stubPath)

        // Inject Dummy Note
        let path = "notifications-like.json"
        let note = try WordPress.Notification.fixture(fromFile: path, insertInto: mainContext)

        XCTAssertNotNil(note)
        XCTAssertFalse(note.read)

        // CoreData Expectations
        let contextSaved = expectation(forNotification: .NSManagedObjectContextDidSave, object: mainContext)

        // Mediator Expectations
        let expect = expectation(description: "Mark as Read")

        // Mark as Read!
        mediator.markAsRead(note) { success in
            XCTAssertTrue(note.read)
            expect.fulfill()
        }

        wait(for: [contextSaved, expect], timeout: timeout)
    }

    /// Verifies that Mark Notifications as Read effectively toggles a Notifications' read flag
    ///
    func testMarkNotificationsAsReadEffectivelyTogglesNotificationsReadStatus() throws {
        // Stub Endpoint
        let endpoint = "notifications/read"
        let stubPath = OHPathForFile("notifications-mark-as-read.json", type(of: self))!
        HTTPStubs.stubRequest(forEndpoint: endpoint, withFileAtPath: stubPath)

        // Inject Dummy Note
        let path1 = "notifications-like.json"
        let path2 = "notifications-new-follower.json"
        let path3 = "notifications-unapproved-comment.json"
        let note1 = try WordPress.Notification.fixture(fromFile: path1, insertInto: mainContext)
        let note2 = try WordPress.Notification.fixture(fromFile: path2, insertInto: mainContext)
        let note3 = try WordPress.Notification.fixture(fromFile: path3, insertInto: mainContext)

        XCTAssertFalse(note1.read)
        XCTAssertFalse(note3.read)

        XCTAssertTrue(note2.read)

        // CoreData Expectations
        let contextSaved = expectation(forNotification: .NSManagedObjectContextDidSave, object: mainContext)

        // Mediator Expectations
        let expect = expectation(description: "Mark as Read")

        // Mark as Read!
        mediator.markAsRead([note1, note3]) { success in
            XCTAssertTrue(note1.read)
            XCTAssertTrue(note2.read)
            XCTAssertTrue(note3.read)
            expect.fulfill()
        }

        wait(for: [contextSaved, expect], timeout: timeout)
    }

    /// Verifies that Mark Notifications as Read modifies only the specified notifications' read status
    ///
    func testMarkNotificationsAsReadTogglesOnlyTheReadStatusOfPassedInNotifications() throws {
        // Stub Endpoint
        let endpoint = "notifications/read"
        let stubPath = OHPathForFile("notifications-mark-as-read.json", type(of: self))!
        HTTPStubs.stubRequest(forEndpoint: endpoint, withFileAtPath: stubPath)

        // Inject Dummy Note
        let path1 = "notifications-like.json"
        let path2 = "notifications-new-follower.json"
        let path3 = "notifications-unapproved-comment.json"
        let note1 = try WordPress.Notification.fixture(fromFile: path1, insertInto: mainContext)
        let note2 = try WordPress.Notification.fixture(fromFile: path2, insertInto: mainContext)
        let note3 = try WordPress.Notification.fixture(fromFile: path3, insertInto: mainContext)

        XCTAssertFalse(note1.read)
        XCTAssertFalse(note3.read)

        XCTAssertTrue(note2.read)

        // CoreData Expectations
        let contextSaved = expectation(forNotification: .NSManagedObjectContextDidSave, object: mainContext)

        // Mediator Expectations
        let expect = expectation(description: "Mark as Read")

        // Mark as Read!
        mediator.markAsRead([note1]) { success in
            XCTAssertTrue(note1.read)
            XCTAssertFalse(note3.read)
            expect.fulfill()
        }

        wait(for: [contextSaved, expect], timeout: timeout)
    }


    /// Verifies that updateLastSeen method effectively calls the callback with successfull flag
    ///
    func testUpdateLastSeenHitsCallbackWithSuccessfulResult() {
        // Stub Endpoint
        let endpoint = "notifications/seen"
        let stubPath = OHPathForFile("notifications-last-seen.json", type(of: self))!
        HTTPStubs.stubRequest(forEndpoint: endpoint, withFileAtPath: stubPath)

        // Mediator Expectations
        let expect = expectation(description: "Update Last Seen")

        // Update Last Seen!
        mediator.updateLastSeen("1234") { error in
            XCTAssertNil(error)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }
}
