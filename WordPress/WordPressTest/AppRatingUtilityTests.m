@import XCTest;
@import OHHTTPStubs;
@import OHHTTPStubs.OHPathHelpers;

#import "WordPress-Swift.h"

@interface AppRatingUtility(Tests)

+ (void)unregisterAllSections;

@end

@interface AppRatingUtilityTests : XCTestCase
@property (nonatomic, strong) NSUserDefaults *defaults;
@property (nonatomic, strong) AppRatingUtility *utility;
@end

@implementation AppRatingUtilityTests

- (void)setUp {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];

    self.defaults = [NSUserDefaults new];
    self.utility = [[AppRatingUtility alloc] initWithDefaults:self.defaults];
    [self.utility setVersion:@"1.0"];
    self.utility.systemWideSignificantEventCountRequiredForPrompt = 1;

    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testCheckForPromptReturnsFalseWithoutEnoughSignificantEvents
{
    [self.utility setSystemWideSignificantEventCountRequiredForPrompt:1];
    XCTAssertFalse([self.utility shouldPromptForAppReview]);
}

- (void)testCheckForPromptReturnsTrueWithEnoughSignificantEvents
{
    [self.utility setSystemWideSignificantEventCountRequiredForPrompt:1];
    [self.utility incrementSignificantEvent];
    XCTAssertTrue([self.utility shouldPromptForAppReview]);
}

- (void)createConditionsForPositiveAppReviewPrompt
{
    [self.utility setSystemWideSignificantEventCountRequiredForPrompt:1];
    [self.utility incrementSignificantEvent];
}

- (void)testCheckForPromptReturnsFalseIfUserHasRatedCurrentVersion
{
    [self createConditionsForPositiveAppReviewPrompt];
    XCTAssertTrue([self.utility shouldPromptForAppReview]);
    [self.utility ratedCurrentVersion];
    XCTAssertFalse([self.utility shouldPromptForAppReview]);
}

- (void)testCheckForPromptReturnsFalseIfUserHasGivenFeedbackForCurrentVersion
{
    [self createConditionsForPositiveAppReviewPrompt];
    XCTAssertTrue([self.utility shouldPromptForAppReview]);
    [self.utility gaveFeedbackForCurrentVersion];
    XCTAssertFalse([self.utility shouldPromptForAppReview]);
}

- (void)testCheckForPromptReturnsFalseIfUserHasDeclinedToRateCurrentVersion
{
    [self createConditionsForPositiveAppReviewPrompt];
    XCTAssertTrue([self.utility shouldPromptForAppReview]);
    [self.utility declinedToRateCurrentVersion];
    XCTAssertFalse([self.utility shouldPromptForAppReview]);
}

- (void)testCheckForPromptShouldResetForNewVersion
{
    [self createConditionsForPositiveAppReviewPrompt];
    XCTAssertTrue([self.utility shouldPromptForAppReview]);
    [self.utility setVersion:@"2.0"];
    XCTAssertFalse([self.utility shouldPromptForAppReview]);
}

- (void)testCheckForPromptShouldTriggerWithNewVersion
{
    [self createConditionsForPositiveAppReviewPrompt];
    XCTAssertTrue([self.utility shouldPromptForAppReview]);
    [self.utility setVersion:@"2.0"];
    XCTAssertFalse([self.utility shouldPromptForAppReview]);
    [self createConditionsForPositiveAppReviewPrompt];
    XCTAssertTrue([self.utility shouldPromptForAppReview]);
}

- (void)testUserIsNotPromptedForAReviewForOneVersionIfTheyLikedTheApp;
{
    [self.utility setVersion:@"4.7"];
    XCTAssertFalse([self.utility shouldPromptForAppReview]);
    [self.utility likedCurrentVersion];
    
    [self.utility setVersion:@"4.8"];
    [self.utility incrementSignificantEvent];
    XCTAssertFalse([self.utility shouldPromptForAppReview], @"should not prompt for a review after liking last version");
    
    [self.utility setVersion:@"4.9"];
    [self.utility incrementSignificantEvent];
    XCTAssertTrue([self.utility shouldPromptForAppReview], @"should prompt for a review after skipping a version");
}

