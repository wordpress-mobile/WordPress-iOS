#import "AppRatingUtility.h"

@implementation AppRatingUtility

NSString *const AppRatingCurrentVersion = @"AppRatingCurrentVersion";
NSString *const AppRatingNumberOfSignificantEventsRequiredForPrompt = @"AppRatingNumberOfSignificantEventsRequiredForPrompt";
NSString *const AppRatingSignificantEventCount = @"AppRatingSignificantEventCount";
NSString *const AppRatingUseCount = @"AppRatingUseCount";
NSString *const AppRatingNumberOfVersionsSkippedPrompting = @"AppRatingsNumberOfVersionsSkippedPrompt";
NSString *const AppRatingNumberOfVersionsToSkipPrompting = @"AppRatingsNumberOfVersionsToSkipPrompting";
NSString *const AppRatingRatedCurrentVersion = @"AppRatingRatedCurrentVersion";
NSString *const AppRatingDeclinedToRateCurrentVersion = @"AppRatingDeclinedToRateCurrentVersion";
NSString *const AppRatingGaveFeedbackForCurrentVersion = @"AppRatingGaveFeedbackForCurrentVersion";
NSString *const AppRatingDislikedCurrentVersion = @"AppRatingDislikedCurrentVersion";
NSString *const AppRatingLikedCurrentVersion = @"AppRatingLikedCurrentVersion";
NSString *const AppRatingUserLikeCount = @"AppRatingUserLikeCount";
NSString *const AppRatingUserDislikeCount = @"AppRatingUserDislikeCount";

+ (BOOL)shouldPromptForAppReview
{
    if ([self interactedWithAppReviewPrompt]) {
        return NO;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSUInteger significantEventCount = [userDefaults integerForKey:AppRatingSignificantEventCount];
    NSUInteger numberOfSignificantEventsRequiredForPrompt = [userDefaults integerForKey:AppRatingNumberOfSignificantEventsRequiredForPrompt];
    
    if (significantEventCount >= numberOfSignificantEventsRequiredForPrompt) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)interactedWithAppReviewPrompt
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:AppRatingRatedCurrentVersion] || [userDefaults boolForKey:AppRatingDeclinedToRateCurrentVersion] || [userDefaults boolForKey:AppRatingGaveFeedbackForCurrentVersion] || [userDefaults boolForKey:AppRatingLikedCurrentVersion] || [userDefaults boolForKey:AppRatingDislikedCurrentVersion];
}

+ (void)initializeForVersion:(NSString *)version
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *trackingVersion = [userDefaults stringForKey:AppRatingCurrentVersion];
    if (trackingVersion == nil)
    {
        trackingVersion = version;
        [userDefaults setObject:version forKey:AppRatingCurrentVersion];
    }
    
    if ([trackingVersion isEqualToString:version])
    {
        // increment the use count
        NSInteger useCount = [userDefaults integerForKey:AppRatingUseCount];
        useCount++;
        [userDefaults setInteger:useCount forKey:AppRatingUseCount];
    }
    else
    {
        // Restarting tracking for new version of app
        
        BOOL interactedWithAppReviewPromptInPreviousVersion = [self interactedWithAppReviewPrompt];
        
        [userDefaults setObject:version forKey:AppRatingCurrentVersion];
        [userDefaults setInteger:0 forKey:AppRatingSignificantEventCount];
        [userDefaults setBool:NO forKey:AppRatingRatedCurrentVersion];
        [userDefaults setBool:NO forKey:AppRatingDeclinedToRateCurrentVersion];
        [userDefaults setBool:NO forKey:AppRatingGaveFeedbackForCurrentVersion];
        [userDefaults setBool:NO forKey:AppRatingDislikedCurrentVersion];
        [userDefaults setBool:NO forKey:AppRatingLikedCurrentVersion];
        
        if (interactedWithAppReviewPromptInPreviousVersion) {
            NSInteger numberOfVersionsSkippedPrompting = [userDefaults integerForKey:AppRatingNumberOfVersionsSkippedPrompting];
            NSInteger numberOfVersionsToSkipPrompting = [userDefaults integerForKey:AppRatingNumberOfVersionsToSkipPrompting];
            
            if (numberOfVersionsToSkipPrompting > 0) {
                if (numberOfVersionsSkippedPrompting < numberOfVersionsToSkipPrompting) {
                    // We haven't skipped enough versions, skip this one
                    numberOfVersionsSkippedPrompting++;
                    [userDefaults setInteger:numberOfVersionsSkippedPrompting forKey:AppRatingNumberOfVersionsSkippedPrompting];
                    [userDefaults setBool:YES forKey:AppRatingRatedCurrentVersion];
                } else {
                    // We have skipped enough, reset data
                    [userDefaults setInteger:0 forKey:AppRatingNumberOfVersionsSkippedPrompting];
                    [userDefaults setInteger:0 forKey:AppRatingNumberOfVersionsToSkipPrompting];
                }
            }
        }
    }
}

+ (void)incrementSignificantEvent
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger numberOfSignificantEvents = [userDefaults integerForKey:AppRatingSignificantEventCount];
    numberOfSignificantEvents++;
    [userDefaults setInteger:numberOfSignificantEvents forKey:AppRatingSignificantEventCount];
    [userDefaults synchronize];
}

+ (void)setNumberOfSignificantEventsRequiredForPrompt:(NSUInteger)numberOfEvents
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:numberOfEvents forKey:AppRatingNumberOfSignificantEventsRequiredForPrompt];
    [userDefaults synchronize];
}

+ (void)declinedToRateCurrentVersion
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:YES forKey:AppRatingDeclinedToRateCurrentVersion];
    [userDefaults setInteger:2 forKey:AppRatingNumberOfVersionsToSkipPrompting];
    [userDefaults synchronize];
}

+ (void)gaveFeedbackForCurrentVersion
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:YES forKey:AppRatingGaveFeedbackForCurrentVersion];
    [userDefaults synchronize];
}

+ (void)ratedCurrentVersion
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:YES forKey:AppRatingRatedCurrentVersion];
    [userDefaults synchronize];
}

+ (void)dislikedCurrentVersion
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSUInteger userDislikeCount = [userDefaults integerForKey:AppRatingUserDislikeCount];
    userDislikeCount++;
    [userDefaults setInteger:userDislikeCount forKey:AppRatingUserDislikeCount];
    [userDefaults setBool:YES forKey:AppRatingDislikedCurrentVersion];
    [userDefaults setInteger:2 forKey:AppRatingNumberOfVersionsToSkipPrompting];
    [userDefaults synchronize];
}

+ (void)likedCurrentVersion
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSUInteger userLikeCount = [userDefaults integerForKey:AppRatingUserLikeCount];
    userLikeCount++;
    [userDefaults setInteger:userLikeCount forKey:AppRatingUserLikeCount];
    [userDefaults setBool:YES forKey:AppRatingLikedCurrentVersion];
    [userDefaults setInteger:1 forKey:AppRatingNumberOfVersionsToSkipPrompting];
    [userDefaults synchronize];
}

+ (BOOL)hasUserEverLikedApp
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:AppRatingUserLikeCount] > 0;
}

+ (BOOL)hasUserEverDislikedApp
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:AppRatingUserDislikeCount] > 0;
}

@end
