#import <XCTest/XCTest.h>
#import "ReaderPost.h"
#import "NSString+Helpers.h"
#import "TestContextManager.h"
#import "WordPress-Swift.h"

@interface ReaderPostTest : XCTestCase
@end

@implementation ReaderPostTest

- (void)testSiteIconForDisplay
{
    NSManagedObjectContext *context = [[TestContextManager sharedInstance] mainContext];
    ReaderPost *post = [NSEntityDescription insertNewObjectForEntityForName:@"ReaderPost"
                                         inManagedObjectContext:context];

    XCTAssertNil([WPImageURLHelper siteIconURLForContentProvider:post size:50]);

    NSString *iconURL = @"http://example.com/icon.png";
    post.siteIconURL = iconURL;

    NSString *iconForDisplay = [[WPImageURLHelper siteIconURLForContentProvider:post size:50] absoluteString];

    XCTAssertTrue([iconURL isEqualToString:iconForDisplay], @"Expected %@ but got %@", iconURL, iconForDisplay);


    iconURL = @"http://example.com/blavatar/icon.png";
    post.siteIconURL = iconURL;
    iconForDisplay = [[WPImageURLHelper siteIconURLForContentProvider:post size:50] absoluteString];

    NSString *blavatarURL = @"http://example.com/blavatar/icon.png?d=404&s=50";
    XCTAssertTrue([blavatarURL isEqualToString:iconForDisplay], @"Expected %@ but got %@", blavatarURL, iconForDisplay);
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
