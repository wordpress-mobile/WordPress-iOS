#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <KIF/KIF.h>
#import "WordPressTestCredentials.h"
#import "UIWindow-KIFAdditions.h"
#import "WPUITestCase.h"
#import "NSError-KIFAdditions.h"
#import "WPStatsViewController.h"

@interface StatsTests : WPUITestCase

@end

@implementation StatsTests

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
    [tester waitForTimeInterval:2];
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] inTableViewWithAccessibilityIdentifier:@"Blogs"];
    [tester tapViewWithAccessibilityLabel:@"Stats"];
    [tester waitForTimeInterval:2];

}


- (void) testToggleDayWeekMonth {
    NSArray * elements = @[@"WEEKS", @"MONTHS", @"DAYS"];
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMM" options:0 locale:[NSLocale currentLocale]];
//    NSDate * now = [NSDate date];
//    NSString * month = [dateFormatter stringFromDate:now];
    
    for (NSString * timePeriod in elements){
        [tester tapViewWithAccessibilityLabel:timePeriod];
        [tester waitForTimeInterval:2];

// TODO: Find a way to match the bar elements
//        UIAccessibilityElement * photoCellAccessibilityElement = nil;
//        UIView * photoCell = nil;
//        if ([tester tryFindingAccessibilityElement:&photoCellAccessibilityElement view:&photoCell withElementMatchingPredicate:[NSPredicate predicateWithFormat:@"accessibilityLabel BEGINSWITH %@", month] tappable:YES error:nil]){
//            
//            [tester tapAccessibilityElement:photoCellAccessibilityElement inView:photoCell];
//        } else {
//            [tester failWithError:[NSError KIFErrorWithFormat:@"Unable to find photo element"] stopTest:YES];
//        }
    }
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
}

- (void) testTodayYesterday {
    NSArray * sectionsToTest = @[@(StatsSectionTopPosts), @(StatsSectionViewsByCountry), @(StatsSectionClicks), @(StatsSectionReferrers), @(StatsSectionSearchTerms)];
    
    for (NSNumber * section in sectionsToTest){
        [tester waitForCellAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:[section intValue]] inTableViewWithAccessibilityIdentifier:@"Stats Table"];
        [tester waitForTimeInterval:2];

        [tester tapViewWithAccessibilityLabel:@"YESTERDAY"];
        [tester waitForTimeInterval:2];

        [tester tapViewWithAccessibilityLabel:@"TODAY"];
        [tester waitForTimeInterval:2];
    }

    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
}

- (void) testViewWebVersion {
    [tester tapRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:StatsSectionLinkToWebview] inTableViewWithAccessibilityIdentifier:@"Stats Table"];
    [tester waitForTimeInterval:2];
        
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];
    
    [tester tapViewWithAccessibilityLabel:@"Back"];
    [tester waitForTimeInterval:2];

}
@end
