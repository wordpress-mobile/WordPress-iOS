#import "WPAnalyticsTrackerAutomatticTracks.h"
#import "ContextManager.h"
#import "AccountService.h"
#import "BlogService.h"
#import "WPAccount.h"
#import "Blog.h"
#import <Automattic_Tracks_iOS/TracksService.h>

@interface  TracksEventPair : NSObject
@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, strong) NSDictionary *properties;
@end

@implementation TracksEventPair
@end


@interface WPAnalyticsTrackerAutomatticTracks ()

@property (nonatomic, strong) TracksContextManager *contextManager;
@property (nonatomic, strong) TracksService *tracksService;
@property (nonatomic, strong) NSDictionary *userProperties;
@property (nonatomic, strong) NSString *anonymousID;

@end

NSString *const TracksEventPropertyButtonKey = @"button";
NSString *const TracksEventPropertyMenuItemKey = @"menu_item";
NSString *const TracksUserDefaultsAnonymousUserIDKey = @"TracksAnonymousUserID";

@implementation WPAnalyticsTrackerAutomatticTracks

- (instancetype)init
{
    self = [super init];
    if (self) {
        _contextManager = [TracksContextManager new];
        _tracksService = [[TracksService alloc] initWithContextManager:_contextManager];
    }
    return self;
}

- (void)track:(WPAnalyticsStat)stat
{
    [self track:stat withProperties:nil];
}

- (void)track:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties
{
    TracksEventPair *eventPair = [self eventPairForStat:stat];
    if (!eventPair) {
        DDLogInfo(@"WPAnalyticsStat not supported by WPAnalyticsTrackerAutomatticTracks: %@", @(stat));
        return;
    }
    
    NSMutableDictionary *mergedProperties = [NSMutableDictionary new];

    [mergedProperties addEntriesFromDictionary:eventPair.properties];
    [mergedProperties addEntriesFromDictionary:properties];

    [self.tracksService trackEventName:eventPair.eventName withCustomProperties:mergedProperties];
}

- (void)beginSession
{
#ifdef TRACKS_ENABLED
    [self.tracksService switchToAnonymousUserWithAnonymousID:self.anonymousID];
#endif
    [self refreshMetadata];
}

- (void)endSession
{
    self.anonymousID = nil;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:TracksUserDefaultsAnonymousUserIDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)refreshMetadata
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    __block NSUInteger blogCount;
    __block NSString *username;
    __block NSNumber *userID;
    __block NSString *emailAddress;
    __block BOOL accountPresent = NO;
    __block BOOL jetpackBlogsPresent = NO;
    [context performBlockAndWait:^{
        AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
        WPAccount *account = [accountService defaultWordPressComAccount];
        BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
        
        blogCount = [blogService blogCountForAllAccounts];
        jetpackBlogsPresent = [blogService hasAnyJetpackBlogs];
        if (account != nil) {
            username = account.username;
            userID = nil;
            emailAddress = account.email;
            accountPresent = YES;
        }
    }];
    
    BOOL dotcom_user = NO;
    if (accountPresent) {
        dotcom_user = YES;
    }
    
    NSMutableDictionary *userProperties = [NSMutableDictionary new];
    userProperties[@"platform"] = @"iOS";
    userProperties[@"dotcom_user"] = @(dotcom_user);
    userProperties[@"jetpack_user"] = @(jetpackBlogsPresent);
    userProperties[@"number_of_blogs"] = @(blogCount);
    userProperties[@"accessibility_voice_over_enabled"] = @(UIAccessibilityIsVoiceOverRunning());

    [self.tracksService.userProperties removeAllObjects];
    [self.tracksService.userProperties addEntriesFromDictionary:userProperties];
    
    if (dotcom_user == YES && [username length] > 0) {
        [self.tracksService switchToAuthenticatedUserWithUsername:username userID:@"" skipAliasEventCreation:NO];
    }
}

- (void)beginTimerForStat:(WPAnalyticsStat)stat
{
    
}

- (void)endTimerForStat:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties
{
    
}


#pragma mark - Private methods

