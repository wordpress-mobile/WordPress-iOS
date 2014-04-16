#import "WPAnalyticsTrackerMixpanel.h"
#import <Mixpanel/Mixpanel.h>
#import "WPAnalyticsTrackerMixpanelInstructionsForStat.h"
#import "WordPressComApiCredentials.h"
#import "AccountService.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "Blog.h"
#import "BlogService.h"

@implementation WPAnalyticsTrackerMixpanel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _aggregatedStatProperties = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)beginSession
{
    [Mixpanel sharedInstanceWithToken:[WordPressComApiCredentials mixpanelAPIToken]];
    
    // Tracking session count will help us isolate users who just installed the app
    NSUInteger sessionCount = [[[[Mixpanel sharedInstance] currentSuperProperties] objectForKey:@"session_count"] intValue];
    sessionCount++;
    
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *account = [accountService defaultWordPressComAccount];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    NSDictionary *properties = @{
                                 @"platform": @"iOS",
                                 @"session_count": @(sessionCount),
                                 @"connected_to_dotcom": @(account != nil),
                                 @"number_of_blogs" : @([blogService blogCountForAllAccounts]) };
    [[Mixpanel sharedInstance] registerSuperProperties:properties];
    
    NSString *username = account.username;
    if (account && [username length] > 0) {
        [[Mixpanel sharedInstance] identify:username];
        [[Mixpanel sharedInstance].people increment:@"Application Opened" by:@(1)];
        [[Mixpanel sharedInstance].people set:@{ @"$username": username, @"$first_name" : username }];
    }
}
- (void)track:(WPAnalyticsStat)stat
{
    [self track:stat withProperties:nil];
}

- (void)track:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties
{
    WPAnalyticsTrackerMixpanelInstructionsForStat *instructions = [self instructionsForStat:stat];
    if (instructions == nil) {
        DDLogInfo(@"No instructions, do nothing");
        return;
    }
    
    [self trackMixpanelDataForInstructions:instructions andProperties:properties];
}

- (void)endSession
{
    [_aggregatedStatProperties removeAllObjects];
}

#pragma mark - Private Methods

- (NSString *)convertWPStatToString:(WPAnalyticsStat)stat
{
    return [NSString stringWithFormat:@"%d", stat];
}

- (BOOL)connectedToWordPressDotCom
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];
    
    return [[defaultAccount restApi] hasCredentials];
}

- (void)trackMixpanelDataForInstructions:(WPAnalyticsTrackerMixpanelInstructionsForStat *)instructions andProperties:(NSDictionary *)properties
{
    if (instructions.disableTrackingForSelfHosted) {
        if (![self connectedToWordPressDotCom]) {
            return;
        }
    }
    
    if ([instructions.mixpanelEventName length] > 0) {
        NSDictionary *aggregatedPropertiesForEvent = [self propertiesForStat:instructions.stat];
        if (aggregatedPropertiesForEvent != nil) {
            NSMutableDictionary *combinedProperties = [[NSMutableDictionary alloc] init];
            [combinedProperties addEntriesFromDictionary:aggregatedPropertiesForEvent];
            [combinedProperties addEntriesFromDictionary:properties];
            [[Mixpanel sharedInstance] track:instructions.mixpanelEventName properties:combinedProperties];
        } else {
            [[Mixpanel sharedInstance] track:instructions.mixpanelEventName properties:properties];
        }
    }
    
    if ([instructions.superPropertyToIncrement length] > 0) {
        [self incrementSuperProperty:instructions.superPropertyToIncrement];
    }
    
    if ([instructions.peoplePropertyToIncrement length] > 0) {
        [self incrementPeopleProperty:instructions.peoplePropertyToIncrement];
    }
    
    if ([instructions.propertyToIncrement length] > 0) {
        [self incrementProperty:instructions.propertyToIncrement forStat:instructions.statToAttachProperty];
    }
    
    if ([instructions.superPropertyToFlag length] > 0) {
        [self flagSuperProperty:instructions.superPropertyToFlag];
    }
}

- (void)incrementPeopleProperty:(NSString *)property
{
    [[Mixpanel sharedInstance].people increment:property by:@(1)];
}

- (void)incrementSuperProperty:(NSString *)property
{
    NSMutableDictionary *superProperties = [[NSMutableDictionary alloc] initWithDictionary:[Mixpanel sharedInstance].currentSuperProperties];
    NSUInteger propertyValue = [superProperties[property] integerValue];
    superProperties[property] = @(++propertyValue);
    [[Mixpanel sharedInstance] registerSuperProperties:superProperties];
}

- (void)flagSuperProperty:(NSString *)property
{
    NSMutableDictionary *superProperties = [[NSMutableDictionary alloc] initWithDictionary:[Mixpanel sharedInstance].currentSuperProperties];
    superProperties[property] = @(YES);
    [[Mixpanel sharedInstance] registerSuperProperties:superProperties];
}

