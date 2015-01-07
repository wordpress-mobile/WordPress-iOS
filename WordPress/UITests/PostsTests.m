#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import "WordPressTestCredentials.h"
#import "UIWindow-KIFAdditions.h"
#import "WPUITestCase.h"
#import "NSError-KIFAdditions.h"

@interface PostsTests : WPUITestCase

@end

@implementation PostsTests

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
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Me"];
    [tester waitForTimeInterval:5];
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Blogs"];
    [tester tapViewWithAccessibilityLabel:@"Posts"];
    [tester waitForTimeInterval:10];

}

- (void)afterEach
{
    if ([tester tryFindingViewWithAccessibilityLabel:@"Blogs" error:nil]){
        return;
    }
    
    if ([tester tryFindingTappableViewWithAccessibilityLabel:@"Back" error:nil]){
        [tester tapViewWithAccessibilityLabel:@"Back"];
        [tester waitForTimeInterval:2];
    }
    
    if ([tester tryFindingTappableViewWithAccessibilityLabel:@"Back" error:nil]){
        [tester tapViewWithAccessibilityLabel:@"Back"];
        [tester waitForTimeInterval:2];
    }
    
    if ([tester tryFindingTappableViewWithAccessibilityLabel:@"Cancel" error:nil]){
        [tester tapViewWithAccessibilityLabel:@"Cancel"];
        [tester waitForTimeInterval:2];
    }
    
    if ([tester tryFindingTappableViewWithAccessibilityLabel:@"Close" error:nil]){
        [tester tapViewWithAccessibilityLabel:@"Close"];
        [tester waitForTimeInterval:2];
    }

}


- (void) testAdd {
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

- (void) testRemove {
    [tester swipeViewWithAccessibilityIdentifier:@"PostCell" inDirection:KIFSwipeDirectionLeft];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Trash"];
    [tester waitForTimeInterval:2];
}

- (void) selectPostOptions {
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"PostsTable"];
    
    if ([tester tryFindingViewWithAccessibilityLabel:@"Edit" error:nil]) {
        [tester tapViewWithAccessibilityLabel:@"Edit"];
        [tester waitForTimeInterval:2];
    }
    
    [tester tapViewWithAccessibilityIdentifier:@"Options"];
    [tester waitForTimeInterval:2];
}

- (void) testSetCategory {
    
    [self selectPostOptions];
    
    [tester tapViewWithAccessibilityIdentifier:@"Categories"];
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

- (void) testSetTag {
    [self selectPostOptions];
    
    [tester clearTextFromAndThenEnterText:[NSString stringWithFormat:@"iOS, KIF, %u", arc4random()] intoViewWithAccessibilityIdentifier:@"Tags Value"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Update"];
    [tester waitForTimeInterval:2];
}

- (void) testSetSchedule {
    [self selectPostOptions];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] inTableViewWithAccessibilityIdentifier:@"SettingsTable"];
    [tester waitForTimeInterval:2];

// TODO: Need to find the proper way to change the date
//    [tester selectDatePickerValue:@[@"Wed Oct 8",@"6",@"30",@"PM" ]];
//    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Done"];
    [tester waitForTimeInterval:2];

    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Close"];
    [tester waitForTimeInterval:2];
}

- (void) testSetStatus {
    [self selectPostOptions];
    
    [tester tapViewWithAccessibilityIdentifier:@"Status"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Draft"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForTimeInterval:2];
    
    [self selectPostOptions];
    
    [tester tapViewWithAccessibilityIdentifier:@"Status"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Published"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Publish"];
    [tester waitForTimeInterval:2];
    
}

- (void) testSetVisibility {
    [self selectPostOptions];
    
    [tester tapViewWithAccessibilityIdentifier:@"Visibility"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Private"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForTimeInterval:5];
    
    [self selectPostOptions];
    
    [tester tapViewWithAccessibilityIdentifier:@"Visibility"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Password protected"];
    [tester waitForTimeInterval:2];
    
    [tester clearTextFromAndThenEnterText:@"Testing123" intoViewWithAccessibilityIdentifier:@"Password Value" ];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Publish"];
    [tester waitForTimeInterval:5];
    
    [self selectPostOptions];
    
    [tester tapViewWithAccessibilityIdentifier:@"Visibility"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Public"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Update"];
    [tester waitForTimeInterval:2];
    
}

- (void) testSetFormat {
    NSArray * formats = @[@"Video", @"Aside", @"Image", @"Quote", @"Link", @"Standard"];
    
    for (NSString * format in formats){
        [self selectPostOptions];
        
        [tester tapViewWithAccessibilityIdentifier:@"Post Format"];
        [tester waitForTimeInterval:2];
        
        [tester tapViewWithAccessibilityLabel:format];
        [tester waitForTimeInterval:2];
        
        [tester tapViewWithAccessibilityLabel:@"Back"];
        [tester waitForTimeInterval:2];
        
        [tester tapViewWithAccessibilityLabel:@"Update"];
        [tester waitForTimeInterval:5];
    }
}

- (void) testSetFeaturedImage {
    for (int i = 0; i < 2 ; i++) {
        [self selectPostOptions];
        
        if ( [tester tryFindingTappableViewWithAccessibilityLabel:@"Set Featured Image" error:nil]) {
            [tester tapViewWithAccessibilityLabel:@"Set Featured Image"];
            [tester waitForTimeInterval:2];
            
            [tester tapViewWithAccessibilityLabel:@"Camera Roll"];
            
            [tester waitForTimeInterval:5];
            
            [tester tapViewWithAccessibilityLabelStartingWith:@"Photo, "];
            
            [tester waitForTimeInterval:15];
            
            [tester tapViewWithAccessibilityLabel:@"Back"];
            [tester waitForTimeInterval:2];
            
            [tester tapViewWithAccessibilityLabel:@"Update"];
            [tester waitForTimeInterval:5];
        } else {
            [tester tapViewWithAccessibilityIdentifier:@"Current Featured Image"];
            [tester waitForTimeInterval:2];
            
            [tester tapViewWithAccessibilityLabel:@"Remove Featured Image"];
            [tester waitForTimeInterval:2];
            
            [tester tapViewWithAccessibilityLabel:@"Remove"];
            [tester waitForTimeInterval:2];
            
            [tester tapViewWithAccessibilityLabel:@"Back"];
            [tester waitForTimeInterval:2];
            
            [tester tapViewWithAccessibilityLabel:@"Update"];
            [tester waitForTimeInterval:5];
        }
    }

}


@end
