#import <Foundation/Foundation.h>

// Based loosely on Appirater (https://github.com/arashpayan/appirater)

@interface AppRatingUtility : NSObject

+ (BOOL)shouldPromptForAppReview;
+ (void)initializeForVersion:(NSString *)version;
+ (void)incrementSignificantEvent;
+ (void)setNumberOfSignificantEventsRequiredForPrompt:(NSUInteger)numberOfEvents;
+ (void)declinedToRateCurrentVersion;
+ (void)gaveFeedbackForCurrentVersion;
+ (void)ratedCurrentVersion;

@end
