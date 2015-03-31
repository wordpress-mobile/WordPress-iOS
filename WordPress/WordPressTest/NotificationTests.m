#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
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
    self.contextManager = nil;
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

@end
