#import "WPMobileStats.h"
#import <Mixpanel/Mixpanel.h>
#import "WordPressComApiCredentials.h"
#import "WordPressComApi.h"
#import "WordPressAppDelegate.h"
#import "NSString+Helpers.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "Blog.h"
#import "Constants.h"
#import "AccountService.h"

static BOOL hasRecordedAppOpenedEvent = NO;

// General
NSString *const StatsEventAppClosed = @"Application Closed";
NSString *const StatsEventAppOpenedDueToPushNotification = @"Application Opened Due to Push Notification";

// Super Properties

// Notifications
NSString *const StatsSuperPropertyNumberOfTimesOpenedNotificationDetails = @"number_of_times_opened_notification_details";
NSString *const StatsSuperPropertyNumberOfNotificationsResultingInActions = @"number_of_notifications_resulting_in_actions";
NSString *const StatsSuperPropertyNumberOfNotificationsRepliedTo = @"number_of_notifications_replied_to";
NSString *const StatsSuperPropertyNumberOfNotificationsApproved = @"number_of_notifications_approved";
NSString *const StatsSuperPropertyNumberOfNotificationsUnapproved = @"number_of_notifications_unapproved";
NSString *const StatsSuperPropertyNumberOfNotificationsTrashed = @"number_of_notifications_trashed";
NSString *const StatsSuperPropertyNumberOfNotificationsUntrashed = @"number_of_notifications_untrashed";
NSString *const StatsSuperPropertyNumberOfNotificationsFlaggedAsSpam = @"number_of_notifications_flagged_as_spam";
NSString *const StatsSuperPropertyNumberOfNotificationsUnflaggedAsSpam = @"number_of_notifications_unflagged_as_spam";
NSString *const StatsSuperPropertyNumberOfNotificationsResultingInAFollow = @"number_of_notifications_resulting_in_a_follow";
NSString *const StatsSuperPropertyNumberOfNotificationsResultingInAnUnfollow = @"number_of_notifications_resulting_in_an_unfollow";

// Posts
NSString *const StatsSuperPropertyNumberOfPostsPublished = @"number_of_posts_published";
NSString *const StatsSuperPropertyNumberOfPostsUpdated = @"number_of_posts_updated";
NSString *const StatsSuperPropertyNumberOfPhotosAddedToPosts = @"number_of_photos_added_to_post";
NSString *const StatsSuperPropertyNumberOfVideosAddedToPosts = @"number_of_videos_added_to_post";
NSString *const StatsSuperPropertyNumberOfFeaturedImagesAssignedToPosts = @"number_of_featured_images_assigned_to_post";
NSString *const StatsSuperPropertyNumberOfPostsWithPhotos = @"number_of_posts_with_photos";
NSString *const StatsSuperPropertyNumberOfPostsWithVideos = @"number_of_posts_with_videos";
NSString *const StatsSuperPropertyNumberOfPostsWithCategories = @"number_of_posts_with_categories";
NSString *const StatsSuperPropertyNumberOfPostsWithTags = @"number_of_posts_with_tags";

@interface WPMobileStats() {
    NSMutableDictionary *_aggregatedEventProperties;
}

@end

@implementation WPMobileStats

