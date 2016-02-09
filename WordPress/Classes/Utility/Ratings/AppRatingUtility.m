
#import "AppRatingUtility.h"

#import "Constants.h"

@interface AppRatingUtility ()

@property (nonatomic, assign) NSUInteger systemWideSignificantEventCountRequiredForPrompt;
@property (nonatomic, strong) NSMutableDictionary *sections;
@property (nonatomic, strong) NSMutableDictionary *disabledSections;
@property (nonatomic, assign) BOOL allPromptingDisabled;
@property (nonatomic, copy) NSString *appReviewUrl;

@end

@implementation AppRatingUtility

NSString *const AppRatingCurrentVersion = @"AppRatingCurrentVersion";
NSString *const AppRatingSignificantEventCount = @"AppRatingSignificantEventCount";
NSString *const AppRatingUseCount = @"AppRatingUseCount";
NSString *const AppRatingNumberOfVersionsSkippedPrompting = @"AppRatingsNumberOfVersionsSkippedPrompt";
NSString *const AppRatingNumberOfVersionsToSkipPrompting = @"AppRatingsNumberOfVersionsToSkipPrompting";
NSString *const AppRatingSkipRatingCurrentVersion = @"AppRatingsSkipRatingCurrentVersion";
NSString *const AppRatingRatedCurrentVersion = @"AppRatingRatedCurrentVersion";
NSString *const AppRatingDeclinedToRateCurrentVersion = @"AppRatingDeclinedToRateCurrentVersion";
NSString *const AppRatingGaveFeedbackForCurrentVersion = @"AppRatingGaveFeedbackForCurrentVersion";
NSString *const AppRatingDislikedCurrentVersion = @"AppRatingDislikedCurrentVersion";
NSString *const AppRatingLikedCurrentVersion = @"AppRatingLikedCurrentVersion";
NSString *const AppRatingUserLikeCount = @"AppRatingUserLikeCount";
NSString *const AppRatingUserDislikeCount = @"AppRatingUserDislikeCount";
NSString *const AppRatingDefaultAppReviewUrl = @"http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=335703880&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8";

NSString *const AppReviewPromptDisabledUrl = @"https://api.wordpress.org/iphoneapp/app-review-prompt-check/1.0/";

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sections = [NSMutableDictionary dictionary];
        _disabledSections = [NSMutableDictionary dictionary];
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

+ (void)resetReviewPromptDisabledStatus
{
    AppRatingUtility *appRatingUtility = [AppRatingUtility sharedInstance];
    appRatingUtility.allPromptingDisabled = NO;
    [appRatingUtility.disabledSections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        appRatingUtility.disabledSections[key] = @(NO);
    }];
}

+ (void)checkIfAppReviewPromptsHaveBeenDisabled:(AppRatingCompletionBlock)success failure:(AppRatingCompletionBlock)failure;
{
    NSURL *url = [NSURL URLWithString:AppReviewPromptDisabledUrl];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [[AFJSONResponseSerializer alloc] init];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        NSDictionary *responseDictionary = (NSDictionary *)responseObject;
        AppRatingUtility *appRatingUtility = [AppRatingUtility sharedInstance];
        appRatingUtility.allPromptingDisabled = [responseDictionary[@"all-disabled"] boolValue];
        
        [appRatingUtility.disabledSections enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NSString *disabledKey = [NSString stringWithFormat:@"%@-disabled", key];
            BOOL disableSection = [responseDictionary[disabledKey] boolValue];
            appRatingUtility.disabledSections[key] = @(disableSection);
        }];
        
        NSString *appReviewUrl = [responseDictionary stringForKey:@"app-review-url"];
        if (appReviewUrl.length > 0) {
            AppRatingUtility *sharedInstance = [self sharedInstance];
            sharedInstance.appReviewUrl = appReviewUrl;
        }
        
        if (success) {
            success();
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Let's be optimistic and turn off throttling by default if this call doesn't work
        [self resetReviewPromptDisabledStatus];
        
        if (failure) {
            failure();
        }
    }];

    [operation start];
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
        BOOL skippedRatingPreviousVersion = [self skipRatingCurrentVersion];
        
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
        [userDefaults setBool:NO forKey:AppRatingSkipRatingCurrentVersion];
        
        [self resetReviewPromptDisabledStatus];
        
        if (interactedWithAppReviewPromptInPreviousVersion || skippedRatingPreviousVersion) {
            NSInteger numberOfVersionsSkippedPrompting = [userDefaults integerForKey:AppRatingNumberOfVersionsSkippedPrompting];
            NSInteger numberOfVersionsToSkipPrompting = [userDefaults integerForKey:AppRatingNumberOfVersionsToSkipPrompting];
            
            if (numberOfVersionsToSkipPrompting > 0) {
                if (numberOfVersionsSkippedPrompting < numberOfVersionsToSkipPrompting) {
                    // We haven't skipped enough versions, skip this one
                    numberOfVersionsSkippedPrompting++;
                    [userDefaults setInteger:numberOfVersionsSkippedPrompting forKey:AppRatingNumberOfVersionsSkippedPrompting];
                    [userDefaults setBool:YES forKey:AppRatingSkipRatingCurrentVersion];
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
    
    // Lets setup a entry for the section in the `disabledSections` dictionary
    if ([[AppRatingUtility sharedInstance].disabledSections objectForKey:section] == nil) {
        [[AppRatingUtility sharedInstance].disabledSections setObject:@(NO) forKey:section];
    }
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
    if ([self interactedWithAppReviewPrompt] || [self skipRatingCurrentVersion]) {
        return NO;
    }
    
    if ([AppRatingUtility sharedInstance].allPromptingDisabled) {
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
    
    if ([self interactedWithAppReviewPrompt] || [self skipRatingCurrentVersion]) {
        return NO;
    }
    
    AppRatingUtility *appRatingUtility = [AppRatingUtility sharedInstance];
    if (appRatingUtility.allPromptingDisabled || [appRatingUtility.disabledSections[section] boolValue]) {
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

+ (BOOL)skipRatingCurrentVersion
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:AppRatingSkipRatingCurrentVersion];
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

+ (NSString *)appReviewUrl
{
    AppRatingUtility *sharedInstance = [AppRatingUtility sharedInstance];
    if (sharedInstance.appReviewUrl.length == 0) {
        return AppRatingDefaultAppReviewUrl;
    } else {
        return sharedInstance.appReviewUrl;
    }
}

@end
