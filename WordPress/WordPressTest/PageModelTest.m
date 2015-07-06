#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "TestContextManager.h"
#import "Page.h"

@interface PageModelTest : XCTestCase

@end

@implementation PageModelTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (Page *)newPageForTesting
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    Page *page = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Page class])
                                               inManagedObjectContext:context];
    return page;
}

- (void)testPostModelPropertyDefaultValues
{
    Page *page = [self newPageForTesting];

    XCTAssertNil(page.date_created_gmt);
    XCTAssertTrue(page.metaPublishImmediately);
    XCTAssertFalse(page.metaIsLocal);
    XCTAssertEqual([page.remoteStatusNumber integerValue], 0);
    XCTAssertEqual(page.remoteStatus, 0);
    XCTAssertTrue([page.status isEqualToString:PostStatusPublish]);
}

- (void)testMetaIsLocalUpdates
{
    Page *page = [self newPageForTesting];

    page.date_created_gmt = [NSDate date];
    XCTAssertFalse(page.metaPublishImmediately);

    page.date_created_gmt = nil;
    XCTAssertTrue(page.metaPublishImmediately);
}

- (void)testMetaPublishImmedatelyUpdates
{
    Page *page = [self newPageForTesting];

    page.remoteStatus = AbstractPostRemoteStatusLocal;
    XCTAssertTrue(page.metaIsLocal);

    page.remoteStatus = AbstractPostRemoteStatusSync;
    XCTAssertFalse(page.metaIsLocal);
}

@end
