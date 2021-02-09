import Foundation
import XCTest
import OHHTTPStubs
@testable import WordPress


// MARK: - NotificationSyncMediatorTests
//
class NotificationSyncMediatorTests: XCTestCase {
    /// CoreData Context Manager
    ///
    fileprivate var manager: TestContextManager!

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

        manager = TestContextManager()
        dotcomAPI = WordPressComRestApi(oAuthToken: "1234", userAgent: "yosemite")
        mediator = NotificationSyncMediator(manager: manager, dotcomAPI: dotcomAPI)

        // Note:
        // Since the TestContextManager actually changed, and thus, the entire Core Data stack,
        // we'll need to manually reset the global shared Derived Context.
        // This definitely won't be needed in the actual app.
        //
        NotificationSyncMediator.resetSharedDerivedContext()
    }

    override func tearDown() {
        super.tearDown()

        manager = nil
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
        XCTAssert(manager.mainContext.countObjects(ofType: Notification.self) == 0)

        // CoreData Expectations
        manager.testExpectation = expectation(description: "Context save expectation")


        // Mediator Expectations
        let expect = expectation(description: "Sync")

        // Sync!
        mediator.sync { (_, _) in
            XCTAssert(self.manager.mainContext.countObjects(ofType: Notification.self) == 1)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
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
//        XCTAssert(manager.mainContext.countObjects(ofType: Notification.self) == 0)
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
//            XCTAssert(self.manager.mainContext.countObjects(ofType: Notification.self) == 1)
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
        XCTAssert(manager.mainContext.countObjects(ofType: Notification.self) == 0)

        // CoreData Expectations
        manager.testExpectation = expectation(description: "Context save expectation")

        // Mediator Expectations
        let expect = expectation(description: "Sync")

        // Sync!
        mediator.syncNote(with: "2674124016") { error, note in
            XCTAssertNil(error)
            XCTAssertNotNil(note)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }


    /// Verifies that Mark as Read effectively toggles a Notification's read flag
    ///
    func testMarkAsReadEffectivelyTogglesNotificationReadStatus() {
        // Stub Endpoint
        let endpoint = "notifications/read"
        let stubPath = OHPathForFile("notifications-mark-as-read.json", type(of: self))!
        HTTPStubs.stubRequest(forEndpoint: endpoint, withFileAtPath: stubPath)

        // Inject Dummy Note
        let path = "notifications-like.json"
        let note = manager.loadEntityNamed(Notification.entityName(), withContentsOfFile: path) as! WordPress.Notification

        XCTAssertNotNil(note)
        XCTAssertFalse(note.read)

        // CoreData Expectations
        manager.testExpectation = expectation(description: "Context save expectation")

        // Mediator Expectations
        let expect = expectation(description: "Mark as Read")

        // Mark as Read!
        mediator.markAsRead(note) { success in
            XCTAssertTrue(note.read)
            expect.fulfill()
        }

        waitForExpectations(timeout: timeout, handler: nil)
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
