#import "AppRatingUtility.h"

@implementation AppRatingUtility

NSString *const AppRatingCurrentVersion = @"AppRatingCurrentVersion";
NSString *const AppRatingNumberOfSignificantEventsRequiredForPrompt = @"AppRatingNumberOfSignificantEventsRequiredForPrompt";
NSString *const AppRatingSignificantEventCount = @"AppRatingSignificantEventCount";
NSString *const AppRatingUseCount = @"AppRatingUseCount";
NSString *const AppRatingRatedCurrentVersion = @"AppRatingRatedCurrentVersion";
NSString *const AppRatingDeclinedToRateCurrentVersion = @"AppRatingDeclinedToRateCurrentVersion";
NSString *const AppRatingGaveFeedbackForCurrentVersion = @"AppRatingGaveFeedbackForCurrentVersion";

+ (BOOL)shouldPromptForAppReview
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:AppRatingRatedCurrentVersion]
        || [userDefaults boolForKey:AppRatingDeclinedToRateCurrentVersion]
        || [userDefaults boolForKey:AppRatingGaveFeedbackForCurrentVersion]) {
        return NO;
    }
    
    NSUInteger significantEventCount = [userDefaults integerForKey:AppRatingSignificantEventCount];
    NSUInteger numberOfSignificantEventsRequiredForPrompt = [userDefaults integerForKey:AppRatingNumberOfSignificantEventsRequiredForPrompt];
    
    if (significantEventCount >= numberOfSignificantEventsRequiredForPrompt) {
        return YES;
    }
    
    return NO;
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
        [userDefaults setObject:version forKey:AppRatingCurrentVersion];
        [userDefaults setInteger:1 forKey:AppRatingSignificantEventCount];
        [userDefaults setInteger:0 forKey:AppRatingSignificantEventCount];
        [userDefaults setBool:NO forKey:AppRatingRatedCurrentVersion];
        [userDefaults setBool:NO forKey:AppRatingDeclinedToRateCurrentVersion];
        [userDefaults setBool:NO forKey:AppRatingGaveFeedbackForCurrentVersion];
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

@end
