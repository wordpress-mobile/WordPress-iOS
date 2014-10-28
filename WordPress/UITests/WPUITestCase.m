#import "WPUITestCase.h"
#import <Foundation/Foundation.h>
#import "WordPressTestCredentials.h"

@implementation WPUITestCase

- (void) login
{
    [tester clearTextFromAndThenEnterText:oneStepUser intoViewWithAccessibilityLabel:@"Username / Email"];
    [tester clearTextFromAndThenEnterText:oneStepPassword intoViewWithAccessibilityLabel:@"Password"];
    [tester tapViewWithAccessibilityLabel:@"Sign In"];
    
    [tester waitForTimeInterval:3];
    // Verify that the login succeeded
    [tester waitForViewWithAccessibilityLabel:@"Main Navigation"];
}

- (void) loginOther
{
    [tester clearTextFromAndThenEnterText:twoStepUser intoViewWithAccessibilityLabel:@"Username / Email"];
    [tester clearTextFromAndThenEnterText:twoStepPassword intoViewWithAccessibilityLabel:@"Password"];
    [tester tapViewWithAccessibilityLabel:@"Sign In"];
    
    [tester waitForTimeInterval:3];
    // Verify that the login succeeded
    [tester waitForViewWithAccessibilityLabel:@"Main Navigation"];
}

- (void) logout
{
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Settings"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Sign Out"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Sign Out"];
    [tester waitForTimeInterval:3];
}

@end