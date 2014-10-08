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
    [tester swipeViewWithAccessibilityLabel:@"PostCell" inDirection:KIFSwipeDirectionLeft];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Delete"];
    [tester waitForTimeInterval:2];
}

- (void) testSetCategory {
    
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

- (void) testSetTag {
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"PostsTable"];
    
    [tester tapViewWithAccessibilityLabel:@"Options"];
    [tester waitForTimeInterval:2];
    
    [tester clearTextFromAndThenEnterText:[NSString stringWithFormat:@"iOS, KIF, %ld", random()] intoViewWithAccessibilityLabel:@"Tags Value"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Update"];
    [tester waitForTimeInterval:2];
}

- (void) testSetSchedule {
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
    
    [tester tapViewWithAccessibilityLabel:@"Close"];
    [tester waitForTimeInterval:2];
}

- (void) testSetStatus {
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

- (void) testSetVisibility {
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

- (void) testSetFormat {
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"PostsTable"];
    
    NSArray * formats = @[@"Aside", @"Status", @"Image", @"Quote", @"Link", @"Standard"];
    
    for (NSString * format in formats){
        [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"PostsTable"];
        
        [tester tapViewWithAccessibilityLabel:@"Options"];
        [tester waitForTimeInterval:2];
        
        [tester tapViewWithAccessibilityLabel:@"Post Format"];
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
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"PostsTable"];
    
    [tester tapViewWithAccessibilityLabel:@"Options"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Set Featured Image"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Camera Roll"];
    
    [tester waitForTimeInterval:5];

    UIAccessibilityElement * collectionView = nil;
    UIView * view = nil;
    if ([tester tryFindingAccessibilityElement:&collectionView view:&view withElementMatchingPredicate:[NSPredicate predicateWithFormat:@"accessibilityLabel BEGINSWITH %@", @"Photo, "] tappable:YES error:nil]){

        [tester tapAccessibilityElement:collectionView inView:view];
    } else {
        [tester failWithError:[NSError KIFErrorWithFormat:@"Unable to find photo element"] stopTest:YES];
    }
    
    [tester waitForTimeInterval:15];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Update"];
    [tester waitForTimeInterval:5];
    
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"PostsTable"];
    
    [tester tapViewWithAccessibilityLabel:@"Options"];
    [tester waitForTimeInterval:5];
    
    [tester tapViewWithAccessibilityLabel:@"Current Featured Image"];
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


@end
