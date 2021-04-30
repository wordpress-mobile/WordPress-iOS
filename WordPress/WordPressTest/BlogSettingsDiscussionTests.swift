import Foundation
@testable import WordPress


class BlogSettingsDiscussionTests: XCTestCase {
    fileprivate var manager: TestContextManager!

    override func setUp() {
        manager = TestContextManager()
    }

    override func tearDown() {
        ContextManager.overrideSharedInstance(nil)
        manager.mainContext.reset()
        manager = nil
    }

    func testCommentsAutoapprovalDisabledEnablesManualModerationFlag() {
        let settings = newSettings()
        settings.commentsAutoapproval = .disabled
        XCTAssertTrue(settings.commentsRequireManualModeration)
        XCTAssertFalse(settings.commentsFromKnownUsersAllowlisted)
    }

    func testCommentsAutoapprovalFromKnownUsersEnablesAllowlistedFlag() {
        let settings = newSettings()
        settings.commentsAutoapproval = .fromKnownUsers
        XCTAssertFalse(settings.commentsRequireManualModeration)
        XCTAssertTrue(settings.commentsFromKnownUsersAllowlisted)
    }

    func testCommentsAutoapprovalEverythingDisablesManualModerationAndAllowlistedFlags() {
        let settings = newSettings()
        settings.commentsAutoapproval = .everything
        XCTAssertFalse(settings.commentsRequireManualModeration)
        XCTAssertFalse(settings.commentsFromKnownUsersAllowlisted)
    }

    func testCommentsSortingSetsTheCorrectCommentSortOrderIntegerValue() {
        let settings = newSettings()

        settings.commentsSorting = .ascending
        XCTAssertTrue(settings.commentsSortOrder?.intValue == Sorting.ascending.rawValue)

        settings.commentsSorting = .descending
        XCTAssertTrue(settings.commentsSortOrder?.intValue == Sorting.descending.rawValue)
    }

    func testCommentsSortOrderAscendingSetsTheCorrectCommentSortOrderIntegerValue() {
        let settings = newSettings()

        settings.commentsSortOrderAscending = true
        XCTAssertTrue(settings.commentsSortOrder?.intValue == Sorting.ascending.rawValue)

        settings.commentsSortOrderAscending = false
        XCTAssertTrue(settings.commentsSortOrder?.intValue == Sorting.descending.rawValue)
    }

    func testCommentsThreadingDisablesSetsThreadingEnabledFalse() {
        let settings = newSettings()

        settings.commentsThreading = .disabled
        XCTAssertFalse(settings.commentsThreadingEnabled)
    }

    func testCommentsThreadingEnabledSetsThreadingEnabledTrueAndTheRightDepthValue() {
        let settings = newSettings()

        settings.commentsThreading = .enabled(depth: 10)
        XCTAssertTrue(settings.commentsThreadingEnabled)
        XCTAssert(settings.commentsThreadingDepth == 10)

        settings.commentsThreading = .enabled(depth: 2)
        XCTAssertTrue(settings.commentsThreadingEnabled)
        XCTAssert(settings.commentsThreadingDepth == 2)
    }



    // MARK: - Typealiases
    typealias Sorting = BlogSettings.CommentsSorting

    // MARK: - Private Helpers
    fileprivate func newSettings() -> BlogSettings {
        let context = manager!.mainContext
        let name = BlogSettings.classNameWithoutNamespaces()
        let entity = NSEntityDescription.insertNewObject(forEntityName: name, into: context)

        return entity as! BlogSettings
    }
}
