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
NSString *const AppRatingDidntLikeCurrentVersion = @"AppRatingDidntLikeCurrentVersion";
NSString *const AppRatingLikedCurrentVersion = @"AppRatingDidntLikeCurrentVersion";

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
    return [userDefaults boolForKey:AppRatingRatedCurrentVersion] || [userDefaults boolForKey:AppRatingDeclinedToRateCurrentVersion] || [userDefaults boolForKey:AppRatingGaveFeedbackForCurrentVersion] || [userDefaults boolForKey:AppRatingLikedCurrentVersion] || [userDefaults boolForKey:AppRatingDidntLikeCurrentVersion];
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
        [userDefaults setBool:NO forKey:AppRatingDidntLikeCurrentVersion];
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
    [[NSUserDefaults standardUserDefaults] setInteger:numberOfEvents forKey:AppRatingNumberOfSignificantEventsRequiredForPrompt];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)declinedToRateCurrentVersion
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:AppRatingDeclinedToRateCurrentVersion];
    [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:AppRatingNumberOfVersionsToSkipPrompting];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)gaveFeedbackForCurrentVersion
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:AppRatingGaveFeedbackForCurrentVersion];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)ratedCurrentVersion
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:AppRatingRatedCurrentVersion];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)doesntLikeCurrentVersion
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:AppRatingDidntLikeCurrentVersion];
    [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:AppRatingNumberOfVersionsToSkipPrompting];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)likedCurrentVersion
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:AppRatingLikedCurrentVersion];
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:AppRatingNumberOfVersionsToSkipPrompting];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
