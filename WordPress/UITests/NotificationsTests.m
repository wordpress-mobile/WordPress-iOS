#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import "WordPressTestCredentials.h"
#import "UIWindow-KIFAdditions.h"
#import "WPUITestCase.h"
#import "NSError-KIFAdditions.h"

@interface NotificationsTests : WPUITestCase

@end

@implementation NotificationsTests

- (void) makeSureNotificationExists {
    [self loginOther];
    
    [tester tapViewWithAccessibilityLabel:@"Reader"];
    [tester waitForTimeInterval:5];
    
    [tester tapViewWithAccessibilityLabel:@"Topics"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Blogs I Follow"];
    [tester waitForTimeInterval:5];
    
    [tester tapViewWithAccessibilityLabel:@"Comment"];
    [tester waitForTimeInterval:2];
    
    
    [tester enterText:[NSString stringWithFormat:@"Interesting %@",[NSDate date]] intoViewWithAccessibilityIdentifier:@"ReplyText"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"REPLY"];
    [tester waitForTimeInterval:2];
    [self logout];
}

- (void)beforeAll
{
    [self logoutIfNeeded];
    [self makeSureNotificationExists];
    [self login];
}

- (void)afterAll
{
    [self logout];
}

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"Notifications"];
    [tester waitForTimeInterval:5];
}

- (void)afterEach
{
    if ([tester tryFindingTappableViewWithAccessibilityLabel:@"Back" error:nil]){
        [tester tapViewWithAccessibilityLabel:@"Back"];
        [tester waitForTimeInterval:2];
    }
    
    if ([tester tryFindingTappableViewWithAccessibilityLabel:@"Back" error:nil]){
        [tester tapViewWithAccessibilityLabel:@"Back"];
        [tester waitForTimeInterval:2];
    }
}


- (void) testOpen {
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Notifications Table"];
    [tester waitForTimeInterval:2];

    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Notification Details Table"];
    [tester waitForTimeInterval:2];

    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Notification Details Table"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];

    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];

}

- (void) testModerate {
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Notifications Table"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Approve"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
}

- (void) testReply {
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Notifications Table"];
    [tester waitForTimeInterval:2];
    
    [tester enterText:@"Reply Text" intoViewWithAccessibilityIdentifier:@"ReplyText"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"REPLY"];
    [tester waitForTimeInterval:2];

    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
}


@end
