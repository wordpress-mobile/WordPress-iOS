#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "AppRatingUtility.h"

@interface AppRatingUtilityTests : XCTestCase

@end

@implementation AppRatingUtilityTests

- (void)setUp {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
    [AppRatingUtility initializeForVersion:@"1.0"];
    [AppRatingUtility setNumberOfSignificantEventsRequiredForPrompt:1];
    [super setUp];
}

- (void)tearDown {
    // A hack to reset everything
    [AppRatingUtility initializeForVersion:@"10.0"];
    [super tearDown];
}

- (void)testCheckForPromptReturnsFalseWithoutEnoughSignificantEvents
{
    [AppRatingUtility setNumberOfSignificantEventsRequiredForPrompt:1];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview]);
}

- (void)testCheckForPromptReturnsTrueWithEnoughSignificantEvents
{
    [AppRatingUtility setNumberOfSignificantEventsRequiredForPrompt:1];
    [AppRatingUtility incrementSignificantEvent];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReview]);
}

- (void)createConditionsForPositiveAppReviewPrompt
{
    [AppRatingUtility setNumberOfSignificantEventsRequiredForPrompt:1];
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

@end
