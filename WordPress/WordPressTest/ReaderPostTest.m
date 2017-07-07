#import <XCTest/XCTest.h>
#import "ReaderPost.h"
#import "TestContextManager.h"
@import WordPressShared;

@interface ReaderPostTest : XCTestCase
@end

@implementation ReaderPostTest

- (void)testSiteIconForDisplay
{
    NSManagedObjectContext *context = [[TestContextManager sharedInstance] mainContext];
    ReaderPost *post = [NSEntityDescription insertNewObjectForEntityForName:@"ReaderPost"
                                         inManagedObjectContext:context];

    XCTAssertNil([post siteIconForDisplayOfSize:50]);

    NSString *iconURL = @"http://example.com/icon.png";
    post.siteIconURL = iconURL;

    NSString *iconForDisplay = [[post siteIconForDisplayOfSize:50] absoluteString];

    XCTAssertTrue([iconURL isEqualToString:iconForDisplay]);


    iconURL = @"http://example.com/blavatar/icon.png";
    post.siteIconURL = iconURL;
    iconForDisplay = [[post siteIconForDisplayOfSize:50] absoluteString];

    XCTAssertTrue([@"http://example.com/blavatar/icon.png?s=50&d=404" isEqualToString:iconForDisplay]);
}

- (void)testDisplayDate
{
    NSManagedObjectContext *context = [[TestContextManager sharedInstance] mainContext];
    ReaderPost *post = [NSEntityDescription insertNewObjectForEntityForName:@"ReaderPost"
                                                     inManagedObjectContext:context];

    // Arbitrary time interval.  Anything except "now" just so we have a better test.
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:-10000];
    post.dateCreated = date;
    XCTAssertTrue([post.dateCreated isEqualToDate:post.dateForDisplay]);
}

@end
