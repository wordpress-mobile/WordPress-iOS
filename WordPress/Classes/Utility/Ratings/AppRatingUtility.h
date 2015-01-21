#import <Foundation/Foundation.h>

typedef void (^AppRatingCompletionBlock)();

/**
 This class will help track whether or not a user should be prompted for an app 
 review. This class is loosely based on Appirater 
 (https://github.com/arashpayan/appirater)
 */
@interface AppRatingUtility : NSObject

/**
 *  This should be called with the current App Version so as to setup internal 
    tracking.
 *
 *  @param version version number of the app, e.g. CFBundleShortVersionString
 */
+ (void)initializeForVersion:(NSString *)version;

/**
 *  This checks if we've disabled app review prompts for a feature or at a 
    global level
 *
 *  @param success called on successfully retrieving the details
 *  @param failure called when we were unable to retrieve the details
 */
+ (void)checkIfAppReviewPromptsHaveBeenDisabled:(AppRatingCompletionBlock)success failure:(AppRatingCompletionBlock)failure;

/**
 *  Registers a granular section to be tracked.
 *
 *  @param section               section name, e.g. "Notifications"
 *  @param significantEventCount the number of significant events required to trigger an app rating prompt for this particular section
 */
+ (void)registerSection:(NSString *)section withSignificantEventCount:(NSUInteger)significantEventCount;

/**
 *  Increments significant events app wide
 */
+ (void)incrementSignificantEvent;

/**
 *  Increments significant events for just this particular section
 *
 *  @param section section name, e.g. "Notifications"
 */
+ (void)incrementSignificantEventForSection:(NSString *)section;

/**
 *  Sets the number of system wide significant events are required when calling `shouldPromptForAppReview`. Ideally this number should be a number less 
    than the total of all the signficant event counts for each section so as to
    trigger the review prompt for a fairly active user who uses the app in a 
    broad fashion.
 *
 *  @param numberOfEvents number of events required to trigger the generic check for an app review.
 */
+ (void)setSystemWideSignificantEventsCount:(NSUInteger)numberOfEvents;

/**
 *  Indicates that the user didn't want to review the app or leave feedback for 
    this version.
 */
+ (void)declinedToRateCurrentVersion;

/**
 *  Indicates that the user decided to give feedback for this version.
 */
+ (void)gaveFeedbackForCurrentVersion;

/**
 *  Indicates the the use rated the current version of the app.
 */
+ (void)ratedCurrentVersion;

/**
 *  Indicates that the user didn't like the current version of the app.
 */
+ (void)dislikedCurrentVersion;

/**
 *  Indicates the user did like the current version of the app.
 */
+ (void)likedCurrentVersion;

/**
 *  Checks if the user should be prompted for an app review based on `systemWideSignificantEventsCount` and also if the user hasn't been
    configured to skip being prompted for this release.  Note that this method 
    will check to see if app review prompts on a global basis have been shut 
    off.
 *
 *  @return returns true when the user has performed enough significant events and isn't configured to skip being prompted for this release.
 */
+ (BOOL)shouldPromptForAppReview;

/**
 *  Checks if the user should be prompted for an app review based on the number 
    of significant events configured for this particular section and if the user 
    hasn't been configured to skip being prompted for this release. Note that 
    this method will check to see if prompts for this section have been shut 
    off entirely.
 *
 *  @param section section name, e.g. "Notifications"
 *
 *  @return returns true when the user has performed enough significant events for this section and isn't configured to skip being prompted for this release.
 */
+ (BOOL)shouldPromptForAppReviewForSection:(NSString *)section;

/**
 *  Checks if the user has ever indicated that they like the app.
 *
 *  @return true if the user has ever indicated they like the app.
 */
+ (BOOL)hasUserEverLikedApp;

/**
 *  Checks if the user has ever indicated they dislike the app.
 *
 *  @return true if the user has ever indicated they don't like the app.
 */
+ (BOOL)hasUserEverDislikedApp;

@end
