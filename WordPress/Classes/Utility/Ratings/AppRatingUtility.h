#import <Foundation/Foundation.h>

// Based loosely on Appirater (https://github.com/arashpayan/appirater)

@interface AppRatingUtility : NSObject

+ (void)initializeForVersion:(NSString *)version;
+ (void)registerSection:(NSString *)section withSignificantEventCount:(NSUInteger)significantEventCount;

+ (void)incrementSignificantEvent;
+ (void)incrementSignificantEventForSection:(NSString *)section;
+ (void)setSystemWideSignificantEventsCount:(NSUInteger)numberOfEvents;

+ (void)declinedToRateCurrentVersion;
+ (void)gaveFeedbackForCurrentVersion;
+ (void)ratedCurrentVersion;
+ (void)dislikedCurrentVersion;
+ (void)likedCurrentVersion;

+ (BOOL)shouldPromptForAppReview;
+ (BOOL)shouldPromptForAppReviewForSection:(NSString *)section;
+ (BOOL)hasUserEverLikedApp;
+ (BOOL)hasUserEverDislikedApp;

@end
