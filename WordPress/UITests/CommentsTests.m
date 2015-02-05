#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import "WordPressTestCredentials.h"
#import "UIWindow-KIFAdditions.h"
#import "WPUITestCase.h"
#import "NSError-KIFAdditions.h"

@interface CommentsTests : WPUITestCase

@end

@implementation CommentsTests

- (void) makeSureCommentExists {
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
    [self makeSureCommentExists];
    [self login];
}

- (void)afterAll
{
    [self logout];
}

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"My Sites"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"My Sites"];
    [tester waitForTimeInterval:2];
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Blogs"];
    [tester tapViewWithAccessibilityLabel:@"Comments"];
    [tester waitForTimeInterval:5];

}


- (void) testOpen {
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Comments Table"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
}

- (void) testReply {
     [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Comments Table"];
     [tester waitForTimeInterval:2];
    
     [tester enterText:@"What about it?" intoViewWithAccessibilityIdentifier:@"ReplyText"];
    
     [tester tapViewWithAccessibilityLabel:@"REPLY"];
     [tester waitForTimeInterval:2];

     [tester tapViewWithAccessibilityLabel:@"Back"];
     [tester waitForTimeInterval:2];
}

- (void) testLike {
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Comments Table"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Like"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
}

- (void) testApprove {
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Comments Table"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Approve"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];

}

- (void) testSpam {
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Comments Table"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Spam"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Spam"];
    [tester waitForTimeInterval:2];

    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
}

- (void) testEdit {
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Comments Table"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Edit"];
    [tester waitForTimeInterval:2];
    
    [tester enterTextIntoCurrentFirstResponder:[NSString stringWithFormat:@"Smashing comment %ld", random()]];
    
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForTimeInterval:2];

    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
}

- (void) testTrash {
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Comments Table"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Trash"];
    [tester waitForTimeInterval:2];

    [tester tapViewWithAccessibilityLabel:@"Delete"];
    [tester waitForTimeInterval:2];

    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
}

@end
