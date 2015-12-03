import Foundation
@testable import WordPress


public class BlogSettingsDiscussionTests : XCTestCase
{
    private var manager : TestContextManager!
    
    public override func setUp() {
        manager = TestContextManager()
    }
    
    public override func tearDown() {
        manager = nil
    }
    
    func testCommentsAutoapprovalDisabledEnablesManualModerationFlag() {
        let settings = newSettings()
        settings.commentsAutoapproval = .Disabled
        XCTAssertTrue(settings.commentsRequireManualModeration)
        XCTAssertFalse(settings.commentsFromKnownUsersWhitelisted)
    }
    
    func testCommentsAutoapprovalFromKnownUsersEnablesWhitelistedFlag() {
        let settings = newSettings()
        settings.commentsAutoapproval = .FromKnownUsers
        XCTAssertFalse(settings.commentsRequireManualModeration)
        XCTAssertTrue(settings.commentsFromKnownUsersWhitelisted)
    }
    
    func testCommentsAutoapprovalEverythingDisablesManualModerationAndWhitelistedFlags() {
        let settings = newSettings()
        settings.commentsAutoapproval = .Everything
        XCTAssertFalse(settings.commentsRequireManualModeration)
        XCTAssertFalse(settings.commentsFromKnownUsersWhitelisted)
    }
    
    func testCommentsSortingSetsTheCorrectCommentSortOrderIntegerValue() {
        let settings = newSettings()
        
        settings.commentsSorting = .Ascending
        XCTAssertTrue(settings.commentsSortOrder == Sorting.Ascending.rawValue)
        
        settings.commentsSorting = .Descending
        XCTAssertTrue(settings.commentsSortOrder == Sorting.Descending.rawValue)
    }
    
    func testCommentsSortOrderAscendingSetsTheCorrectCommentSortOrderIntegerValue() {
        let settings = newSettings()
        
        settings.commentsSortOrderAscending = true
        XCTAssertTrue(settings.commentsSortOrder == Sorting.Ascending.rawValue)
        
        settings.commentsSortOrderAscending = false
        XCTAssertTrue(settings.commentsSortOrder == Sorting.Descending.rawValue)
    }
    
    func testCommentsThreadingDisablesSetsThreadingEnabledFalse() {
        let settings = newSettings()
        
        settings.commentsThreading = .Disabled
        XCTAssertFalse(settings.commentsThreadingEnabled)
    }
    
    func testCommentsThreadingEnabledSetsThreadingEnabledTrueAndTheRightDepthValue() {
        let settings = newSettings()
        
        settings.commentsThreading = .Enabled(depth: 10)
        XCTAssertTrue(settings.commentsThreadingEnabled)
        XCTAssert(settings.commentsThreadingDepth == 10)
        
        settings.commentsThreading = .Enabled(depth: 2)
        XCTAssertTrue(settings.commentsThreadingEnabled)
        XCTAssert(settings.commentsThreadingDepth == 2)
    }
    
    
    
    // MARK: - Typealiases
    typealias Sorting = BlogSettings.CommentsSorting
    
    // MARK: - Private Helpers
    public func newSettings() -> BlogSettings {
        let context = manager!.mainContext
        let name = BlogSettings.classNameWithoutNamespaces()
        let entity = NSEntityDescription.insertNewObjectForEntityForName(name, inManagedObjectContext: context)
        
        return entity as! BlogSettings
    }
}
