#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ContextManager-Internals.h"
#import "TestContextManager.h"
#import "Notification.h"


@interface NotificationTests : XCTestCase
@property (nonatomic, strong) TestContextManager *contextManager;
@end

@implementation NotificationTests

- (void)setUp
{
    [super setUp];
    self.contextManager = [[TestContextManager alloc] init];
}

- (void)tearDown
{
    [super tearDown];
    
    // Note: We'll force TestContextManager override reset, since, for (unknown reasons) the TestContextManager
    // might be retained more than expected, and it may break other core data based tests.
    [ContextManager overrideSharedInstance:nil];
}

- (void)testBadgeNotificationHasBadgeFlagSetToTrue
{
    Notification *note = [self loadBadgeNotification];
    XCTAssertTrue(note.isBadge, @"Badge flag should be true");
}

- (void)testBadgeNotificationHasRegularFieldsSet
{
    Notification *note = [self loadBadgeNotification];
    XCTAssertNotNil(note.type, @"Missing Notification Type");
    XCTAssertNotNil(note.noticon, @"Missing Noticon");
    XCTAssertNotNil(note.timestampAsDate, @"Timestamp could not be parsed");
    XCTAssertNotNil(note.icon, @"Missing Noticon");
    XCTAssertNotNil(note.url, @"Missing Resource URL");
}

- (void)testBadgeNotificationContainsOneSubjectBlock
{
    Notification *note = [self loadBadgeNotification];
    XCTAssertNotNil(note.subjectBlock, @"Missing subjectBlock");
    XCTAssertNotNil(note.subjectBlock.text, @"Subject Block has no text!");
}

- (void)testBadgeNotificationContainsOneImageBlockGroup
{
    Notification *note = [self loadBadgeNotification];
    NotificationBlockGroup *group = [note blockGroupOfType:NoteBlockGroupTypeImage];
    XCTAssertNotNil(group, @"Missing Image Block Group");
    
    NotificationBlock *imageBlock = group.blocks.firstObject;
    XCTAssertNotNil(imageBlock, @"Missing Image Block");
    
    NotificationMedia *media = imageBlock.media.firstObject;
    XCTAssertNotNil(media, @"Missing Media");
    XCTAssertNotNil(media.mediaURL, @"Missing mediaURL");
}

- (void)testLikeNotificationContainsOneSubjectBlock
{
    Notification *note = [self loadLikeNotification];
    XCTAssertNotNil(note.subjectBlock, @"Missing subjectBlock");
    XCTAssertNotNil(note.subjectBlock.text, @"Subject Block has no text!");
}

- (void)testLikeNotificationContainsHeader
{
    Notification *note = [self loadLikeNotification];
    NotificationBlockGroup *header = note.headerBlockGroup;
    XCTAssertNotNil(header, @"Missing headerBlockGroup");

    NotificationBlock *gravatarBlock = [header blockOfType:NoteBlockTypeImage];
    XCTAssertNotNil(gravatarBlock.text, @"Missing Gravatar Text");
    
    NotificationMedia *media = gravatarBlock.media.firstObject;
    XCTAssertNotNil(media.mediaURL, @"Missing Gravatar URL");
    
    NotificationBlock *snippetBlock = [header blockOfType:NoteBlockTypeText];
    XCTAssertNotNil(snippetBlock.text, @"Missing Snippet Block");
}

- (void)testLikeNotificationContainsUserBlocksInTheBody
{
    Notification *note = [self loadLikeNotification];
    for (NotificationBlockGroup *group in note.bodyBlockGroups) {
        XCTAssertTrue(group.type == NoteBlockGroupTypeUser);
    }
}

- (void)testLikeNotificationContainsPostAndSiteID
{
    Notification *note = [self loadLikeNotification];
    XCTAssertNotNil(note.metaSiteID, @"Missing SiteID");
    XCTAssertNotNil(note.metaPostID, @"Missing PostID");
}

- (void)testFollowerNotificationHasFollowFlagSetToTrue
{
    Notification *note = [self loadFollowerNotification];
    XCTAssertTrue(note.isFollow, @"Follow flag should be true");
}

- (void)testFollowerNotificationContainsOneSubjectBlock
{
    Notification *note = [self loadFollowerNotification];
    XCTAssertNotNil(note.subjectBlock, @"Missing subjectBlock");
    XCTAssertNotNil(note.subjectBlock.text, @"Subject Block has no text!");
}

