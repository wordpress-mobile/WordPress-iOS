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
    [tester clearTextFromViewWithAccessibilityLabel:@"Username / Email"];
    [tester clearTextFromViewWithAccessibilityLabel:@"Password"];
    
    [tester enterText:oneStepUser intoViewWithAccessibilityLabel:@"Username / Email"];
    [tester enterText:oneStepPassword intoViewWithAccessibilityLabel:@"Password"];
    [tester tapViewWithAccessibilityLabel:@"Sign In"];
    
    [tester waitForTimeInterval:3];
    // Verify that the login succeeded
    [tester waitForViewWithAccessibilityLabel:@"Main Navigation"];
}

- (void)afterAll
{
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester tapViewWithAccessibilityLabel:@"Settings"];
    [tester tapViewWithAccessibilityLabel:@"Sign Out"];
    [tester tapViewWithAccessibilityLabel:@"Sign Out"];
    [tester waitForTimeInterval:3];
}

- (void)testMeTab
{
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester waitForViewWithAccessibilityLabel:@"Blogs"];
}

- (void)testHideBlog
{
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Edit"];
    
    [tester setOn:NO forSwitchWithAccessibilityLabel:[NSString stringWithFormat:@"Switch-Visibility-%@", oneStepUser]];
    
    [tester tapViewWithAccessibilityLabel:@"Edit"];
    
    [tester tapViewWithAccessibilityLabel:@"Edit"];
    
    [tester setOn:YES forSwitchWithAccessibilityLabel:[NSString stringWithFormat:@"Switch-Visibility-%@", oneStepUser]];

    [tester tapViewWithAccessibilityLabel:@"Edit"];
}

- (void)testMeNavigation
{
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];

    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Blogs"];
    
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

- (void) testMeAddPost {
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Blogs"];
    
    [tester tapViewWithAccessibilityLabel:@"Posts"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"New Post"];
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

- (void) testMeRemovePost {
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Blogs"];
    
    [tester tapViewWithAccessibilityLabel:@"Posts"];
    [tester waitForTimeInterval:3];

    [tester swipeViewWithAccessibilityLabel:@"PostCell" inDirection:KIFSwipeDirectionLeft];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Delete"];
    [tester waitForTimeInterval:2];
}

- (void) testMePostSetCategory {
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Blogs"];
    
    [tester tapViewWithAccessibilityLabel:@"Posts"];
    [tester waitForTimeInterval:5];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"PostsTable"];
    
    [tester tapViewWithAccessibilityLabel:@"Options"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Categories"];
    [tester waitForTimeInterval:2];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"CategoriesList"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];

    [tester tapViewWithAccessibilityLabel:@"Update"];
    [tester waitForTimeInterval:2];
    
}

- (void) testMePostSetTag {
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Blogs"];
    
    [tester tapViewWithAccessibilityLabel:@"Posts"];
    [tester waitForTimeInterval:5];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"PostsTable"];
    
    [tester tapViewWithAccessibilityLabel:@"Options"];
    [tester waitForTimeInterval:2];
    
    [tester clearTextFromAndThenEnterText:@"iOS, KIF" intoViewWithAccessibilityLabel:@"Tags Value"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Update"];
    [tester waitForTimeInterval:2];
}

- (void) testMePostSetSchedule {
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Blogs"];
    
    [tester tapViewWithAccessibilityLabel:@"Posts"];
    [tester waitForTimeInterval:5];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"PostsTable"];
    
    [tester tapViewWithAccessibilityLabel:@"Options"];
    [tester waitForTimeInterval:2];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] inTableViewWithAccessibilityIdentifier:@"SettingsTable"];
    [tester waitForTimeInterval:2];

// TODO: Need to find the proper way to change the date
//    [tester selectDatePickerValue:@[@"Wed Oct 8",@"6",@"30",@"PM" ]];
//    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Done"];
    [tester waitForTimeInterval:2];

    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
}

- (void) testMePostToggleStatus {
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Blogs"];
    
    [tester tapViewWithAccessibilityLabel:@"Posts"];
    [tester waitForTimeInterval:5];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"PostsTable"];
    
    [tester tapViewWithAccessibilityLabel:@"Options"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Status"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Draft"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForTimeInterval:2];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"PostsTable"];
    
    [tester tapViewWithAccessibilityLabel:@"Options"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Status"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Published"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Publish"];
    [tester waitForTimeInterval:2];
    
}

- (void) testMePostVisibility {
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Blogs"];
    
    [tester tapViewWithAccessibilityLabel:@"Posts"];
    [tester waitForTimeInterval:5];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"PostsTable"];
    
    [tester tapViewWithAccessibilityLabel:@"Options"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Visibility"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Private"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForTimeInterval:5];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"PostsTable"];
    
    [tester tapViewWithAccessibilityLabel:@"Options"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Visibility"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Password protected"];
    [tester waitForTimeInterval:2];
    
    [tester clearTextFromAndThenEnterText:@"Testing123" intoViewWithAccessibilityLabel:@"Password Value" ];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Publish"];
    [tester waitForTimeInterval:5];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"PostsTable"];
    
    [tester tapViewWithAccessibilityLabel:@"Options"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Visibility"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Public"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Update"];
    [tester waitForTimeInterval:2];
    
}


@end
