#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import "WordPressTestCredentials.h"
#import "UIWindow-KIFAdditions.h"
#import "WPUITestCase.h"
#import "NSError-KIFAdditions.h"

@interface PagesTests : WPUITestCase

@end

@implementation PagesTests

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
    [tester tapViewWithAccessibilityLabel:@"My Sites"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"My Sites"];
    [tester waitForTimeInterval:5];
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Blogs"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Blog Posts"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    [tester tapViewWithAccessibilityLabel:@"Pages"];
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
    [tester tapViewWithAccessibilityLabel:@"New Page"];
    [tester waitForTimeInterval:2];
    
    if ([tester tryFindingTappableViewWithAccessibilityLabel:@"Title" error:nil]) {
        [tester enterText:@"KIF Test Page" intoViewWithAccessibilityLabel:@"Title"];
        [tester waitForTimeInterval:2];
        [[[[UIApplication sharedApplication] keyWindow] firstResponder] resignFirstResponder];
        [tester enterTextIntoCurrentFirstResponder:@"KIF Test Page Content" ];
        [tester waitForTimeInterval:2];
        
        [[[[UIApplication sharedApplication] keyWindow] firstResponder] resignFirstResponder];

    } else {
        [tester enterTextIntoCurrentFirstResponder:@"KIF Test Page\t"];
        [tester waitForTimeInterval:2];
    }
    
    if ([tester tryFindingTappableViewWithAccessibilityLabel:@"Publish" error:nil]) {
        [tester tapViewWithAccessibilityLabel:@"Publish"];
    } else {
        [tester tapViewWithAccessibilityLabel:@"Post"];
    }
    [tester waitForTimeInterval:2];
}

- (void) testRemove {
    [tester swipeViewWithAccessibilityIdentifier:@"PostCell" inDirection:KIFSwipeDirectionLeft];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabelStartingWith:@"Trash"];
    [tester waitForTimeInterval:2];
}

- (void) selectOptions {
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"PostsTable"];
    
    if ([tester tryFindingViewWithAccessibilityLabel:@"Edit" error:nil]) {
        [tester tapViewWithAccessibilityLabel:@"Edit"];
        [tester waitForTimeInterval:2];
    }
    
    [tester tapViewWithAccessibilityIdentifier:@"Options"];
    [tester waitForTimeInterval:2];
}

- (void) testSetSchedule {
    [self selectOptions];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"SettingsTable"];
    [tester waitForTimeInterval:2];

// TODO: Need to find the proper way to change the date
//    [tester selectDatePickerValue:@[@"Wed Oct 8",@"6",@"30",@"PM" ]];
//    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Done"];
    [tester waitForTimeInterval:2];

    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
// new editor
    if ([tester tryFindingViewWithAccessibilityLabel:@"Cancel" error:nil]) {
        [tester tapViewWithAccessibilityLabel:@"Update"];
        [tester waitForTimeInterval:2];
    } else if ([tester tryFindingViewWithAccessibilityLabel:@"Close" error:nil]) {
        [tester tapViewWithAccessibilityLabel:@"Close"];
        [tester waitForTimeInterval:2];
    }
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];

}

- (void) testSetStatus {
    [self selectOptions];
    
    [tester tapViewWithAccessibilityIdentifier:@"Status"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Draft"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForTimeInterval:2];
    
    [self selectOptions];
    
    [tester tapViewWithAccessibilityIdentifier:@"Status"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Published"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    //depends of the editor version
    if ([tester tryFindingViewWithAccessibilityLabel:@"Post" error:nil]) {
        [tester tapViewWithAccessibilityLabel:@"Post"];
    } else if ([tester tryFindingViewWithAccessibilityLabel:@"Publish" error:nil]) {
        [tester tapViewWithAccessibilityLabel:@"Publish"];
    }
    [tester waitForTimeInterval:2];
    
}

- (void) testSetVisibility {
    [self selectOptions];
    
    [tester tapViewWithAccessibilityIdentifier:@"Visibility"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Private"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Save"];
    [tester waitForTimeInterval:5];
    
    [self selectOptions];
    
    [tester tapViewWithAccessibilityIdentifier:@"Visibility"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Password protected"];
    [tester waitForTimeInterval:2];
    
    [tester clearTextFromAndThenEnterText:@"Testing123" intoViewWithAccessibilityIdentifier:@"Password Value" ];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    //depends of the editor version
    if ([tester tryFindingViewWithAccessibilityLabel:@"Post" error:nil]) {
        [tester tapViewWithAccessibilityLabel:@"Post"];
    } else if ([tester tryFindingViewWithAccessibilityLabel:@"Publish" error:nil]) {
        [tester tapViewWithAccessibilityLabel:@"Publish"];
    }
    [tester waitForTimeInterval:2];
    
    [self selectOptions];
    
    [tester tapViewWithAccessibilityIdentifier:@"Visibility"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Public"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Update"];
    [tester waitForTimeInterval:2];
}

- (void) testSetFeaturedImage {
    for (int i = 0; i < 2 ; i++) {
        [self selectOptions];
        
        if ( [tester tryFindingTappableViewWithAccessibilityLabel:@"Set Featured Image" error:nil]) {
            [tester tapViewWithAccessibilityLabel:@"Set Featured Image"];
            [tester waitForTimeInterval:2];
            
            if ([tester tryFindingTappableViewWithAccessibilityLabel:@"Camera Roll" error:nil]){
                [tester tapViewWithAccessibilityLabel:@"Camera Roll"];
            } else {
                [tester tapViewWithAccessibilityLabel:@"Saved Photos"];
            }
            [tester waitForTimeInterval:2];
            
            [tester tapViewWithAccessibilityLabelStartingWith:@"Photo, "];
            //Wait for upload to happen.
            [tester waitForTimeInterval:15];
            
            [tester tapViewWithAccessibilityLabel:@"Back"];
            [tester waitForTimeInterval:2];
            
            [tester tapViewWithAccessibilityLabel:@"Update"];
            [tester waitForTimeInterval:5];
        } else {
            [tester waitForViewWithAccessibilityIdentifier:@"Current Featured Image"];
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

- (void) testPreview {
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"PostsTable"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabelStartingWith:@"Preview"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
}


@end