- (id)init
{
    self = [super init];
    if (self) {
        _aggregatedEventProperties = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (WPMobileStats *)sharedInstance
{
    static WPMobileStats *sharedInstance = nil;
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

+ (void)initializeStats
{
    [Mixpanel sharedInstanceWithToken:[WordPressComApiCredentials mixpanelAPIToken]];

    // Tracking session count will help us isolate users who just installed the app
    NSUInteger sessionCount = [[[[Mixpanel sharedInstance] currentSuperProperties] objectForKey:@"session_count"] intValue];
    sessionCount++;

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *account = [accountService defaultWordPressComAccount];
    NSDictionary *properties = @{
                                 @"platform": @"iOS",
                                 @"session_count": @(sessionCount),
                                 @"connected_to_dotcom": @(account != nil),
                                 @"number_of_blogs" : @([Blog countWithContext:[[ContextManager sharedInstance] mainContext]]) };
    [[Mixpanel sharedInstance] registerSuperProperties:properties];
    
    NSString *username = account.username;
    if (account && [username length] > 0) {
        [[Mixpanel sharedInstance] identify:username];
        [[Mixpanel sharedInstance].people increment:@"Application Opened" by:@(1)];
        [[Mixpanel sharedInstance].people set:@{ @"$username": username, @"$first_name" : username }];
    }
}

+ (void)pauseSession
{
    [self clearPropertiesForAllEvents];
    hasRecordedAppOpenedEvent = NO;
}

+ (void)recordAppOpenedForEvent:(NSString *)event {
    if (!hasRecordedAppOpenedEvent) {
        [self trackEventForSelfHostedAndWPCom:event];
    }
    hasRecordedAppOpenedEvent = YES;
}

+ (void)trackEventForSelfHostedAndWPCom:(NSString *)event
{
    [[self sharedInstance] trackEventForSelfHostedAndWPCom:event];
}

+ (void)trackEventForSelfHostedAndWPCom:(NSString *)event properties:(NSDictionary *)properties
{
    [[self sharedInstance] trackEventForSelfHostedAndWPCom:event properties:properties];
}

+ (void)trackEventForSelfHostedAndWPComWithSavedProperties:(NSString *)event
{
    [[self sharedInstance] trackEventForSelfHostedAndWPComWithSavedProperties:event];
}

+ (void)trackEventForWPCom:(NSString *)event
{
    [[self sharedInstance] trackEventForWPCom:event];
}

+ (void)trackEventForWPCom:(NSString *)event properties:(NSDictionary *)properties
{
    [[self sharedInstance] trackEventForWPCom:event properties:properties];
}

+ (void)trackEventForWPComWithSavedProperties:(NSString *)event
{
    [[self sharedInstance] trackEventForWPComWithSavedProperties:event];
}

+ (void)pingWPComStatsEndpoint:(NSString *)statName
{
    int x = arc4random();
    NSString *statsURL = [NSString stringWithFormat:@"%@%@%@%@%d" , kMobileReaderURL, @"&template=stats&stats_name=", statName, @"&rnd=", x];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:statsURL]];
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
    @autoreleasepool {
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:nil];
        [conn start];
    }
}

+ (void)clearPropertiesForAllEvents
{
    [[self sharedInstance] clearPropertiesForAllEvents];
}

+ (void)incrementProperty:(NSString *)property forEvent:(NSString *)event
{
    [[self sharedInstance] incrementProperty:property forEvent:event];
}

+ (void)setValue:(id)value forProperty:(NSString *)property forEvent:(NSString *)event
{
    [[self sharedInstance] setValue:value forProperty:property forEvent:event];
}

+ (void)flagProperty:(NSString *)property forEvent:(NSString *)event
{
    [[self sharedInstance] flagProperty:property forEvent:event];
}

+ (void)unflagProperty:(NSString *)property forEvent:(NSString *)event
{
    [[self sharedInstance] unflagProperty:property forEvent:event];
}

+ (void)flagSuperProperty:(NSString *)property
{
    [[self sharedInstance] flagSuperProperty:property];
}

+ (void)incrementSuperProperty:(NSString *)property
{
    [[self sharedInstance] incrementSuperProperty:property];
}

+ (void)setValue:(id)value forSuperProperty:(NSString *)property
{
    [[self sharedInstance] setValue:value forSuperProperty:property];
}

+ (void)flagPeopleProperty:(NSString *)property
{
    [[self sharedInstance] flagPeopleProperty:property];
}

+ (void)incrementPeopleProperty:(NSString *)property
{
    [[self sharedInstance] incrementPeopleProperty:property];
}

+ (void)setValue:(id)value forPeopleProperty:(NSString *)property
{
    [[self sharedInstance] setValue:value forPeopleProperty:property];
}

+ (void)flagPeopleAndSuperProperty:(NSString *)property
{
    [[self sharedInstance] flagPeopleAndSuperProperty:property];
}

+ (void)incrementPeopleAndSuperProperty:(NSString *)property
{
    [[self sharedInstance] incrementPeopleAndSuperProperty:property];
}

+ (void)setValue:(id)value forPeopleAndSuperProperty:(NSString *)property
{
    [[self sharedInstance] setValue:value forPeopleAndSuperProperty:property];
}

#pragma mark - Private Methods

- (BOOL)connectedToWordPressDotCom
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    return [[defaultAccount restApi] hasCredentials];
}

- (void)trackEventForSelfHostedAndWPCom:(NSString *)event
{
    [[Mixpanel sharedInstance] track:event];
}

- (void)trackEventForSelfHostedAndWPCom:(NSString *)event properties:(NSDictionary *)properties
{
    [[Mixpanel sharedInstance] track:event properties:properties];
}

- (void)trackEventForSelfHostedAndWPComWithSavedProperties:(NSString *)event
{
    [[Mixpanel sharedInstance] track:event properties:[self propertiesForEvent:event]];
}

- (void)trackEventForWPCom:(NSString *)event
{
    if ([self connectedToWordPressDotCom]) {
        [[Mixpanel sharedInstance] track:event];
    }
}

