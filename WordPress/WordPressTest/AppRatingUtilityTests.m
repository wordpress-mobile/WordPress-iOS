#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "AppRatingUtility.h"
#import <OHHTTPStubs/OHHTTPStubs.h>

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
    [AppRatingUtility registerSection:@"notifications" withSignificantEventCount:2];
    [AppRatingUtility initializeForVersion:@"4.7"];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReviewForSection:@"notifications"]);
    [AppRatingUtility incrementSignificantEventForSection:@"notifications"];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReviewForSection:@"notifications"]);
    [AppRatingUtility incrementSignificantEventForSection:@"notifications"];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReviewForSection:@"notifications"]);
}

- (void)testShouldPromptAppReviewSystemWideWithEnoughSmallerSignficantEvents
{
    [AppRatingUtility registerSection:@"notifications" withSignificantEventCount:2];
    [AppRatingUtility registerSection:@"editor" withSignificantEventCount:2];
    [AppRatingUtility setSystemWideSignificantEventsCount:3];
    [AppRatingUtility initializeForVersion:@"4.7"];
    
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReviewForSection:@"notifications"]);
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReviewForSection:@"editor"]);
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview]);
    
    [AppRatingUtility incrementSignificantEventForSection:@"notifications"];
    [AppRatingUtility incrementSignificantEventForSection:@"editor"];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview]);
    
    [AppRatingUtility incrementSignificantEventForSection:@"editor"];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReview]);
}

- (void)testShouldPromptForAppReviewSystemWideWithEnoughSmallerSignificantEventsIncludingNonSectionedEvents
{
    [AppRatingUtility registerSection:@"notifications" withSignificantEventCount:2];
    [AppRatingUtility registerSection:@"editor" withSignificantEventCount:2];
    [AppRatingUtility setSystemWideSignificantEventsCount:3];
    [AppRatingUtility initializeForVersion:@"4.7"];
    
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReviewForSection:@"notifications"]);
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReviewForSection:@"editor"]);
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview]);
    
    [AppRatingUtility incrementSignificantEventForSection:@"notifications"];
    [AppRatingUtility incrementSignificantEventForSection:@"editor"];
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReview]);
    
    [AppRatingUtility incrementSignificantEvent];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReview]);
}

- (void)testAppReviewPromptRemoteDisableWhenRemoteCheckIndicatesEverythingIsEnabled
{
    [AppRatingUtility registerSection:@"notifications" withSignificantEventCount:1];
    [AppRatingUtility initializeForVersion:@"4.7"];
    [AppRatingUtility incrementSignificantEventForSection:@"notifications"];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReviewForSection:@"notifications"]);
    
    [self stubAppReviewCheckWithFile:@"app-review-prompt-all-enabled.json"];
    XCTestExpectation *testExpectation = [self expectationWithDescription:@"remote check"];
    [AppRatingUtility checkIfAppReviewPromptsHaveBeenDisabled:^{
        [testExpectation fulfill];
    } failure:^{
        [NSException raise:@"Error" format:@"Shouldn't get here..."];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    // We shouldn't disable the check when the remote check indicates everything is enabled
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReviewForSection:@"notifications"]);
}

- (void)testAppReviewPromptRemoteDisableWhenRemoteCheckIndicatesNotificationsAreDisabled
{
    [AppRatingUtility registerSection:@"notifications" withSignificantEventCount:1];
    [AppRatingUtility initializeForVersion:@"4.7"];
    [AppRatingUtility incrementSignificantEventForSection:@"notifications"];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReviewForSection:@"notifications"]);
    
    [self stubAppReviewCheckWithFile:@"app-review-prompt-notifications-disabled.json"];
    XCTestExpectation *testExpectation = [self expectationWithDescription:@"remote check"];
    [AppRatingUtility checkIfAppReviewPromptsHaveBeenDisabled:^{
        [testExpectation fulfill];
    } failure:^{
        [NSException raise:@"Error" format:@"Shouldn't get here..."];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    // We should disable the check when the remote check indicates notifications is disabled
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReviewForSection:@"notifications"]);
}

- (void)testAppReviewPromptRemoteDisableWhenRemoteCheckIndicatesEverythingIsDisabled
{
    [AppRatingUtility registerSection:@"notifications" withSignificantEventCount:1];
    [AppRatingUtility initializeForVersion:@"4.7"];
    [AppRatingUtility incrementSignificantEventForSection:@"notifications"];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReviewForSection:@"notifications"]);
    
    [self stubAppReviewCheckWithFile:@"app-review-prompt-global-disable.json"];
    XCTestExpectation *testExpectation = [self expectationWithDescription:@"remote check"];
    [AppRatingUtility checkIfAppReviewPromptsHaveBeenDisabled:^{
        [testExpectation fulfill];
    } failure:^{
        [NSException raise:@"Error" format:@"Shouldn't get here..."];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    // We should disable the check when the remote check indicates notifications is disabled
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReviewForSection:@"notifications"]);
}

- (void)testAppReviewPromptRemoteDisableForGlobalPromptWhenRemoteCheckIndicatesEverythingIsDisabled
{
    [AppRatingUtility registerSection:@"notifications" withSignificantEventCount:1];
    [AppRatingUtility setSystemWideSignificantEventsCount:2];
    [AppRatingUtility initializeForVersion:@"4.7"];
    [AppRatingUtility incrementSignificantEventForSection:@"notifications"];
    [AppRatingUtility incrementSignificantEvent];
    XCTAssertTrue([AppRatingUtility shouldPromptForAppReview]);
    
    [self stubAppReviewCheckWithFile:@"app-review-prompt-global-disable.json"];
    XCTestExpectation *testExpectation = [self expectationWithDescription:@"remote check"];
    [AppRatingUtility checkIfAppReviewPromptsHaveBeenDisabled:^{
        [testExpectation fulfill];
    } failure:^{
        [NSException raise:@"Error" format:@"Shouldn't get here..."];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    // We should disable the check when the remote check indicates notifications is disabled
    XCTAssertFalse([AppRatingUtility shouldPromptForAppReviewForSection:@"notifications"]);
}

- (void)stubAppReviewCheckWithFile:(NSString *)file
{
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] containsString:@"app-review-prompt-check"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFile:file contentType:@"application/json" responseTime:OHHTTPStubsDownloadSpeedWifi];
    }];
}

@end
