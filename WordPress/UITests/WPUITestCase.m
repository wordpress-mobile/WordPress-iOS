#import "WPUITestCase.h"
#import <Foundation/Foundation.h>
#import "WordPressTestCredentials.h"

@implementation WPUITestCase

- (void) login
{
    [tester clearTextFromAndThenEnterText:oneStepUser intoViewWithAccessibilityIdentifier:@"Username / Email"];
    [tester clearTextFromAndThenEnterText:oneStepPassword intoViewWithAccessibilityIdentifier:@"Password"];
    [tester tapViewWithAccessibilityLabel:@"Sign In"];
    
    [tester waitForTimeInterval:3];
    // Verify that the login succeeded
    [tester waitForViewWithAccessibilityIdentifier:@"Main Navigation"];
}

- (void) loginOther
{
    [tester clearTextFromAndThenEnterText:twoStepUser intoViewWithAccessibilityIdentifier:@"Username / Email"];
    [tester clearTextFromAndThenEnterText:twoStepPassword intoViewWithAccessibilityIdentifier:@"Password"];
    [tester tapViewWithAccessibilityLabel:@"Sign In"];
    
    [tester waitForTimeInterval:3];
    // Verify that the login succeeded
    [tester waitForViewWithAccessibilityIdentifier:@"Main Navigation"];
}

- (void) logout
{
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:1];
    [tester tapViewWithAccessibilityLabel:@"Sign Out"];
    [tester waitForTimeInterval:1];
    [tester tapViewWithAccessibilityLabel:@"Sign Out"];
    [tester waitForTimeInterval:1];
}

- (void) logoutIfNeeded {
    if(![tester tryFindingViewWithAccessibilityIdentifier:@"Username / Email" error:nil]){
        [self logout];
    }
}


@end