- (void)testUserIsNotPromptedForAReviewForTwoVersionsIfTheyDeclineToRate
{
    [self.utility setVersion:@"4.7"];
    XCTAssertFalse([self.utility shouldPromptForAppReview]);
    [self.utility dislikedCurrentVersion];
    
    [self.utility setVersion:@"4.8"];
    [self.utility incrementSignificantEvent];
    XCTAssertFalse([self.utility shouldPromptForAppReview], @"should not prompt for a review after declining on this first upgrade");
    
    [self.utility setVersion:@"4.9"];
    [self.utility incrementSignificantEvent];
    XCTAssertFalse([self.utility shouldPromptForAppReview], @"should not prompt for a review after declining on this second upgrade");
    
    [self.utility setVersion:@"5.0"];
    [self.utility incrementSignificantEvent];
    XCTAssertTrue([self.utility shouldPromptForAppReview], @"should prompt for a review two versions later");
}

- (void)testHasUserEverLikedApp
{
    [self.utility setVersion:@"4.7"];
    XCTAssertFalse([self.utility hasUserEverLikedApp]);
    [self.utility declinedToRateCurrentVersion];
    
    [self.utility setVersion:@"4.8"];
    XCTAssertFalse([self.utility hasUserEverLikedApp]);
    [self.utility likedCurrentVersion];
    XCTAssertTrue([self.utility hasUserEverLikedApp]);
    
    [self.utility setVersion:@"4.9"];
    [self.utility dislikedCurrentVersion];
    XCTAssertTrue([self.utility hasUserEverLikedApp]);
}

- (void)testHasUserEverDislikedTheApp
{
    [self.utility setVersion:@"4.7"];
    XCTAssertFalse([self.utility hasUserEverDislikedApp]);
    [self.utility declinedToRateCurrentVersion];
    
    [self.utility setVersion:@"4.8"];
    XCTAssertFalse([self.utility hasUserEverDislikedApp]);
    [self.utility dislikedCurrentVersion];
    XCTAssertTrue([self.utility hasUserEverDislikedApp]);
    
    [self.utility setVersion:@"4.9"];
    [self.utility likedCurrentVersion];
    XCTAssertTrue([self.utility hasUserEverDislikedApp]);
}

- (void)testShouldPromptForAppReviewForSection
{
    [self.utility registerSection:@"notifications" withSignificantEventCount:2];
    [self.utility setVersion:@"4.7"];
    XCTAssertFalse([self.utility shouldPromptForAppReviewForSection:@"notifications"]);
    [self.utility incrementSignificantEventForSection:@"notifications"];
    XCTAssertFalse([self.utility shouldPromptForAppReviewForSection:@"notifications"]);
    [self.utility incrementSignificantEventForSection:@"notifications"];
    XCTAssertTrue([self.utility shouldPromptForAppReviewForSection:@"notifications"]);
}

- (void)testShouldPromptAppReviewSystemWideWithEnoughSmallerSignficantEvents
{
    [self.utility registerSection:@"notifications" withSignificantEventCount:2];
    [self.utility registerSection:@"editor" withSignificantEventCount:2];
    [self.utility setSystemWideSignificantEventCountRequiredForPrompt:3];
    [self.utility setVersion:@"4.7"];
    
    XCTAssertFalse([self.utility shouldPromptForAppReviewForSection:@"notifications"]);
    XCTAssertFalse([self.utility shouldPromptForAppReviewForSection:@"editor"]);
    XCTAssertFalse([self.utility shouldPromptForAppReview]);
    
    [self.utility incrementSignificantEventForSection:@"notifications"];
    [self.utility incrementSignificantEventForSection:@"editor"];
    XCTAssertFalse([self.utility shouldPromptForAppReview]);
    
    [self.utility incrementSignificantEventForSection:@"editor"];
    XCTAssertTrue([self.utility shouldPromptForAppReview]);
}

- (void)testShouldPromptForAppReviewSystemWideWithEnoughSmallerSignificantEventsIncludingNonSectionedEvents
{
    [self.utility registerSection:@"notifications" withSignificantEventCount:2];
    [self.utility registerSection:@"editor" withSignificantEventCount:2];
    [self.utility setSystemWideSignificantEventCountRequiredForPrompt:3];
    [self.utility setVersion:@"4.7"];
    
    XCTAssertFalse([self.utility shouldPromptForAppReviewForSection:@"notifications"]);
    XCTAssertFalse([self.utility shouldPromptForAppReviewForSection:@"editor"]);
    XCTAssertFalse([self.utility shouldPromptForAppReview]);
    
    [self.utility incrementSignificantEventForSection:@"notifications"];
    [self.utility incrementSignificantEventForSection:@"editor"];
    XCTAssertFalse([self.utility shouldPromptForAppReview]);
    
    [self.utility incrementSignificantEvent];
    XCTAssertTrue([self.utility shouldPromptForAppReview]);
}

