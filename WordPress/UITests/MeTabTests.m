#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import "WordPressTestCredentials.h"
#import "UIWindow-KIFAdditions.h"
#import "WPUITestCase.h"

@interface MeTabTests : WPUITestCase

@end

@implementation MeTabTests

- (void)beforeAll
{
    [self logoutIfNeeded];
    [self login];
}

- (void)afterAll
{
    [self logout];
}

- (void)testMeTab
{
    [tester tapViewWithAccessibilityLabel:@"My Sites"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"My Sites"];
    [tester waitForTimeInterval:2];
    [tester waitForViewWithAccessibilityIdentifier:@"Blogs"];
}

- (void)testHideBlog
{
    [tester tapViewWithAccessibilityLabel:@"My Sites"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"My Sites"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Edit"];
    
    [tester setOn:NO forSwitchWithAccessibilityIdentifier:[NSString stringWithFormat:@"Switch-Visibility-%@", oneStepUser]];
    
    [tester tapViewWithAccessibilityLabel:@"Done"];
    
    [tester tapViewWithAccessibilityLabel:@"Edit"];
    
    [tester setOn:YES forSwitchWithAccessibilityIdentifier:[NSString stringWithFormat:@"Switch-Visibility-%@", oneStepUser]];

    [tester tapViewWithAccessibilityLabel:@"Done"];
}

- (void)testMeNavigation
{
    [tester tapViewWithAccessibilityLabel:@"My Sites"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"My Sites"];
    [tester waitForTimeInterval:2];

    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Blogs"];
    
    [tester tapViewWithAccessibilityLabel:@"Blog Posts"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Back"];
    
    [tester tapViewWithAccessibilityLabel:@"Pages"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Comments"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Stats"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"View Site"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Settings"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
}

- (void)testSettingsAbout
{
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Help & Support"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"About"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Terms of Service"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Privacy Policy"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Support"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];

}

- (void)testSettingsSupport
{
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Help & Support"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Activity Logs"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Current"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Logs"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Clear Old Activity Logs"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Support"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
}

@end
