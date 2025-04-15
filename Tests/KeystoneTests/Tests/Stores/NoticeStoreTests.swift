import WordPressFlux
import XCTest

@testable import WordPress

class NoticeStoreTests: XCTestCase {
    private var dispatcher: ActionDispatcher!
    private var store: NoticeStore!

    override func setUp() {
        super.setUp()

        dispatcher = ActionDispatcher()
        store = NoticeStore(dispatcher: dispatcher)
    }

    override func tearDown() {
        dispatcher = nil
        store = nil

        super.tearDown()
    }

    func testPostActionSetsTheNoticeAsTheCurrent() {
        // Given
        precondition(store.currentNotice == nil)
        let notice = Notice(title: "Alpha")

        // When
        dispatch(.post(notice))

        // Then
        XCTAssertEqual(notice, store.currentNotice)
    }

    func testPostActionQueuesTheNoticeIfThereIsACurrentNotice() {
        // Given
        let alpha = Notice(title: "Alpha")
        dispatch(.post(alpha))
        precondition(store.currentNotice == alpha)

        // When
        dispatch(.post(Notice(title: "Bravo")))

        // Then
        XCTAssertEqual(alpha, store.currentNotice)
    }

    func testDismissActionSetsTheNextNoticeInTheQueueAsTheCurrent() {
        // Given
        let alpha = Notice(title: "Alpha")
        let bravo = Notice(title: "Bravo")

        dispatch(.post(alpha))
        dispatch(.post(bravo))

        precondition(store.currentNotice == alpha)

        // When
        dispatch(.dismiss)

        // Then
        XCTAssertEqual(bravo, store.currentNotice)
    }

    func testClearActionCanClearTheCurrentNotice() {
        // Given
        let alpha = Notice(title: "Alpha")
        let bravo = Notice(title: "Bravo")

        dispatch(.post(alpha))
        dispatch(.post(bravo))

        precondition(store.currentNotice == alpha)

        // When
        dispatch(.clear(alpha))

        // Then
        // Alpha was removed so the next in queue, Bravo, is set as the current
        XCTAssertEqual(bravo, store.currentNotice)
    }

    func testClearActionCanRemoveANoticeInTheQueue() {
        // Given
        let alpha = Notice(title: "Alpha")
        let bravo = Notice(title: "Bravo")

        dispatch(.post(alpha))
        dispatch(.post(bravo))

        precondition(store.currentNotice == alpha)

        // When
        dispatch(.clear(bravo))
        // Remove alpha
        dispatch(.dismiss)

        // Then
        // Since Bravo was removed from the queue, there should be no current
        XCTAssertNil(store.currentNotice)
    }

    func testClearWithTagActionRemovesNoticesWithTheMatchingTag() {
        // Given
        let tagToClear: Notice.Tag = "quae"
        let alpha = Notice(title: "Alpha", tag: tagToClear)
        let bravo = Notice(title: "Bravo")
        let charlie = Notice(title: "Charlie", tag: tagToClear)

        [alpha, bravo, charlie].forEach { dispatch(.post($0)) }

        precondition(store.currentNotice == alpha)

        // When
        dispatch(.clearWithTag(tagToClear))

        // Then
        // Since Alpha was removed, Bravo is now the current Notice
        XCTAssertEqual(bravo, store.currentNotice)

        // Dismiss Bravo so that we can test that Charlie was removed too
        dispatch(.dismiss)
        XCTAssertNil(store.currentNotice)
    }

    func testEmptyActionClearsTheQueueButNotTheCurrentNotice() {
        // Given
        let alpha = Notice(title: "Alpha")
        let bravo = Notice(title: "Bravo")
        let charlie = Notice(title: "Charlie")

        [alpha, bravo, charlie].forEach { dispatch(.post($0)) }

        precondition(store.currentNotice == alpha)

        // When
        dispatch(.empty)

        // Then
        XCTAssertEqual(alpha, store.currentNotice)
        // Dismiss Alpha so that we can test that everything else was removed
        dispatch(.dismiss)
        XCTAssertNil(store.currentNotice)
    }

    func testLockActionClearsTheNoticeThatIsShown() {
        let alpha = Notice(title: "Alpha")
        let bravo = Notice(title: "Bravo")
        [alpha, bravo].forEach { dispatch(.post($0)) }

        XCTAssertEqual(alpha, store.currentNotice)
        dispatch(.lock)
        XCTAssertEqual(nil, store.currentNotice)
    }

    func testLockUnlockShowsEnqueuedNotices() {
        dispatch(.lock)
        let alpha = Notice(title: "Alpha")
        let bravo = Notice(title: "Bravo")
        [alpha, bravo].forEach { dispatch(.post($0)) }

        dispatch(.unlock)
        XCTAssertEqual(alpha, store.currentNotice)
    }

    func testCanNotDismissNoticesOnLockedStore() {
        dispatch(.lock)
        let alpha = Notice(title: "Alpha")
        let bravo = Notice(title: "Bravo")
        [alpha, bravo].forEach { dispatch(.post($0)) }
        dispatch(.dismiss) // You can't dismiss notices in the locked store. Since that would removed notices without showing them to the user.
        dispatch(.unlock)
        XCTAssertEqual(alpha, store.currentNotice)
    }

    // MARK: - Helpers

    private func dispatch(_ action: NoticeAction) {
        dispatcher.dispatch(action)
    }
}