- (void)testAppReviewPromptRemoteDisableWhenRemoteCheckIndicatesEverythingIsEnabled
{
    [self.utility registerSection:@"notifications" withSignificantEventCount:1];
    [self.utility setVersion:@"4.7"];
    [self.utility incrementSignificantEventForSection:@"notifications"];
    XCTAssertTrue([self.utility shouldPromptForAppReviewForSection:@"notifications"]);
    
    [self stubAppReviewCheckWithFile:@"app-review-prompt-all-enabled.json"];
    XCTestExpectation *testExpectation = [self expectationWithDescription:@"remote check"];
    [self.utility checkIfAppReviewPromptsHaveBeenDisabledWithSuccess:^{
        [testExpectation fulfill];
    } failure:^{
        [NSException raise:@"Error" format:@"Shouldn't get here..."];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    // We shouldn't disable the check when the remote check indicates everything is enabled
    XCTAssertTrue([self.utility shouldPromptForAppReviewForSection:@"notifications"]);
}

- (void)testAppReviewPromptRemoteDisableWhenRemoteCheckIndicatesNotificationsAreDisabled
{
    [self.utility registerSection:@"notifications" withSignificantEventCount:1];
    [self.utility setVersion:@"4.7"];
    [self.utility incrementSignificantEventForSection:@"notifications"];
    XCTAssertTrue([self.utility shouldPromptForAppReviewForSection:@"notifications"]);
    
    [self stubAppReviewCheckWithFile:@"app-review-prompt-notifications-disabled.json"];
    XCTestExpectation *testExpectation = [self expectationWithDescription:@"remote check"];
    [self.utility checkIfAppReviewPromptsHaveBeenDisabledWithSuccess:^{
        [testExpectation fulfill];
    } failure:^{
        [NSException raise:@"Error" format:@"Shouldn't get here..."];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    // We should disable the check when the remote check indicates notifications is disabled
    XCTAssertFalse([self.utility shouldPromptForAppReviewForSection:@"notifications"]);
}

- (void)testAppReviewPromptRemoteDisableWhenRemoteCheckIndicatesEverythingIsDisabled
{
    [self.utility registerSection:@"notifications" withSignificantEventCount:1];
    [self.utility setVersion:@"4.7"];
    [self.utility incrementSignificantEventForSection:@"notifications"];
    XCTAssertTrue([self.utility shouldPromptForAppReviewForSection:@"notifications"]);
    
    [self stubAppReviewCheckWithFile:@"app-review-prompt-global-disable.json"];
    XCTestExpectation *testExpectation = [self expectationWithDescription:@"remote check"];
    [self.utility checkIfAppReviewPromptsHaveBeenDisabledWithSuccess:^{
        [testExpectation fulfill];
    } failure:^{
        [NSException raise:@"Error" format:@"Shouldn't get here..."];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    // We should disable the check when the remote check indicates notifications is disabled
    XCTAssertFalse([self.utility shouldPromptForAppReviewForSection:@"notifications"]);
}

- (void)testAppReviewPromptRemoteDisableForGlobalPromptWhenRemoteCheckIndicatesEverythingIsDisabled
{
    [self.utility registerSection:@"notifications" withSignificantEventCount:1];
    [self.utility setSystemWideSignificantEventCountRequiredForPrompt:2];
    [self.utility setVersion:@"4.7"];
    [self.utility incrementSignificantEventForSection:@"notifications"];
    [self.utility incrementSignificantEvent];
    XCTAssertTrue([self.utility shouldPromptForAppReview]);
    
    [self stubAppReviewCheckWithFile:@"app-review-prompt-global-disable.json"];
    XCTestExpectation *testExpectation = [self expectationWithDescription:@"remote check"];
    [self.utility checkIfAppReviewPromptsHaveBeenDisabledWithSuccess:^{
        [testExpectation fulfill];
    } failure:^{
        [NSException raise:@"Error" format:@"Shouldn't get here..."];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    // We should disable the check when the remote check indicates notifications is disabled
    XCTAssertFalse([self.utility shouldPromptForAppReviewForSection:@"notifications"]);
}

- (void)stubAppReviewCheckWithFile:(NSString *)file
{
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] containsString:@"app-review-prompt-check"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString* fixture = OHPathForFile(file, self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:fixture
                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];
}

@end
