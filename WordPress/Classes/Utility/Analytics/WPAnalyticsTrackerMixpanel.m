#import "WPAnalyticsTrackerMixpanel.h"
#import <Mixpanel/Mixpanel.h>
#import "WPAnalyticsTrackerMixpanelInstructionsForStat.h"
#import "WordPressComApiCredentials.h"
#import "AccountService.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "Blog.h"
#import "BlogService.h"

@interface WPAnalyticsTrackerMixpanel()

@property (nonatomic, assign) NSInteger sessionCount;

@end

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
    self.sessionCount = [[[[Mixpanel sharedInstance] currentSuperProperties] objectForKey:@"session_count"] integerValue];
    self.sessionCount++;
    
    [self refreshMetadata];
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

- (void)refreshMetadata
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *account = [accountService defaultWordPressComAccount];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    
    BOOL dotcom_user = NO;
    BOOL jetpack_user = NO;
    if (account != nil) {
        dotcom_user = YES;
        if ([[account jetpackBlogs] count] > 0) {
            jetpack_user = YES;
        }
    }
    
    NSDictionary *properties = @{
                                 @"platform": @"iOS",
                                 @"session_count": @(self.sessionCount),
                                 @"dotcom_user": @(dotcom_user),
                                 @"jetpack_user": @(jetpack_user),
                                 @"number_of_blogs" : @([blogService blogCountForAllAccounts]) };
    [[Mixpanel sharedInstance] registerSuperProperties:properties];
    
    NSString *username = account.username;
    if (account && [username length] > 0) {
        [[Mixpanel sharedInstance] identify:username];
        [[Mixpanel sharedInstance].people set:@{ @"$username": username, @"$first_name" : username }];
    }
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
    
    [instructions.superPropertiesToFlag enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self flagSuperProperty:obj];
    }];
    
    [instructions.peoplePropertiesToAssign enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setValue:obj forPeopleProperty:key];
    }];
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

- (void)setValue:(id)value forPeopleProperty:(NSString *)property
{
    [[Mixpanel sharedInstance].people set:@{ property : value } ];
}

