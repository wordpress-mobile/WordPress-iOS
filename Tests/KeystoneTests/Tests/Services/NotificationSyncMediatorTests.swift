import Foundation
import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift
import WordPressData
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

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        dotcomAPI = WordPressComRestApi(oAuthToken: "1234", userAgent: "yosemite")
        mediator = NotificationSyncMediator(manager: contextManager, dotcomAPI: dotcomAPI, accountUUID: nil)
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
        mediator.sync { _, _ in
            XCTAssert(self.mainContext.countObjects(ofType: Notification.self) == 1)
            expect.fulfill()
        }

        wait(for: [expect], timeout: timeout)
    }

    /// Verifies that a sync bound to an account that is no longer the default does not write its notes, so a
    /// late result from a replaced account cannot repopulate the new account's list, and does not report new data.
    ///
    func testSyncDoesNotWriteNotesOnceItsAccountIsReplaced() {
        let result = sync(boundTo: "account-A", defaultAccount: "account-B")
        XCTAssertEqual(result.noteCount, 0)
        XCTAssertFalse(result.hasNewData)
    }

    /// Verifies that a sync bound to an account that is no longer the default does not delete local notes, so a
    /// late result from a replaced account cannot purge the new account's list.
    ///
    func testSyncDoesNotDeleteNotesOnceItsAccountIsReplaced() {
        let noteID = "new-account-note"
        mainContext.insertNewObject(ofType: Notification.self).notificationId = noteID
        contextManager.saveContextAndWait(mainContext)

        _ = sync(boundTo: "account-A", defaultAccount: "account-B")

        let predicate = NSPredicate(format: "notificationId == %@", noteID)
        XCTAssertNotNil(mainContext.firstObject(ofType: Notification.self, matching: predicate))
    }

    /// Verifies that a sync bound to the current default account still writes its notes.
    ///
    func testSyncWritesNotesForTheDefaultAccount() {
        let result = sync(boundTo: "account-A", defaultAccount: "account-A")
        XCTAssertEqual(result.noteCount, 1)
        XCTAssertTrue(result.hasNewData)
    }

    /// Verifies that syncing a single note bound to an account that is no longer the default does not write it.
    /// Unlike `sync`, `syncNote` reaches the write without going through the delete first.
    ///
    func testSyncNoteDoesNotWriteOnceItsAccountIsReplaced() {
        let previousDefault = UserSettings.defaultDotComUUID
        UserSettings.defaultDotComUUID = "account-B"
        defer { UserSettings.defaultDotComUUID = previousDefault }

        let stubPath = OHPathForFile("notifications-load-all.json", type(of: self))!
        HTTPStubs.stubRequest(forEndpoint: "notifications/", withFileAtPath: stubPath)
        let mediator = NotificationSyncMediator(
            manager: contextManager,
            dotcomAPI: dotcomAPI,
            accountUUID: "account-A"
        )!

        let expect = expectation(description: "Sync")
        mediator.syncNote(with: "2674124016") { error, note in
            XCTAssertNil(error)
            XCTAssertNil(note)
            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)
        XCTAssertEqual(mainContext.countObjects(ofType: Notification.self), 0)
    }

    private func sync(boundTo accountUUID: String, defaultAccount: String) -> (noteCount: Int, hasNewData: Bool) {
        let previousDefault = UserSettings.defaultDotComUUID
        UserSettings.defaultDotComUUID = defaultAccount
        defer { UserSettings.defaultDotComUUID = previousDefault }

        let stubPath = OHPathForFile("notifications-load-all.json", type(of: self))!
        HTTPStubs.stubRequest(forEndpoint: "notifications/", withFileAtPath: stubPath)
        let mediator = NotificationSyncMediator(
            manager: contextManager,
            dotcomAPI: dotcomAPI,
            accountUUID: accountUUID
        )!

        let expect = expectation(description: "Sync")
        var hasNewData = false
        mediator.sync { error, newData in
            XCTAssertNil(error)
            hasNewData = newData
            expect.fulfill()
        }
        wait(for: [expect], timeout: timeout)
        return (mainContext.countObjects(ofType: Notification.self), hasNewData)
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
        let note = try WordPressData.Notification.fixture(fromFile: path, insertInto: mainContext)

        XCTAssertNotNil(note)
        XCTAssertFalse(note.read)

        // CoreData Expectations
        let contextSaved = expectation(forNotification: .NSManagedObjectContextDidSave, object: mainContext)

        // Mediator Expectations
        let expect = expectation(description: "Mark as Read")

        // Mark as Read!
        mediator.markAsRead(note) { _ in
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
        let note1 = try WordPressData.Notification.fixture(fromFile: path1, insertInto: mainContext)
        let note2 = try WordPressData.Notification.fixture(fromFile: path2, insertInto: mainContext)
        let note3 = try WordPressData.Notification.fixture(fromFile: path3, insertInto: mainContext)

        XCTAssertFalse(note1.read)
        XCTAssertFalse(note3.read)

        XCTAssertTrue(note2.read)

        // CoreData Expectations
        let contextSaved = expectation(forNotification: .NSManagedObjectContextDidSave, object: mainContext)

        // Mediator Expectations
        let expect = expectation(description: "Mark as Read")

        // Mark as Read!
        mediator.markAsRead([note1, note3]) { _ in
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
        let note1 = try WordPressData.Notification.fixture(fromFile: path1, insertInto: mainContext)
        let note2 = try WordPressData.Notification.fixture(fromFile: path2, insertInto: mainContext)
        let note3 = try WordPressData.Notification.fixture(fromFile: path3, insertInto: mainContext)

        XCTAssertFalse(note1.read)
        XCTAssertFalse(note3.read)

        XCTAssertTrue(note2.read)

        // CoreData Expectations
        let contextSaved = expectation(forNotification: .NSManagedObjectContextDidSave, object: mainContext)

        // Mediator Expectations
        let expect = expectation(description: "Mark as Read")

        // Mark as Read!
        mediator.markAsRead([note1]) { _ in
            XCTAssertTrue(note1.read)
            XCTAssertFalse(note3.read)
            expect.fulfill()
        }

        wait(for: [contextSaved, expect], timeout: timeout)
    }
}
