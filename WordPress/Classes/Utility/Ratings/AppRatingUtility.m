
#import "AppRatingUtility.h"

@interface AppRatingUtility ()

@property (nonatomic, assign) NSUInteger systemWideSignificantEventCountRequiredForPrompt;
@property (nonatomic, strong) NSMutableDictionary *sections;

@end

@implementation AppRatingUtility

NSString *const AppRatingCurrentVersion = @"AppRatingCurrentVersion";
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

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sections = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (instancetype)sharedInstance {
    static AppRatingUtility *_sharedAppRatingUtility = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedAppRatingUtility = [self new];
    });
    
    return _sharedAppRatingUtility;
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
        for (NSString *section in [AppRatingUtility sharedInstance].sections.allKeys) {
            [userDefaults setInteger:0 forKey:[self significantEventCountKeyForSection:section]];
        }
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

+ (void)registerSection:(NSString *)section withSignificantEventCount:(NSUInteger)significantEventCount
{
    [[AppRatingUtility sharedInstance].sections setObject:@(significantEventCount) forKey:section];
}

+ (void)unregisterAllSections
{
    [[AppRatingUtility sharedInstance].sections removeAllObjects];
}

+ (void)incrementSignificantEvent
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger numberOfSignificantEvents = [userDefaults integerForKey:AppRatingSignificantEventCount];
    numberOfSignificantEvents++;
    [userDefaults setInteger:numberOfSignificantEvents forKey:AppRatingSignificantEventCount];
    [userDefaults synchronize];
}

+ (void)incrementSignificantEventForSection:(NSString *)section
{
    [self assertValidSection:section];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *key = [self significantEventCountKeyForSection:section];
    NSInteger numberOfSignificantEvents = [userDefaults integerForKey:[self significantEventCountKeyForSection:section]];
    numberOfSignificantEvents++;
    [userDefaults setInteger:numberOfSignificantEvents forKey:key];
    [userDefaults synchronize];
}

+ (void)setSystemWideSignificantEventsCount:(NSUInteger)numberOfEvents
{
    [AppRatingUtility sharedInstance].systemWideSignificantEventCountRequiredForPrompt = numberOfEvents;
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


+ (BOOL)shouldPromptForAppReview
{
    if ([self interactedWithAppReviewPrompt]) {
        return NO;
    }
    
    NSUInteger significantEventCount = [self systemWideSignificantEventCount];
    NSUInteger numberOfSignificantEventsRequiredForPrompt = [AppRatingUtility sharedInstance].systemWideSignificantEventCountRequiredForPrompt;
    
    if (significantEventCount >= numberOfSignificantEventsRequiredForPrompt) {
        return YES;
    }
    
    return NO;
}

+ (NSUInteger)systemWideSignificantEventCount
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    __block NSUInteger total = [userDefaults integerForKey:AppRatingSignificantEventCount];
    [[AppRatingUtility sharedInstance].sections.allKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *section = (NSString *)obj;
        total += [userDefaults integerForKey:[self significantEventCountKeyForSection:section]];
    }];
    return total;
}

+ (BOOL)shouldPromptForAppReviewForSection:(NSString *)section
{
    [self assertValidSection:section];
    
    if ([self interactedWithAppReviewPrompt]) {
        return NO;
    }
    
    NSUInteger numberOfSignificantEventsForSection = [[NSUserDefaults standardUserDefaults] integerForKey:[self significantEventCountKeyForSection:section]];
    NSUInteger requiredNumberOfSignificantEventsForSection = [[[AppRatingUtility sharedInstance].sections valueForKey:section] unsignedIntegerValue];
    if (numberOfSignificantEventsForSection >= requiredNumberOfSignificantEventsForSection) {
        return YES;
    } else {
        return NO;
    }
}

+ (NSString *)significantEventCountKeyForSection:(NSString *)section
{
    return [NSString stringWithFormat:@"%@_%@", AppRatingSignificantEventCount, section];
}

+ (BOOL)interactedWithAppReviewPrompt
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults boolForKey:AppRatingRatedCurrentVersion] || [userDefaults boolForKey:AppRatingDeclinedToRateCurrentVersion] || [userDefaults boolForKey:AppRatingGaveFeedbackForCurrentVersion] || [userDefaults boolForKey:AppRatingLikedCurrentVersion] || [userDefaults boolForKey:AppRatingDislikedCurrentVersion];
}

+ (BOOL)hasUserEverLikedApp
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:AppRatingUserLikeCount] > 0;
}

+ (BOOL)hasUserEverDislikedApp
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:AppRatingUserDislikeCount] > 0;
}

+ (void)assertValidSection:(NSString *)section
{
    NSAssert([[AppRatingUtility sharedInstance].sections.allKeys containsObject:section], @"Invalid section");
}

@end
