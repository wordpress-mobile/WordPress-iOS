#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "AppRatingUtility.h"

@interface AppRatingUtilityTests : XCTestCase

@end

@implementation AppRatingUtilityTests

- (void)setUp {
    [AppRatingUtility initializeForVersion:@"1.0"];
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

@end