- (void)trackEventForWPCom:(NSString *)event properties:(NSDictionary *)properties
{
    if ([self connectedToWordPressDotCom]) {
        [[Mixpanel sharedInstance] track:event properties:properties];
    }
}

- (void)trackEventForWPComWithSavedProperties:(NSString *)event
{
    if ([self connectedToWordPressDotCom]) {
        [[Mixpanel sharedInstance] track:event properties:[self propertiesForEvent:event]];
    }
}

- (void)clearPropertiesForAllEvents
{
    [_aggregatedEventProperties removeAllObjects];
}

- (void)incrementProperty:(NSString *)property forEvent:(NSString *)event
{
    NSNumber *currentValue = [self property:property forEvent:event];
    int newValue;
    if (currentValue == nil) {
        newValue = 1;
    } else {
        newValue = [currentValue intValue];
        newValue++;
    }
    
    [self saveProperty:property withValue:@(newValue) forEvent:event];
}

- (void)flagProperty:(NSString *)property forEvent:(NSString *)event
{
    [self saveProperty:property withValue:@(YES) forEvent:event];
}

- (void)unflagProperty:(NSString *)property forEvent:(NSString *)event
{
    [self saveProperty:property withValue:@(NO) forEvent:event];
}

- (void)setValue:(id)value forProperty:(NSString *)property forEvent:(NSString *)event
{
    [self saveProperty:property withValue:value forEvent:event];
}

- (void)flagSuperProperty:(NSString *)property
{
    NSParameterAssert(property != nil);
    NSMutableDictionary *superProperties = [[NSMutableDictionary alloc] initWithDictionary:[Mixpanel sharedInstance].currentSuperProperties];
    superProperties[property] = @(YES);
    [[Mixpanel sharedInstance] registerSuperProperties:superProperties];
}


- (void)incrementSuperProperty:(NSString *)property
{
    NSParameterAssert(property != nil);
    NSMutableDictionary *superProperties = [[NSMutableDictionary alloc] initWithDictionary:[Mixpanel sharedInstance].currentSuperProperties];
    NSUInteger propertyValue = [superProperties[property] integerValue];
    superProperties[property] = @(++propertyValue);
    [[Mixpanel sharedInstance] registerSuperProperties:superProperties];
}

- (void)setValue:(id)value forSuperProperty:(NSString *)property
{
    NSParameterAssert(value != nil);
    NSParameterAssert(property != nil);
    NSMutableDictionary *superProperties = [[NSMutableDictionary alloc] initWithDictionary:[Mixpanel sharedInstance].currentSuperProperties];
    superProperties[property] = value;
    [[Mixpanel sharedInstance] registerSuperProperties:superProperties];
}

- (void)flagPeopleProperty:(NSString *)property
{
    NSParameterAssert(property != nil);
    [[Mixpanel sharedInstance].people set:@{ property : @(YES) }];
}

- (void)incrementPeopleProperty:(NSString *)property
{
    NSParameterAssert(property != nil);
    [[Mixpanel sharedInstance].people increment:property by:@(1)];
}

- (void)setValue:(id)value forPeopleProperty:(NSString *)property
{
    NSParameterAssert(value != nil);
    NSParameterAssert(property != nil);
    [[Mixpanel sharedInstance].people set:@{property: value}];
}

- (void)flagPeopleAndSuperProperty:(NSString *)property
{
    NSParameterAssert(property != nil);
    [self flagPeopleProperty:property];
    [self flagSuperProperty:property];
}

- (void)incrementPeopleAndSuperProperty:(NSString *)property
{
    NSParameterAssert(property != nil);
    [self incrementPeopleProperty:property];
    [self incrementSuperProperty:property];
}

- (void)setValue:(id)value forPeopleAndSuperProperty:(NSString *)property
{
    NSParameterAssert(value != nil);
    NSParameterAssert(property != nil);
    [self setValue:value forPeopleProperty:property];
    [self setValue:value forSuperProperty:property];
}


- (id)property:(NSString *)property forEvent:(NSString *)event
{
    NSMutableDictionary *eventProperties = [_aggregatedEventProperties objectForKey:event];
    return [eventProperties objectForKey:property];
}

- (void)saveProperty:(NSString *)property withValue:(id)value forEvent:(NSString *)event
{
    NSMutableDictionary *eventProperties = [_aggregatedEventProperties objectForKey:event];
    if (eventProperties == nil) {
        eventProperties = [[NSMutableDictionary alloc] init];
        [_aggregatedEventProperties setValue:eventProperties forKey:event];
    }
    
    [eventProperties setValue:value forKey:property];
}

- (NSDictionary *)propertiesForEvent:(NSString *)event
{
    return [_aggregatedEventProperties objectForKey:event];
}


@end
