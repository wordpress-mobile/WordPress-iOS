#import "WPStatsTrackerMixpanel.h"
#import <Mixpanel/Mixpanel.h>
#import "WPStatsMixpanelClientInstructionsForStat.h"
#import "WordPressComApiCredentials.h"
#import "AccountService.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "Blog.h"

@implementation WPStatsTrackerMixpanel

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
- (void)track:(WPStat)stat
{
    [self track:stat withProperties:nil];
}

- (void)track:(WPStat)stat withProperties:(NSDictionary *)properties
{
    WPStatsMixpanelClientInstructionsForStat *instructions = [self instructionsForStat:stat];
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

- (NSString *)convertWPStatToString:(WPStat)stat
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

- (void)trackMixpanelDataForInstructions:(WPStatsMixpanelClientInstructionsForStat *)instructions andProperties:(NSDictionary *)properties
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

- (WPStatsMixpanelClientInstructionsForStat *)instructionsForStat:(WPStat )stat
{
    WPStatsMixpanelClientInstructionsForStat *instructions;
    
    switch (stat) {
        case WPStatApplicationOpened:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Application Opened"];
            break;
        case WPStatApplicationClosed:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Application Closed"];
            break;
        case WPStatThemesAccessedThemeBrowser:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Theme - Accessed Theme Browser"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_accessed_theme_browser"];
            break;
        case WPStatThemesChangedTheme:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Theme - Changed Theme"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_changed_theme"];
            break;
        case WPStatReaderAccessed:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Accessed Reader"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_accessed_reader"];
            break;
        case WPStatReaderOpenedArticle:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Opened Article"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_opened_article"];
            break;
        case WPStatReaderLikedArticle:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Liked Article"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_liked_article"];
            break;
        case WPStatReaderRebloggedArticle:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Reblogged Article"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_reblogged_article"];
            break;
        case WPStatReaderInfiniteScroll:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Infinite Scroll"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_reader_performed_infinite_scroll"];
            break;
        case WPStatReaderFollowedReaderTag:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Followed Reader Tag"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_followed_reader_tag"];
            break;
        case WPStatReaderUnfollowedReaderTag:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Unfollowed Reader Tag"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_unfollowed_reader_tag"];
            break;
        case WPStatReaderFilteredByReaderTag:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Filtered By Reader Tag"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_filtered_by_reader_tag"];
            break;
        case WPStatReaderLoadedFreshlyPressed:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Loaded Freshly Pressed"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_loaded_freshly_pressed"];
            break;
        case WPStatReaderCommentedOnArticle:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Commented on Article"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_commented_on_reader_article"];
            break;
        case WPStatStatsAccessedStats:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Stats - Accessed Stats"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_accessed_stats"];
            break;
        case WPStatEditorCreatedPost:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Editor - Created Post"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_editor_created_post"];
            break;
        case WPStatEditorAddedPhotoViaLocalLibrary:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Editor - Added Photo via Local Library"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_added_photo_via_local_library"];
            break;
        case WPStatEditorAddedPhotoViaWPMediaLibrary:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Editor - Added Photo via WP Media Library"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_added_photo_via_wp_media_library"];
            break;
        case WPStatEditorPublishedPost:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Editor - Published Post"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_editor_published_post"];
            break;
        case WPStatEditorUpdatedPost:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Editor - Updated Post"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_editor_updated_post"];
            break;
        case WPStatNotificationsAccessed:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Notifications - Accessed Notifications"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_accessed_notifications"];
            break;
        case WPStatNotificationsOpenedNotificationDetails:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Notifications - Opened Notification Details"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_opened_notification_details"];
            break;
        case WPStatOpenedPosts:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_posts" forStat:WPStatApplicationClosed];
            break;
        case WPStatOpenedPages:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_pages" forStat:WPStatApplicationClosed];
            break;
        case WPStatOpenedComments:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_comments" forStat:WPStatApplicationClosed];
            break;
        case WPStatOpenedViewSite:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_view_site" forStat:WPStatApplicationClosed];
            break;
        case WPStatOpenedViewAdmin:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_view_admin" forStat:WPStatApplicationClosed];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_opened_view_admin"];
            break;
        case WPStatOpenedMediaLibrary:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_media_library" forStat:WPStatApplicationClosed];
            break;
        case WPStatOpenedSettings:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_settings" forStat:WPStatApplicationClosed];
            break;
        case WPStatCreatedAccount:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsForEventName:@"Created Account"];
            break;
        case WPStatSharedItemViaEmail:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_shared_via_email"];
            break;
        case WPStatSharedItemViaSMS:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_shared_via_sms"];
            break;
        case WPStatSharedItemViaFacebook:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_shared_via_facebook"];
            break;
        case WPStatSharedItemViaTwitter:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_shared_via_twitter"];
            break;
        case WPStatSharedItemViaWeibo:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_shared_via_weibo"];
            break;
        case WPStatSentItemToInstapaper:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_sent_to_instapaper"];
            break;
        case WPStatSentItemToPocket:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_sent_to_pocket"];
            break;
        case WPStatSentItemToGooglePlus:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_sent_to_google_plus"];
            break;
        case WPStatSharedItem:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_shared"];
            break;
        case WPStatNotificationPerformedAction:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_notifications_performed_action_against"];
            break;
        case WPStatNotificationApproved:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_notifications_approved"];
            break;
        case WPStatNotificationRepliedTo:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_notifications_replied_to"];
            break;
        case WPStatNotificationTrashed:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_notifications_trashed"];
            break;
        case WPStatNotificationFlaggedAsSpam:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_notifications_flagged_as_spam"];
            break;
        case WPStatPublishedPostWithPhoto:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_posts_published_with_photos"];
            break;
        case WPStatPublishedPostWithVideo:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_posts_published_with_videos"];
            break;
        case WPStatPublishedPostWithCategories:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_posts_published_with_categories"];
            break;
        case WPStatPublishedPostWithTags:
            instructions = [WPStatsMixpanelClientInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_posts_published_with_tags"];
            break;
        default:
            break;
    }
    
    instructions.stat = stat;
    
    return instructions;
}

#pragma mark - Deferred Property Related Methods

- (id)property:(NSString *)property forStat:(WPStat)stat
{
    NSMutableDictionary *properties = [_aggregatedStatProperties objectForKey:[self convertWPStatToString:stat]];
    return properties[property];
}

- (void)saveProperty:(NSString *)property withValue:(id)value forStat:(WPStat)stat
{
    NSMutableDictionary *properties = [_aggregatedStatProperties objectForKey:[self convertWPStatToString:stat]];
    if (properties == nil) {
        properties = [[NSMutableDictionary alloc] init];
        [_aggregatedStatProperties setValue:properties forKey:[self convertWPStatToString:stat]];
    }
    
    properties[property] = value;
}

- (NSDictionary *)propertiesForStat:(WPStat)stat
{
    return [_aggregatedStatProperties objectForKey:[self convertWPStatToString:stat]];
}

- (void)incrementProperty:(NSString *)property forStat:(WPStat)stat
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