- (NSString *)anonymousID
{
    if (_anonymousID == nil || _anonymousID.length == 0) {
        NSString *anonymousID = [[NSUserDefaults standardUserDefaults] stringForKey:TracksUserDefaultsAnonymousUserIDKey];
        if (anonymousID == nil) {
            anonymousID = [[NSUUID UUID] UUIDString];
            [[NSUserDefaults standardUserDefaults] setObject:anonymousID forKey:TracksUserDefaultsAnonymousUserIDKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        _anonymousID = anonymousID;
    }
    
    return _anonymousID;
}

- (TracksEventPair *)eventPairForStat:(WPAnalyticsStat)stat
{
    NSString *eventName;
    NSDictionary *eventProperties;
    
    switch (stat) {
        case WPAnalyticsStatAddedSelfHostedSite:
            eventName = @"self_hosted_blog_added";
            break;
        case WPAnalyticsStatAddedSelfHostedSiteButJetpackNotConnectedToWPCom:
            eventName = @"self_hosted_blog_added_jetpack_not_connected";
            break;
        case WPAnalyticsStatAppInstalled:
            eventName = @"application_installed";
            break;
        case WPAnalyticsStatAppUpgraded:
            eventName = @"application_upgraded";
            break;
        case WPAnalyticsStatApplicationOpened:
            eventName = @"application_opened";
            break;
        case WPAnalyticsStatApplicationClosed:
            eventName = @"application_closed";
            break;
        case WPAnalyticsStatAppReviewsCanceledFeedbackScreen:
            eventName = @"app_reviews_feedback_screen_canceled";
            break;
        case WPAnalyticsStatAppReviewsDeclinedToRateApp:
            eventName = @"app_reviews_declined_to_rate_app";
            break;
        case WPAnalyticsStatAppReviewsDidntLikeApp:
            eventName = @"app_reviews_didnt_like_app";
            break;
        case WPAnalyticsStatAppReviewsLikedApp:
            eventName = @"app_reviews_liked_app";
            break;
        case WPAnalyticsStatAppReviewsOpenedFeedbackScreen:
            eventName = @"app_reviews_feedback_screen_opened";
            break;
        case WPAnalyticsStatAppReviewsRatedApp:
            eventName = @"app_reviews_rated_app";
            break;
        case WPAnalyticsStatAppReviewsSawPrompt:
            eventName = @"app_reviews_saw_prompt";
            break;
        case WPAnalyticsStatAppReviewsSentFeedback:
            eventName = @"app_reviews_feedback_sent";
            break;
        case WPAnalyticsStatCreatedAccount:
            eventName = @"account_created";
            break;
        case WPAnalyticsStatEditorAddedPhotoViaLocalLibrary:
            eventName = @"editor_photo_added";
            eventProperties = @{ @"via" : @"local_library" };
            break;
        case WPAnalyticsStatEditorAddedPhotoViaWPMediaLibrary:
            eventName = @"editor_photo_added";
            eventProperties = @{ @"via" : @"media_library" };
            break;
        case WPAnalyticsStatEditorAddedVideoViaLocalLibrary:
            eventName = @"editor_video_added";
            eventProperties = @{ @"via" : @"local_library" };
            break;
        case WPAnalyticsStatEditorAddedVideoViaWPMediaLibrary:
            eventName = @"editor_video_added";
            eventProperties = @{ @"via" : @"media_library" };
            break;
        case WPAnalyticsStatEditorClosed:
            eventName = @"editor_closed";
            break;
        case WPAnalyticsStatEditorCreatedPost:
            eventName = @"editor_post_created";
            break;
        case WPAnalyticsStatEditorDiscardedChanges:
            eventName = @"editor_discarded_changes";
            break;
        case WPAnalyticsStatEditorEditedImage:
            eventName = @"editor_image_edited";
            break;
        case WPAnalyticsStatEditorEnabledNewVersion:
            eventName = @"editor_enabled_new_version";
            break;
        case WPAnalyticsStatEditorSavedDraft:
            eventName = @"editor_draft_saved";
            break;
        case WPAnalyticsStatEditorScheduledPost:
            eventName = @"editor_post_scheduled";
            break;
        case WPAnalyticsStatEditorPublishedPost:
            eventName = @"editor_post_published";
            break;
        case WPAnalyticsStatEditorTappedBlockquote:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"blockquote" };
            break;
        case WPAnalyticsStatEditorTappedBold:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"bold" };
            break;
        case WPAnalyticsStatEditorTappedHTML:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"html" };
            break;
        case WPAnalyticsStatEditorTappedImage:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"image" };
            break;
        case WPAnalyticsStatEditorTappedItalic:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"italic" };
            break;
        case WPAnalyticsStatEditorTappedLink:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"link" };
            break;
        case WPAnalyticsStatEditorTappedMore:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"more" };
            break;
        case WPAnalyticsStatEditorTappedOrderedList:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"ordered_list" };
            break;
        case WPAnalyticsStatEditorTappedStrikethrough:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"strikethrough" };
            break;
        case WPAnalyticsStatEditorTappedUnderline:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"underline" };
            break;
        case WPAnalyticsStatEditorTappedUnlink:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"unlink" };
            break;
        case WPAnalyticsStatEditorTappedUnorderedList:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"unordered_list" };
            break;
        case WPAnalyticsStatEditorToggledOff:
            eventName = @"editor_toggled_off";
            break;
        case WPAnalyticsStatEditorToggledOn:
            eventName = @"editor_toggled_on";
            break;
        case WPAnalyticsStatEditorUpdatedPost:
            eventName = @"editor_post_update";
            break;
        case WPAnalyticsStatEditorUploadMediaFailed:
            eventName = @"editor_upload_media_failed";
            break;
        case WPAnalyticsStatEditorUploadMediaRetried:
            eventName = @"editor_upload_media_retried";
            break;
        case WPAnalyticsStatLogSpecialCondition:
            eventName = @"log_special_condition";
            break;
        case WPAnalyticsStatLoginFailed:
            eventName = @"login_failed_to_login";
            break;
        case WPAnalyticsStatLoginFailedToGuessXMLRPC:
            eventName = @"login_failed_to_guess_xmlrpc";
            break;
        case WPAnalyticsStatLogout:
            eventName = @"account_logout";
            break;
        case WPAnalyticsStatLowMemoryWarning:
            eventName = @"application_low_memory_warning";
            break;
        case WPAnalyticsStatNotificationsCommentApproved:
            eventName = @"notifications_approved";
            break;
        case WPAnalyticsStatNotificationsCommentFlaggedAsSpam:
            eventName = @"notifications_flagged_as_spam";
            break;
        case WPAnalyticsStatNotificationsSiteFollowAction:
            eventName = @"notifications_follow_action";
            break;
        case WPAnalyticsStatNotificationsCommentLiked:
            eventName = @"notifications_comment_liked";
            break;
        case WPAnalyticsStatNotificationsCommentRepliedTo:
            eventName = @"notifications_replied_to";
            break;
        case WPAnalyticsStatNotificationsCommentTrashed:
            eventName = @"notifications_comment_trashed";
            break;
        case WPAnalyticsStatNotificationsCommentUnapproved:
            eventName = @"notifications_comment_unapproved";
            break;
        case WPAnalyticsStatNotificationsSiteUnfollowAction:
            eventName = @"notifications_unfollow_action";
            break;
        case WPAnalyticsStatNotificationsCommentUnliked:
            eventName = @"notifications_comment_unliked";
            break;
        case WPAnalyticsStatNotificationsMissingSyncWarning:
            eventName = @"notifications_missing_sync_warning";
            break;
        case WPAnalyticsStatNotificationsSettingsUpdated:
            eventName = @"notification_settings_updated";
            break;
        case WPAnalyticsStatOnePasswordFailed:
            eventName = @"one_password_failed";
            break;
        case WPAnalyticsStatOnePasswordLogin:
            eventName = @"one_password_login";
            break;
        case WPAnalyticsStatOnePasswordSignup:
            eventName = @"one_password_signup";
            break;
        case WPAnalyticsStatOpenedComments:
            eventName = @"site_menu_opened";
            eventProperties = @{ TracksEventPropertyMenuItemKey : @"comments" };
            break;
        case WPAnalyticsStatOpenedMediaLibrary:
            eventName = @"site_menu_opened";
            eventProperties = @{ TracksEventPropertyMenuItemKey : @"library" };
            break;
        case WPAnalyticsStatOpenedNotificationsList:
            eventName = @"notifications_accessed";
            break;
        case WPAnalyticsStatOpenedNotificationDetails:
            eventName = @"notifications_notification_details_opened";
            break;
        case WPAnalyticsStatOpenedNotificationSettingsList:
            eventName = @"notification_settings_list_opened";
            break;
        case WPAnalyticsStatOpenedNotificationSettingStreams:
            eventName = @"notification_settings_streams_opened";
            break;
        case WPAnalyticsStatOpenedNotificationSettingDetails:
            eventName = @"notification_settings_details_opened";
            break;
        case WPAnalyticsStatOpenedPages:
            eventName = @"site_menu_opened";
            eventProperties = @{ TracksEventPropertyMenuItemKey : @"pages" };
            break;
        case WPAnalyticsStatOpenedPosts:
            eventName = @"site_menu_opened";
            eventProperties = @{ TracksEventPropertyMenuItemKey : @"posts" };
            break;
        case WPAnalyticsStatOpenedSiteSettings:
            eventName = @"site_menu_opened";
            eventProperties = @{ TracksEventPropertyMenuItemKey : @"settings" };
            break;
        case WPAnalyticsStatOpenedSupport:
            eventName = @"support_opened";
            break;
        case WPAnalyticsStatOpenedViewAdmin:
            eventName = @"site_menu_view_admin_opened";
            break;
        case WPAnalyticsStatOpenedViewSite:
            eventName = @"site_menu_view_site_opened";
            break;
        case WPAnalyticsStatPerformedJetpackSignInFromStatsScreen:
            eventName = @"stats_screen_signed_into_jetpack";
            break;
        case WPAnalyticsStatPostListAuthorFilterChanged:
            eventName = @"post_list_author_filter_changed";
            break;
        case WPAnalyticsStatPostListDraftAction:
            eventName = @"post_list_button_pressed";
            eventProperties = @{ TracksEventPropertyButtonKey : @"draft" };
            break;
        case WPAnalyticsStatPostListEditAction:
            eventName = @"post_list_button_pressed";
            eventProperties = @{ TracksEventPropertyButtonKey : @"edit" };
            break;
        case WPAnalyticsStatPostListLoadedMore:
            eventName = @"post_list_load_more_triggered";
            break;
        case WPAnalyticsStatPostListNoResultsButtonPressed:
            eventName = @"post_list_button_pressed";
            eventProperties = @{ TracksEventPropertyButtonKey : @"no_results" };
            break;
        case WPAnalyticsStatPostListOpenedCellMenu:
            eventName = @"post_list_cell_menu_opened";
            break;
        case WPAnalyticsStatPostListPublishAction:
            eventName = @"post_list_button_pressed";
            eventProperties = @{ TracksEventPropertyButtonKey : @"publish" };
            break;
        case WPAnalyticsStatPostListPullToRefresh:
            eventName = @"post_list_pull_to_refresh_triggered";
            break;
        case WPAnalyticsStatPostListRestoreAction:
            eventName = @"post_list_button_pressed";
            eventProperties = @{ TracksEventPropertyButtonKey : @"restore" };
            break;
        case WPAnalyticsStatPostListSearchOpened:
            eventName = @"post_list_search_opened";
            break;
        case WPAnalyticsStatPostListStatsAction:
            eventName = @"post_list_button_pressed";
            eventProperties = @{ TracksEventPropertyButtonKey : @"stats" };
            break;
        case WPAnalyticsStatPostListStatusFilterChanged:
            eventName = @"post_list_status_filter_changed";
            break;
        case WPAnalyticsStatPostListTrashAction:
            eventName = @"post_list_button_pressed";
            eventProperties = @{ TracksEventPropertyButtonKey : @"trash" };
            break;
        case WPAnalyticsStatPostListViewAction:
            eventName = @"post_list_button_pressed";
            eventProperties = @{ TracksEventPropertyButtonKey : @"view" };
            break;
        case WPAnalyticsStatPushAuthenticationApproved:
            eventName = @"push_authentication_approved";
            break;
        case WPAnalyticsStatPushAuthenticationExpired:
            eventName = @"push_authentication_expired";
            break;
        case WPAnalyticsStatPushAuthenticationFailed:
            eventName = @"push_authentication_failed";
            break;
        case WPAnalyticsStatPushAuthenticationIgnored:
            eventName = @"push_authentication_ignored";
            break;
        case WPAnalyticsStatPushNotificationAlertPressed:
            eventName = @"push_notification_alert_tapped";
            break;
        case WPAnalyticsStatPushNotificationReceived:
            eventName = @"push_notification_received";
            break;
        case WPAnalyticsStatReaderAccessed:
            eventName = @"reader_accessed";
            break;
        case WPAnalyticsStatReaderArticleCommentedOn:
            eventName = @"reader_article_commented_on";
            break;
        case WPAnalyticsStatReaderArticleLiked:
            eventName = @"reader_article_liked";
            break;
        case WPAnalyticsStatReaderArticleReblogged:
            eventName = @"reader_article_reblogged";
            break;
        case WPAnalyticsStatReaderArticleOpened:
            eventName = @"reader_article_opened";
            break;
        case WPAnalyticsStatReaderArticleUnliked:
            eventName = @"reader_article_unliked";
            break;
        case WPAnalyticsStatReaderDiscoverViewed:
            eventName = @"reader_discover_viewed";
            break;
        case WPAnalyticsStatReaderFreshlyPressedLoaded:
            eventName = @"reader_freshly_pressed_loaded";
            break;
        case WPAnalyticsStatReaderInfiniteScroll:
            eventName = @"reader_infinite_scroll_performed";
            break;
        case WPAnalyticsStatReaderListFollowed:
            eventName = @"reader_list_followed";
            break;
        case WPAnalyticsStatReaderListLoaded:
            eventName = @"reader_list_loaded";
            break;
        case WPAnalyticsStatReaderListPreviewed:
            eventName = @"reader_list_preview";
            break;
        case WPAnalyticsStatReaderListUnfollowed:
            eventName = @"reader_list_unfollowed";
            break;
        case WPAnalyticsStatReaderSiteBlocked:
            eventName = @"reader_blog_blocked";
            break;
        case WPAnalyticsStatReaderSiteFollowed:
            eventName = @"reader_site_followed";
            break;
        case WPAnalyticsStatReaderSitePreviewed:
            eventName = @"reader_blog_preview";
            break;
        case WPAnalyticsStatReaderSiteUnfollowed:
            eventName = @"reader_site_unfollowed";
            break;
        case WPAnalyticsStatReaderTagFollowed:
            eventName = @"reader_reader_tag_followed";
            break;
        case WPAnalyticsStatReaderTagLoaded:
            eventName = @"reader_tag_loaded";
            break;
        case WPAnalyticsStatReaderTagPreviewed:
            eventName = @"reader_tag_preview";
            break;
        case WPAnalyticsStatReaderTagUnfollowed:
            eventName = @"reader_reader_tag_unfollowed";
            break;
        case WPAnalyticsStatSafariCredentialsLoginFilled:
            eventName = @"safari_credentials_login_filled";
            break;
        case WPAnalyticsStatSafariCredentialsLoginUpdated:
            eventName = @"safari_credentials_login_updated";
            break;
        case WPAnalyticsStatSelectedInstallJetpack:
            eventName = @"stats_install_jetpack_selected";
            break;
        case WPAnalyticsStatSentItemToGooglePlus:
            eventName = @"sent_item_to_google_plus";
            break;
        case WPAnalyticsStatSentItemToInstapaper:
            eventName = @"sent_item_to_instapaper";
            break;
        case WPAnalyticsStatSentItemToPocket:
            eventName = @"sent_item_to_pocket";
            break;
        case WPAnalyticsStatSentItemToWordPress:
            eventName = @"sent_item_to_wordpress";
            break;
        case WPAnalyticsStatSharedItem:
            eventName = @"shared_item";
            break;
        case WPAnalyticsStatSharedItemViaEmail:
            eventName = @"shared_item_via_email";
            break;
        case WPAnalyticsStatSharedItemViaFacebook:
            eventName = @"shared_item_via_facebook";
            break;
        case WPAnalyticsStatSharedItemViaSMS:
            eventName = @"shared_item_via_sms";
            break;
        case WPAnalyticsStatSharedItemViaTwitter:
            eventName = @"shared_item_via_twitter";
            break;
        case WPAnalyticsStatSharedItemViaWeibo:
            eventName = @"shared_item_via_weibo";
            break;
        case WPAnalyticsStatShortcutLogIn:
            eventName = @"3d_touch_shortcut_log_in";
            break;
        case WPAnalyticsStatShortcutNewPost:
            eventName = @"3d_touch_shortcut_new_post";
            break;
        case WPAnalyticsStatShortcutNotifications:
            eventName = @"3d_touch_shortcut_notifications";
            break;
        case WPAnalyticsStatShortcutNewPhotoPost:
            eventName = @"3d_touch_shortcut_new_photo_post";
            break;
        case WPAnalyticsStatShortcutStats:
            eventName = @"3d_touch_shortcut_stats";
            break;
        case WPAnalyticsStatSignedIn:
            eventName = @"signed_in";
            break;
        case WPAnalyticsStatSignedInToJetpack:
            eventName = @"signed_into_jetpack";
            break;
        case WPAnalyticsStatSkippedConnectingToJetpack:
            eventName = @"skipped_connecting_to_jetpack";
            break;
        case WPAnalyticsStatStatsAccessed:
            eventName = @"stats_accessed";
            break;
        case WPAnalyticsStatStatsInsightsAccessed:
            eventName = @"stats_insights_accessed";
            break;
        case WPAnalyticsStatStatsPeriodDaysAccessed:
            eventName = @"stats_period_accessed";
            eventProperties = @{ @"period" : @"days" };
            break;
        case WPAnalyticsStatStatsPeriodMonthsAccessed:
            eventName = @"stats_period_accessed";
            eventProperties = @{ @"period" : @"months" };
            break;
        case WPAnalyticsStatStatsPeriodWeeksAccessed:
            eventName = @"stats_period_accessed";
            eventProperties = @{ @"period" : @"weeks" };
            break;
        case WPAnalyticsStatStatsPeriodYearsAccessed:
            eventName = @"stats_period_accessed";
            eventProperties = @{ @"period" : @"years" };
            break;
        case WPAnalyticsStatStatsOpenedWebVersion:
            eventName = @"stats_opened_web_version_accessed";
            break;
        case WPAnalyticsStatStatsScrolledToBottom:
            eventName = @"stats_scrolled_to_bottom";
            break;
        case WPAnalyticsStatSelectedLearnMoreInConnectToJetpackScreen:
            eventName = @"selected_learn_more_in_connect_to_jetpack";
            break;
        case WPAnalyticsStatStatsSinglePostAccessed:
            eventName = @"stats_single_post_accessed";
            break;
        case WPAnalyticsStatStatsTappedBarChart:
            eventName = @"stats_bar_chart_tapped";
            break;
        case WPAnalyticsStatStatsViewAllAccessed:
            eventName = @"stats_view_all_accessed";
            break;
        case WPAnalyticsStatSupportOpenedHelpshiftScreen:
            eventName = @"support_opened_helpshift_screen";
            break;
        case WPAnalyticsStatSupportReceivedResponseFromSupport:
            eventName = @"support_received_response_from_support";
            break;
        case WPAnalyticsStatSupportSentMessage:
            eventName = @"support_sent_message";
            break;
        case WPAnalyticsStatSupportSentReplyToSupportMessage:
            eventName = @"support_sent_reply_to_support_message";
            break;
        case WPAnalyticsStatSupportUserRepliedToHelpshift:
            eventName = @"support_user_replied_to_helpshift";
            break;
        case WPAnalyticsStatThemesAccessedThemeBrowser:
            eventName = @"themes_theme_browser_accessed";
            break;
        case WPAnalyticsStatThemesAccessedSearch:
            eventName = @"themes_search_accessed";
            break;
        case WPAnalyticsStatThemesChangedTheme:
            eventName = @"themes_theme_changed";
            break;
        case WPAnalyticsStatThemesCustomizeAccessed:
            eventName = @"themes_customize_accessed";
            break;
        case WPAnalyticsStatThemesDemoAccessed:
            eventName = @"themes_demo_accessed";
            break;
        case WPAnalyticsStatThemesDetailsAccessed:
            eventName = @"themes_details_accessed";
            break;
        case WPAnalyticsStatThemesPreviewedSite:
            eventName = @"themes_theme_for_site_previewed";
            break;
        case WPAnalyticsStatThemesSupportAccessed:
            eventName = @"themes_support_accessed";
            break;
        case WPAnalyticsStatTwoFactorCodeRequested:
            eventName = @"two_factor_code_requested";
            break;
        case WPAnalyticsStatTwoFactorSentSMS:
            eventName = @"two_factor_sent_sms";
            break;
        case WPAnalyticsStatOpenedAccountSettings:
            eventName = @"account_settings_opened";
            break;
        case WPAnalyticsStatOpenedMyProfile:
            eventName = @"my_profile_opened";
            break;
        case WPAnalyticsStatDefaultAccountChanged:
        case WPAnalyticsStatNoStat:
        case WPAnalyticsStatPerformedCoreDataMigrationFixFor45:
        case WPAnalyticsStatMaxValue:
            return nil;
    }

    TracksEventPair *eventPair = [TracksEventPair new];
    eventPair.eventName = eventName;
    eventPair.properties = eventProperties;
    
    return eventPair;
}

@end
