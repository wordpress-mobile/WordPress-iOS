#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "AppRatingUtility.h"

@interface AppRatingUtility(Tests)

+ (void)unregisterAllSections;

@end

@interface AppRatingUtilityTests : XCTestCase

@end

@implementation AppRatingUtilityTests

- (void)setUp {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
    [AppRatingUtility initializeForVersion:@"1.0"];
    [AppRatingUtility setSystemWideSignificantEventsCount:1];
    [super setUp];
}

- (void)tearDown {
    // A hack to reset everything
    [AppRatingUtility initializeForVersion:@"10.0"];
    [AppRatingUtility unregisterAllSections];
    [super tearDown];
}

- (void)testCheckForPromptReturnsFalseWithoutEnoughSignificantEvents
{
    [AppRatingUtility setSystemWideSignificantEventsCount:1];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview]);
}

- (void)testCheckForPromptReturnsTrueWithEnoughSignificantEvents
{
    [AppRatingUtility setSystemWideSignificantEventsCount:1];
    [AppRatingUtility incrementSignificantEvent];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReview]);
}

- (void)createConditionsForPositiveAppReviewPrompt
{
    [AppRatingUtility setSystemWideSignificantEventsCount:1];
    [AppRatingUtility incrementSignificantEvent];
}

- (void)testCheckForPromptReturnsFalseIfUserHasRatedCurrentVersion
{
    [self createConditionsForPositiveAppReviewPrompt];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReview]);
    [AppRatingUtility ratedCurrentVersion];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview]);
}

- (void)testCheckForPromptReturnsFalseIfUserHasGivenFeedbackForCurrentVersion
{
    [self createConditionsForPositiveAppReviewPrompt];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReview]);
    [AppRatingUtility gaveFeedbackForCurrentVersion];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview]);
}

- (void)testCheckForPromptReturnsFalseIfUserHasDeclinedToRateCurrentVersion
{
    [self createConditionsForPositiveAppReviewPrompt];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReview]);
    [AppRatingUtility declinedToRateCurrentVersion];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview]);
}

- (void)testCheckForPromptShouldResetForNewVersion
{
    [self createConditionsForPositiveAppReviewPrompt];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReview]);
    [AppRatingUtility initializeForVersion:@"2.0"];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview]);
}

- (void)testCheckForPromptShouldTriggerWithNewVersion
{
    [self createConditionsForPositiveAppReviewPrompt];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReview]);
    [AppRatingUtility initializeForVersion:@"2.0"];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview]);
    [self createConditionsForPositiveAppReviewPrompt];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReview]);
}

- (void)testUserIsNotPromptedForAReviewForOneVersionIfTheyLikedTheApp;
{
    [AppRatingUtility initializeForVersion:@"4.7"];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview]);
    [AppRatingUtility likedCurrentVersion];
    
    [AppRatingUtility initializeForVersion:@"4.8"];
    [AppRatingUtility incrementSignificantEvent];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview], @"should not prompt for a review after liking last version");
    
    [AppRatingUtility initializeForVersion:@"4.9"];
    [AppRatingUtility incrementSignificantEvent];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReview], @"should prompt for a review after skipping a version");
}

- (void)testUserIsNotPromptedForAReviewForTwoVersionsIfTheyDeclineToRate
{
    [AppRatingUtility initializeForVersion:@"4.7"];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview]);
    [AppRatingUtility dislikedCurrentVersion];
    
    [AppRatingUtility initializeForVersion:@"4.8"];
    [AppRatingUtility incrementSignificantEvent];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview], @"should not prompt for a review after declining on this first upgrade");
    
    [AppRatingUtility initializeForVersion:@"4.9"];
    [AppRatingUtility incrementSignificantEvent];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview], @"should not prompt for a review after declining on this second upgrade");
    
    [AppRatingUtility initializeForVersion:@"5.0"];
    [AppRatingUtility incrementSignificantEvent];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReview], @"should prompt for a review two versions later");
}

- (void)testHasUserEverLikedApp
{
    [AppRatingUtility initializeForVersion:@"4.7"];
    XCTAssertFalse([AppRatingUtility hasUserEverLikedApp]);
    [AppRatingUtility declinedToRateCurrentVersion];
    
    [AppRatingUtility initializeForVersion:@"4.8"];
    XCTAssertFalse([AppRatingUtility hasUserEverLikedApp]);
    [AppRatingUtility likedCurrentVersion];
    XCTAssertTrue([AppRatingUtility hasUserEverLikedApp]);
    
    [AppRatingUtility initializeForVersion:@"4.9"];
    [AppRatingUtility dislikedCurrentVersion];
    XCTAssertTrue([AppRatingUtility hasUserEverLikedApp]);
}

- (void)testHasUserEverDislikedTheApp
{
    [AppRatingUtility initializeForVersion:@"4.7"];
    XCTAssertFalse([AppRatingUtility hasUserEverDislikedApp]);
    [AppRatingUtility declinedToRateCurrentVersion];
    
    [AppRatingUtility initializeForVersion:@"4.8"];
    XCTAssertFalse([AppRatingUtility hasUserEverDislikedApp]);
    [AppRatingUtility dislikedCurrentVersion];
    XCTAssertTrue([AppRatingUtility hasUserEverDislikedApp]);
    
    [AppRatingUtility initializeForVersion:@"4.9"];
    [AppRatingUtility likedCurrentVersion];
    XCTAssertTrue([AppRatingUtility hasUserEverDislikedApp]);
}

- (void)testShouldPromptForAppReviewForSection
{
    [AppRatingUtility registerSection:@"Notifications" withSignificantEventCount:2];
    [AppRatingUtility initializeForVersion:@"4.7"];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReviewForSection:@"Notifications"]);
    [AppRatingUtility incrementSignificantEventForSection:@"Notifications"];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReviewForSection:@"Notifications"]);
    [AppRatingUtility incrementSignificantEventForSection:@"Notifications"];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReviewForSection:@"Notifications"]);
}

- (void)testShouldPromptAppReviewSystemWideWithEnoughSmallerSignficantEvents
{
    [AppRatingUtility registerSection:@"Notifications" withSignificantEventCount:2];
    [AppRatingUtility registerSection:@"Editor" withSignificantEventCount:2];
    [AppRatingUtility setSystemWideSignificantEventsCount:3];
    [AppRatingUtility initializeForVersion:@"4.7"];
    
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReviewForSection:@"Notifications"]);
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReviewForSection:@"Editor"]);
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview]);
    
    [AppRatingUtility incrementSignificantEventForSection:@"Notifications"];
    [AppRatingUtility incrementSignificantEventForSection:@"Editor"];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview]);
    
    [AppRatingUtility incrementSignificantEventForSection:@"Editor"];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReview]);
}

- (void)testShouldPromptForAppReviewSystemWideWithEnoughSmallerSignificantEventsIncludingNonSectionedEvents
{
    [AppRatingUtility registerSection:@"Notifications" withSignificantEventCount:2];
    [AppRatingUtility registerSection:@"Editor" withSignificantEventCount:2];
    [AppRatingUtility setSystemWideSignificantEventsCount:3];
    [AppRatingUtility initializeForVersion:@"4.7"];
    
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReviewForSection:@"Notifications"]);
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReviewForSection:@"Editor"]);
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview]);
    
    [AppRatingUtility incrementSignificantEventForSection:@"Notifications"];
    [AppRatingUtility incrementSignificantEventForSection:@"Editor"];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview]);
    
    [AppRatingUtility incrementSignificantEvent];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReview]);
}

@end