- (WPAnalyticsTrackerMixpanelInstructionsForStat *)instructionsForStat:(WPAnalyticsStat )stat
{
    WPAnalyticsTrackerMixpanelInstructionsForStat *instructions;
    
    switch (stat) {
        case WPStatApplicationOpened:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Application Opened"];
            break;
        case WPStatApplicationClosed:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Application Closed"];
            break;
        case WPStatThemesAccessedThemeBrowser:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Themes - Accessed Theme Browser"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_accessed_theme_browser"];
            break;
        case WPStatThemesChangedTheme:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Themes - Changed Theme"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_changed_theme"];
            break;
        case WPStatReaderAccessed:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Accessed"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_accessed_reader"];
            break;
        case WPStatReaderOpenedArticle:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Opened Article"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_opened_article"];
            break;
        case WPStatReaderLikedArticle:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Liked Article"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_liked_article"];
            break;
        case WPStatReaderRebloggedArticle:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Reblogged Article"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_reblogged_article"];
            break;
        case WPStatReaderInfiniteScroll:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Infinite Scroll"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_reader_performed_infinite_scroll"];
            break;
        case WPStatReaderFollowedReaderTag:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Followed Reader Tag"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_followed_reader_tag"];
            break;
        case WPStatReaderUnfollowedReaderTag:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Unfollowed Reader Tag"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_unfollowed_reader_tag"];
            break;
        case WPStatReaderLoadedTag:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Loaded Tag"];
            break;
        case WPStatReaderLoadedFreshlyPressed:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Loaded Freshly Pressed"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_loaded_freshly_pressed"];
            break;
        case WPStatReaderCommentedOnArticle:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Commented on Article"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_commented_on_reader_article"];
            break;
        case WPStatStatsAccessed:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Stats - Accessed"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_accessed_stats"];
            break;
        case WPStatEditorCreatedPost:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Editor - Created Post"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_editor_created_post"];
            break;
        case WPStatEditorAddedPhotoViaLocalLibrary:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Editor - Added Photo via Local Library"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_added_photo_via_local_library"];
            break;
        case WPStatEditorAddedPhotoViaWPMediaLibrary:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Editor - Added Photo via WP Media Library"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_added_photo_via_wp_media_library"];
            break;
        case WPStatEditorPublishedPost:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Editor - Published Post"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_editor_published_post"];
            break;
        case WPStatEditorUpdatedPost:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Editor - Updated Post"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_editor_updated_post"];
            break;
        case WPStatNotificationsAccessed:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Notifications - Accessed"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_accessed_notifications"];
            break;
        case WPStatNotificationsOpenedNotificationDetails:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Notifications - Opened Notification Details"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_opened_notification_details"];
            break;
        case WPStatOpenedPosts:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_posts" forStat:WPStatApplicationClosed];
            break;
        case WPStatOpenedPages:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_pages" forStat:WPStatApplicationClosed];
            break;
        case WPStatOpenedComments:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_comments" forStat:WPStatApplicationClosed];
            break;
        case WPStatOpenedViewSite:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_view_site" forStat:WPStatApplicationClosed];
            break;
        case WPStatOpenedViewAdmin:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_view_admin" forStat:WPStatApplicationClosed];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_opened_view_admin"];
            break;
        case WPStatOpenedMediaLibrary:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_media_library" forStat:WPStatApplicationClosed];
            break;
        case WPStatOpenedSettings:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_settings" forStat:WPStatApplicationClosed];
            break;
        case WPStatCreatedAccount:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Created Account"];
            break;
        case WPStatSharedItemViaEmail:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_shared_via_email"];
            break;
        case WPStatSharedItemViaSMS:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_shared_via_sms"];
            break;
        case WPStatSharedItemViaFacebook:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_shared_via_facebook"];
            break;
        case WPStatSharedItemViaTwitter:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_shared_via_twitter"];
            break;
        case WPStatSharedItemViaWeibo:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_shared_via_weibo"];
            break;
        case WPStatSentItemToInstapaper:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_sent_to_instapaper"];
            break;
        case WPStatSentItemToPocket:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_sent_to_pocket"];
            break;
        case WPStatSentItemToGooglePlus:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_sent_to_google_plus"];
            break;
        case WPStatSharedItem:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_shared"];
            break;
        case WPStatNotificationPerformedAction:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_notifications_performed_action_against"];
            break;
        case WPStatNotificationApproved:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_notifications_approved"];
            break;
        case WPStatNotificationRepliedTo:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_notifications_replied_to"];
            break;
        case WPStatNotificationTrashed:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_notifications_trashed"];
            break;
        case WPStatNotificationFlaggedAsSpam:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_notifications_flagged_as_spam"];
            break;
        case WPStatPublishedPostWithPhoto:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_posts_published_with_photos"];
            break;
        case WPStatPublishedPostWithVideo:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_posts_published_with_videos"];
            break;
        case WPStatPublishedPostWithCategories:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_posts_published_with_categories"];
            break;
        case WPStatPublishedPostWithTags:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_posts_published_with_tags"];
            break;
        default:
            break;
    }
    
    instructions.stat = stat;
    
    return instructions;
}

#pragma mark - Deferred Property Related Methods

- (id)property:(NSString *)property forStat:(WPAnalyticsStat)stat
{
    NSMutableDictionary *properties = [_aggregatedStatProperties objectForKey:[self convertWPStatToString:stat]];
    return properties[property];
}

- (void)saveProperty:(NSString *)property withValue:(id)value forStat:(WPAnalyticsStat)stat
{
    NSMutableDictionary *properties = [_aggregatedStatProperties objectForKey:[self convertWPStatToString:stat]];
    if (properties == nil) {
        properties = [[NSMutableDictionary alloc] init];
        [_aggregatedStatProperties setValue:properties forKey:[self convertWPStatToString:stat]];
    }
    
    properties[property] = value;
}

- (NSDictionary *)propertiesForStat:(WPAnalyticsStat)stat
{
    return [_aggregatedStatProperties objectForKey:[self convertWPStatToString:stat]];
}

- (void)incrementProperty:(NSString *)property forStat:(WPAnalyticsStat)stat
{
    NSNumber *currentValue = [self property:property forStat:stat];
    int newValue = 1;
    if (currentValue != nil) {
        newValue = [currentValue intValue];
        newValue++;
    }
    
    [self saveProperty:property withValue:@(newValue) forStat:stat];
}

@end
