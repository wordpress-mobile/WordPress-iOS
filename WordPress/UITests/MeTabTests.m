#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import "WordPressTestCredentials.h"
#import "UIWindow-KIFAdditions.h"

@interface MeTabTests : KIFTestCase

@end

@implementation MeTabTests

- (void)beforeAll
{
    [tester clearTextFromViewWithAccessibilityLabel:@"Username"];
    [tester clearTextFromViewWithAccessibilityLabel:@"Password"];
    
    [tester enterText:oneStepUser intoViewWithAccessibilityLabel:@"Username"];
    [tester enterText:oneStepPassword intoViewWithAccessibilityLabel:@"Password"];
    [tester tapViewWithAccessibilityLabel:@"SignIn"];
    
    [tester waitForTimeInterval:3];
    // Verify that the login succeeded
    [tester waitForViewWithAccessibilityLabel:@"MainTabBar"];
}

- (void)afterAll
{
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester tapViewWithAccessibilityLabel:@"SettingsButton"];
    [tester tapViewWithAccessibilityLabel:@"wpcom-sign-out"];
    [tester tapViewWithAccessibilityLabel:@"Sign Out"];
    [tester waitForTimeInterval:3];
}

- (void)testMeTab
{
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester waitForViewWithAccessibilityLabel:@"MeView"];
}

- (void)testHideBlog
{
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"EditButton"];
    
    [tester setOn:NO forSwitchWithAccessibilityLabel:[NSString stringWithFormat:@"Switch-Visibility-%@", oneStepUser]];
    
    [tester tapViewWithAccessibilityLabel:@"EditButton"];
    
    [tester tapViewWithAccessibilityLabel:@"EditButton"];
    
    [tester setOn:YES forSwitchWithAccessibilityLabel:[NSString stringWithFormat:@"Switch-Visibility-%@", oneStepUser]];

    [tester tapViewWithAccessibilityLabel:@"EditButton"];
}

- (void)testMeNavigation
{
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];

    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"TableBlogList"];
    
    [tester tapViewWithAccessibilityLabel:@"Posts"];
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
    
    [tester tapViewWithAccessibilityLabel:@"Edit Site"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
}

- (void) testMePostsPages {
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"TableBlogList"];
    
    [tester tapViewWithAccessibilityLabel:@"Posts"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"addpost"];
    [tester waitForTimeInterval:2];
    
    [tester enterText:@"KIF Test Post" intoViewWithAccessibilityLabel:@"Title"];
    [tester waitForTimeInterval:2];

    [[[[UIApplication sharedApplication] keyWindow] firstResponder] resignFirstResponder];
    
    [tester enterTextIntoCurrentFirstResponder:@"KIF Test Post Content" ];
    [tester waitForTimeInterval:2];

    [[[[UIApplication sharedApplication] keyWindow] firstResponder] resignFirstResponder];
    
    [tester tapViewWithAccessibilityLabel:@"Publish"];
    [tester waitForTimeInterval:2];
}


@end
