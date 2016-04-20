#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "TestContextManager.h"
#import "Post.h"

@interface PostModelTest : XCTestCase

@end

@implementation PostModelTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (Post *)newPostForTesting
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    Post *post = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Post class])
                                               inManagedObjectContext:context];
    return post;
}

- (void)testPostModelPropertyDefaultValues
{
    Post *post = [self newPostForTesting];

    XCTAssertNil(post.date_created_gmt);
    XCTAssertTrue(post.metaPublishImmediately);
    XCTAssertFalse(post.metaIsLocal);
    XCTAssertEqual([post.remoteStatusNumber integerValue], 0);
    XCTAssertEqual(post.remoteStatus, 0);
    XCTAssertTrue([post.status isEqualToString:PostStatusPublish]);
}

- (void)testMetaIsLocalUpdates
{
    Post *post = [self newPostForTesting];

    post.date_created_gmt = [NSDate date];
    XCTAssertFalse(post.metaPublishImmediately);

    post.date_created_gmt = nil;
    XCTAssertTrue(post.metaPublishImmediately);
}

- (void)testMetaPublishImmedatelyUpdates
{
    Post *post = [self newPostForTesting];

    post.remoteStatus = AbstractPostRemoteStatusLocal;
    XCTAssertTrue(post.metaIsLocal);

    post.remoteStatus = AbstractPostRemoteStatusSync;
    XCTAssertFalse(post.metaIsLocal);
}

@end
