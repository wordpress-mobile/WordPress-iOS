#import <XCTest/XCTest.h>
#import "BasePost.h"


@interface BasePostTest : XCTestCase
@end

@implementation BasePostTest

- (void)testTitleForStatus
{
    NSString *status = PostStatusDraft;
    NSString *title = [BasePost titleForStatus:status];
    XCTAssertTrue([title isEqualToString:@"Draft"], @"Title did not match status.");

    status = PostStatusPending;
    title = [BasePost titleForStatus:status];
    XCTAssertTrue([title isEqualToString:@"Pending review"], @"Title did not match status.");

    status = PostStatusPrivate;
    title = [BasePost titleForStatus:status];
    XCTAssertTrue([title isEqualToString:@"Privately published"], @"Title did not match status.");

    status = PostStatusPublish;
    title = [BasePost titleForStatus:status];
    XCTAssertTrue([title isEqualToString:@"Published"], @"Title did not match status.");

    status = PostStatusTrash;
    title = [BasePost titleForStatus:status];
    XCTAssertTrue([title isEqualToString:@"Trashed"], @"Title did not match status.");

    status = PostStatusScheduled;
    title = [BasePost titleForStatus:status];
    XCTAssertTrue([title isEqualToString:@"Scheduled"], @"Title did not match status.");
}

- (void)testSummaryForContent
{
    NSString *content = @"<p>Lorem ipsum dolor sit amet, [shortcode param=\"value\"]consectetur[/shortcode] adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p> <p>Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.</p><p>Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.</p><p>Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>";
    NSString *summary = [BasePost summaryFromContent:content];
    NSString *expectedSummary = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, …";

    XCTAssertTrue([summary isEqualToString:expectedSummary], @"The expected summary was not derived from the content.");
}

@end