- (WPAnalyticsTrackerMixpanelInstructionsForStat *)instructionsForStat:(WPAnalyticsStat )stat
{
    WPAnalyticsTrackerMixpanelInstructionsForStat *instructions;
    
    switch (stat) {
        case WPAnalyticsStatApplicationOpened:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Application Opened"];
            [instructions setPeoplePropertyToIncrement:@"Application Opened"];
            break;
        case WPAnalyticsStatApplicationClosed:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Application Closed"];
            break;
        case WPAnalyticsStatThemesAccessedThemeBrowser:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Themes - Accessed Theme Browser"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_accessed_theme_browser"];
            [instructions setCurrentDateForPeopleProperty:@"last_time_accessed_theme_browser"];
            break;
        case WPAnalyticsStatThemesChangedTheme:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Themes - Changed Theme"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_changed_theme"];
            break;
        case WPAnalyticsStatReaderAccessed:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Accessed"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_accessed_reader"];
            [instructions setCurrentDateForPeopleProperty:@"last_time_accessed_reader"];
            break;
        case WPAnalyticsStatReaderOpenedArticle:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Opened Article"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_opened_article"];
            break;
        case WPAnalyticsStatReaderLikedArticle:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Liked Article"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_liked_article"];
            [instructions setCurrentDateForPeopleProperty:@"last_time_liked_reader_article"];
            break;
        case WPAnalyticsStatReaderRebloggedArticle:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Reblogged Article"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_reblogged_article"];
            [instructions setCurrentDateForPeopleProperty:@"last_time_reblogged_article"];
            break;
        case WPAnalyticsStatReaderInfiniteScroll:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Infinite Scroll"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_reader_performed_infinite_scroll"];
            break;
        case WPAnalyticsStatReaderFollowedReaderTag:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Followed Reader Tag"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_followed_reader_tag"];
            break;
        case WPAnalyticsStatReaderUnfollowedReaderTag:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Unfollowed Reader Tag"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_unfollowed_reader_tag"];
            break;
        case WPAnalyticsStatReaderFollowedSite:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Followed Site"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_followed_site"];
            break;
        case WPAnalyticsStatReaderLoadedTag:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Loaded Tag"];
            break;
        case WPAnalyticsStatReaderLoadedFreshlyPressed:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Loaded Freshly Pressed"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_loaded_freshly_pressed"];
            [instructions setCurrentDateForPeopleProperty:@"last_time_loaded_freshly_pressed"];
            break;
        case WPAnalyticsStatReaderCommentedOnArticle:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Reader - Commented on Article"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_commented_on_reader_article"];
            [instructions setCurrentDateForPeopleProperty:@"last_time_commented_on_article"];
            break;
        case WPAnalyticsStatStatsAccessed:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Stats - Accessed"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_accessed_stats"];
            [instructions setCurrentDateForPeopleProperty:@"last_time_accessed_stats"];
            break;
        case WPAnalyticsStatEditorCreatedPost:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Editor - Created Post"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_editor_created_post"];
            break;
        case WPAnalyticsStatEditorAddedPhotoViaLocalLibrary:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Editor - Added Photo via Local Library"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_added_photo_via_local_library"];
            break;
        case WPAnalyticsStatEditorAddedPhotoViaWPMediaLibrary:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Editor - Added Photo via WP Media Library"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_added_photo_via_wp_media_library"];
            break;
        case WPAnalyticsStatEditorPublishedPost:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Editor - Published Post"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_editor_published_post"];
            [instructions setCurrentDateForPeopleProperty:@"last_time_published_post"];
            break;
        case WPAnalyticsStatEditorUpdatedPost:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Editor - Updated Post"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_editor_updated_post"];
            break;
        case WPAnalyticsStatEditorScheduledPost:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Editor - Scheduled Post"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_editor_scheduled_post"];
            break;
        case WPAnalyticsStatEditorClosed:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Editor - Closed"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_editor_closed"];
            break;
        case WPAnalyticsStatEditorDiscardedChanges:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Editor - Discarded Changes"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_editor_discarded_changes"];
            break;
        case WPAnalyticsStatEditorSavedDraft:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Editor - Saved Draft"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_editor_saved_draft"];
            break;
        case WPAnalyticsStatNotificationsAccessed:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Notifications - Accessed"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_accessed_notifications"];
            [instructions setCurrentDateForPeopleProperty:@"last_time_accessed_notifications"];
            break;
        case WPAnalyticsStatNotificationsOpenedNotificationDetails:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Notifications - Opened Notification Details"];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_opened_notification_details"];
            break;
        case WPAnalyticsStatOpenedPosts:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_posts" forStat:WPAnalyticsStatApplicationClosed];
            break;
        case WPAnalyticsStatOpenedPages:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_pages" forStat:WPAnalyticsStatApplicationClosed];
            break;
        case WPAnalyticsStatOpenedComments:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_comments" forStat:WPAnalyticsStatApplicationClosed];
            break;
        case WPAnalyticsStatOpenedViewSite:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_view_site" forStat:WPAnalyticsStatApplicationClosed];
            break;
        case WPAnalyticsStatOpenedViewAdmin:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_view_admin" forStat:WPAnalyticsStatApplicationClosed];
            [instructions setSuperPropertyAndPeoplePropertyToIncrement:@"number_of_times_opened_view_admin"];
            break;
        case WPAnalyticsStatOpenedMediaLibrary:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_media_library" forStat:WPAnalyticsStatApplicationClosed];
            break;
        case WPAnalyticsStatOpenedSettings:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithPropertyIncrementor:@"number_of_times_opened_settings" forStat:WPAnalyticsStatApplicationClosed];
            break;
        case WPAnalyticsStatCreatedAccount:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Created Account"];
            [instructions setCurrentDateForPeopleProperty:@"$created"];
            [instructions addSuperPropertyToFlag:@"created_account_on_mobile"];
            break;
        case WPAnalyticsStatSharedItemViaEmail:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_shared_via_email"];
            break;
        case WPAnalyticsStatSharedItemViaSMS:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_shared_via_sms"];
            break;
        case WPAnalyticsStatSharedItemViaFacebook:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_shared_via_facebook"];
            break;
        case WPAnalyticsStatSharedItemViaTwitter:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_shared_via_twitter"];
            break;
        case WPAnalyticsStatSharedItemViaWeibo:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_shared_via_weibo"];
            break;
        case WPAnalyticsStatSentItemToInstapaper:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_sent_to_instapaper"];
            break;
        case WPAnalyticsStatSentItemToPocket:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_sent_to_pocket"];
            break;
        case WPAnalyticsStatSentItemToGooglePlus:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_sent_to_google_plus"];
            break;
		case WPAnalyticsStatSentItemToWordPress:
			instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_sent_to_wordpress"];
			break;
        case WPAnalyticsStatSharedItem:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_items_shared"];
            [instructions setCurrentDateForPeopleProperty:@"last_time_shared_article"];
            break;
        case WPAnalyticsStatNotificationPerformedAction:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_notifications_performed_action_against"];
            break;
        case WPAnalyticsStatNotificationApproved:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_notifications_approved"];
            break;
        case WPAnalyticsStatNotificationRepliedTo:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_notifications_replied_to"];
            break;
        case WPAnalyticsStatNotificationTrashed:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_notifications_trashed"];
            break;
        case WPAnalyticsStatNotificationFlaggedAsSpam:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_notifications_flagged_as_spam"];
            break;
        case WPAnalyticsStatPublishedPostWithPhoto:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_posts_published_with_photos"];
            break;
        case WPAnalyticsStatPublishedPostWithVideo:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_posts_published_with_videos"];
            break;
        case WPAnalyticsStatPublishedPostWithCategories:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_posts_published_with_categories"];
            break;
        case WPAnalyticsStatPublishedPostWithTags:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:@"number_of_posts_published_with_tags"];
            break;
        case WPAnalyticsStatAddedSelfHostedSite:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Added Self Hosted Site"];
            break;
        case WPAnalyticsStatAddedSelfHostedSiteButJetpackNotConnectedToWPCom:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Added Self Hosted Site Not Connected to Wordpress.com"];
            break;
        case WPAnalyticsStatSkippedConnectingToJetpack:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Skipped Connecting to Jetpack"];
            break;
        case WPAnalyticsStatSignedInToJetpack:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Signed into Jetpack"];
            [instructions addSuperPropertyToFlag:@"jetpack_user"];
            [instructions addSuperPropertyToFlag:@"dotcom_user"];
            break;
        case WPAnalyticsStatSelectedLearnMoreInConnectToJetpackScreen:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Selected Learn More in Connect to Jetpack Screen"];
            break;
        case WPAnalyticsStatPerformedJetpackSignInFromStatsScreen:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Signed into Jetpack from Stats Screen"];
            break;
        case WPAnalyticsStatSelectedInstallJetpack:
            instructions = [WPAnalyticsTrackerMixpanelInstructionsForStat mixpanelInstructionsForEventName:@"Selected Install Jetpack"];
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