- (void)testFollowerNotificationContainsSiteID
{
    Notification *note = [self loadFollowerNotification];
    XCTAssertNotNil(note.metaSiteID, @"Missing siteID");
}

- (void)testFollowerNotificationContainsUserAndFooterBlocksInTheBody
{
    Notification *note = [self loadFollowerNotification];
    
    // Note: Account for 'View All Followers'
    for (NotificationBlockGroup *group in note.bodyBlockGroups) {
        XCTAssertTrue(group.type == NoteBlockGroupTypeUser || group.type == NoteBlockGroupTypeFooter);
    }
}

- (void)testFollowerNotificationContainsFooterBlockWithFollowRangeAtTheEnd
{
    Notification *note = [self loadFollowerNotification];
    
    NotificationBlockGroup *lastGroup = note.bodyBlockGroups.lastObject;
    XCTAssertTrue(lastGroup.type == NoteBlockGroupTypeFooter);
    
    NotificationBlock *block = [lastGroup.blocks firstObject];
    XCTAssertNotNil(block.text, @"Missing block text");
    
    NotificationRange *range = block.ranges.firstObject;
    XCTAssertNotNil(range, @"Missing range");
    XCTAssertEqualObjects(range.type, @"follow", @"Missing follow range");
}

- (void)testCommentNotificationHasCommentFlagSetToTrue
{
    Notification *note = [self loadCommentNotification];
    XCTAssertTrue(note.isComment, @"Comment flag should be true");
}

- (void)testCommentNotificationContainsSubjectWithSnippet
{
    Notification *note = [self loadCommentNotification];
    XCTAssertNotNil(note.subjectBlock.text, @"Subject Block has no text!");
    XCTAssertNotNil(note.snippetBlock.text, @"Subject Block has no text!");
}

- (void)testCommentNotificationContainsHeader
{
    Notification *note = [self loadCommentNotification];
    NotificationBlockGroup *header = note.headerBlockGroup;
    XCTAssertNotNil(header, @"Missing headerBlockGroup");
    
    NotificationBlock *gravatarBlock = [header blockOfType:NoteBlockTypeImage];
    XCTAssertNotNil(gravatarBlock.text, @"Missing Gravatar Text");
    
    NotificationMedia *media = gravatarBlock.media.firstObject;
    XCTAssertNotNil(media.mediaURL, @"Missing Gravatar URL");
    
    NotificationBlock *snippetBlock = [header blockOfType:NoteBlockTypeText];
    XCTAssertNotNil(snippetBlock.text, @"Missing Snippet Block");
}

- (void)testCommentNotificationContainsCommentAndSiteID
{
    Notification *note = [self loadCommentNotification];
    XCTAssertNotNil(note.metaSiteID, @"Missing siteID");
    XCTAssertNotNil(note.metaCommentID, @"Missing commentID");
}

- (void)testFindingNotificationRangeSearchingByReplyCommentID
{
    Notification *note = [self loadCommentNotification];
    XCTAssertNotNil(note.metaReplyID, @"Missing Reply ID");
    
    NotificationBlockGroup *footerGroup = [note blockGroupOfType:NoteBlockGroupTypeFooter];
    NotificationBlock *textBlock = [footerGroup blockOfType:NoteBlockGroupTypeText];
    XCTAssertNotNil(textBlock, @"Missing View Reply Text Block");
    
    NotificationRange *range = [textBlock notificationRangeWithCommentId:note.metaReplyID];
    XCTAssertNotNil(range, @"Missing Reply Range");
}


#pragma mark - Helpers

- (NSString *)entityName
{
    return NSStringFromClass([Notification class]);
}

- (Notification *)loadBadgeNotification
{
    return (Notification *)[self.contextManager loadEntityNamed:self.entityName
                                             withContentsOfFile:@"notifications-badge.json"];
}

- (Notification *)loadLikeNotification
{
    return (Notification *)[self.contextManager loadEntityNamed:self.entityName
                                             withContentsOfFile:@"notifications-like.json"];
}

- (Notification *)loadFollowerNotification
{
    return (Notification *)[self.contextManager loadEntityNamed:self.entityName
                                             withContentsOfFile:@"notifications-new-follower.json"];
}

- (Notification *)loadCommentNotification
{
    return (Notification *)[self.contextManager loadEntityNamed:self.entityName
                                             withContentsOfFile:@"notifications-replied-comment.json"];
}

@end
