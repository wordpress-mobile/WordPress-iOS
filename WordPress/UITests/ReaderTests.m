#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import "WordPressTestCredentials.h"
#import "UIWindow-KIFAdditions.h"
#import "WPUITestCase.h"
#import "NSError-KIFAdditions.h"

@interface ReaderTests : WPUITestCase

@end

@implementation ReaderTests

- (void)beforeAll
{
    [self logoutIfNeeded];
    [self login];
}

- (void)afterAll
{
    [self logout];
}

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"Reader"];
    [tester waitForTimeInterval:5];
    
    [tester tapViewWithAccessibilityLabel:@"Topics"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Blogs I Follow"];
    [tester waitForTimeInterval:5];
    
}


- (void) testOpen {
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Reader Table"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
}

- (void) testLike {    
    // I like it
    [tester tapViewWithAccessibilityLabel:@"Like"];
    [tester waitForTimeInterval:2];
    // I dislike it
    [tester tapViewWithAccessibilityLabel:@"Like"];
    [tester waitForTimeInterval:2];
}

- (void) testComment {

    [tester tapViewWithAccessibilityLabel:@"Comment"];
    [tester waitForTimeInterval:2];

    [tester enterText:@"Reply Text" intoViewWithAccessibilityIdentifier:@"ReplyText"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"REPLY"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];

}

- (void) testReblog {

    [tester tapViewWithAccessibilityLabel:@"Topics"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Freshly Pressed"];
    [tester waitForTimeInterval:5];
    
    [tester tapViewWithAccessibilityLabel:@"Reblog"];
    [tester waitForTimeInterval:2];
    UIView * view = nil;
    if ([tester tryFindingAccessibilityElement:nil view:&view withIdentifier:@"Optional note" tappable:NO error:nil]) {
        [tester tapScreenAtPoint:CGPointMake(CGRectGetMaxX(view.frame)-10,CGRectGetMaxY(view.frame)-10)];
        [tester waitForTimeInterval:2];
        [tester enterTextIntoCurrentFirstResponder:@"Interesting!"];
        [tester waitForTimeInterval:2];
    }
    [tester tapViewWithAccessibilityLabel:@"Publish"];
    [tester waitForTimeInterval:2];
}

- (void) testFollow {
    [tester tapViewWithAccessibilityLabel:@"Topics"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Freshly Pressed"];
    [tester waitForTimeInterval:5];

    [tester tapViewWithAccessibilityLabel:@"Follow"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Following"];
    [tester waitForTimeInterval:2];

}

- (void) testViewAlternateFeeds {
    NSArray * listOfFeeds = @[@"Freshly Pressed", @"Posts I Like", @"Blogs I Follow"];
    
    for(NSString * feed in listOfFeeds){
        [tester tapViewWithAccessibilityLabel:@"Topics"];
        [tester waitForTimeInterval:2];
        
        [tester tapViewWithAccessibilityLabel:feed];
        [tester waitForTimeInterval:5];
    }
}

- (void) testAddTag {
    [tester tapViewWithAccessibilityLabel:@"Topics"];
    [tester waitForTimeInterval:2];
    
    [tester enterText:@"Sport\n" intoViewWithAccessibilityIdentifier:@"Search" expectedResult:@""];
    [tester waitForTimeInterval:2];

    [tester tapViewWithAccessibilityLabel:@"Close"];
    [tester waitForTimeInterval:2];
}

- (void) testViewFeedOptions {
    [tester tapViewWithAccessibilityLabel:@"Topics"];
    [tester waitForTimeInterval:2];
    
    [tester swipeViewWithAccessibilityIdentifier:@"Pager View" inDirection:KIFSwipeDirectionLeft];
    [tester waitForTimeInterval:2];
    [tester swipeViewWithAccessibilityIdentifier:@"Pager View" inDirection:KIFSwipeDirectionLeft];
    [tester waitForTimeInterval:2];
    [tester swipeViewWithAccessibilityIdentifier:@"Pager View" inDirection:KIFSwipeDirectionRight];
    [tester waitForTimeInterval:2];
    [tester swipeViewWithAccessibilityIdentifier:@"Pager View" inDirection:KIFSwipeDirectionRight];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Close"];
    [tester waitForTimeInterval:2];
}


@end
