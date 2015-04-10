#import "WPAnalyticsTrackerAutomatticTracks.h"
#import <TracksService.h>
#import "ContextManager.h"
#import "AccountService.h"
#import "BlogService.h"
#import "WPAccount.h"
#import "Blog.h"

@interface WPAnalyticsTrackerAutomatticTracks ()

@property (nonatomic, strong) TracksService *tracksService;
@property (nonatomic, strong) NSDictionary *userProperties;
@property (nonatomic, strong) NSString *anonymousID;

@end

@implementation WPAnalyticsTrackerAutomatticTracks

- (instancetype)init
{
    self = [super init];
    if (self) {
        _tracksService = [TracksService new];
    }
    return self;
}

- (void)track:(WPAnalyticsStat)stat
{
    [self track:stat withProperties:nil];
}

- (void)track:(WPAnalyticsStat)stat withProperties:(NSDictionary *)properties
{
    NSString *eventName = [self eventNameForStat:stat];
    
    if (eventName.length == 0) {
        return;
    }
    
    [self.tracksService trackEventName:eventName withCustomProperties:properties];
}

- (void)beginSession
{
    NSString *anonymousID = [[NSUserDefaults standardUserDefaults] stringForKey:@"TracksAnonymousUserID"];
    if (!anonymousID) {
        anonymousID = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:anonymousID forKey:@"TracksAnonymousUserID"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    self.anonymousID = anonymousID;
    
    [self refreshMetadata];
}

- (void)endSession
{
    
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
        if (account != nil) {
            username = account.username;
            userID = nil;
            emailAddress = account.email;
            accountPresent = YES;
            jetpackBlogsPresent = [account jetpackBlogs].count > 0;
        }
    }];
    
    BOOL dotcom_user = NO;
    BOOL jetpack_user = NO;
    if (accountPresent) {
        dotcom_user = YES;
        if (jetpackBlogsPresent) {
            jetpack_user = YES;
        }
    }
    
    NSMutableDictionary *userProperties = [NSMutableDictionary new];
    userProperties[@"platform"] = @"iOS";
    userProperties[@"dotcom_user"] = @(dotcom_user);
    userProperties[@"jetpack_user"] = @(jetpack_user);
    userProperties[@"number_of_blogs"] = @(blogCount);
    userProperties[@"accessibility_voice_over_enabled"] = @(UIAccessibilityIsVoiceOverRunning());
    self.tracksService.userProperties = userProperties;
    
    [self.tracksService switchToAnonymousUserWithAnonymousID:self.anonymousID];
    
    if (accountPresent && [username length] > 0) {
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

- (NSString *)eventNameForStat:(WPAnalyticsStat)stat
{
    NSString *eventName;
    
    switch (stat) {
        case WPAnalyticsStatAddedSelfHostedSite:
            eventName = @"added_self_hosted_blog";
            break;
        case WPAnalyticsStatAddedSelfHostedSiteButJetpackNotConnectedToWPCom:
            eventName = @"added_self_hosted_blog_jetpack_not_connected";
            break;
        case WPAnalyticsStatAppInstalled:
            eventName = @"application_installed";
            break;
        case WPAnalyticsStatApplicationOpened:
            eventName = @"application_opened";
            break;
        case WPAnalyticsStatApplicationClosed:
            eventName = @"application_closed";
            break;
        case WPAnalyticsStatAppReviewsCanceledFeedbackScreen:
            eventName = @"app_reviews_canceled_feedback_screen";
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
            eventName = @"app_reviews_opened_feedback_screen";
            break;
        case WPAnalyticsStatAppReviewsRatedApp:
            eventName = @"app_reviews_rated_app";
            break;
        case WPAnalyticsStatAppReviewsSawPrompt:
            eventName = @"app_reviews_saw_prompt";
            break;
        case WPAnalyticsStatAppReviewsSentFeedback:
            eventName = @"app_reviews_sent_feedback";
            break;
        case WPAnalyticsStatCreatedAccount:
            eventName = @"created_account";
            break;
        case WPAnalyticsStatEditorAddedPhotoViaLocalLibrary:
            eventName = @"editor_added_photo_via_local_library";
            break;
        case WPAnalyticsStatEditorAddedPhotoViaWPMediaLibrary:
            eventName = @"editor_added_photo_via_wp_media_library";
            break;
        case WPAnalyticsStatEditorClosed:
            eventName = @"editor_closed";
            break;
        case WPAnalyticsStatEditorCreatedPost:
            eventName = @"editor_created_post";
            break;
        case WPAnalyticsStatPublishedPostWithCategories:
            eventName = @"editor_published_post_with_categories";
            break;
        case WPAnalyticsStatPublishedPostWithPhoto:
            eventName = @"editor_published_post_with_photos";
            break;
        case WPAnalyticsStatPublishedPostWithTags:
            eventName = @"editor_published_post_with_tags";
            break;
        case WPAnalyticsStatPublishedPostWithVideo:
            eventName = @"editor_published_post_with_videos";
            break;
        case WPAnalyticsStatEditorDiscardedChanges:
            eventName = @"editor_discarded_changes";
            break;
        case WPAnalyticsStatEditorEditedImage:
            eventName = @"editor_edited_image";
            break;
        case WPAnalyticsStatEditorEnabledNewVersion:
            eventName = @"editor_enabled_new_version";
            break;
        case WPAnalyticsStatEditorSavedDraft:
            eventName = @"editor_saved_draft";
            break;
        case WPAnalyticsStatEditorScheduledPost:
            eventName = @"editor_scheduled_post";
            break;
        case WPAnalyticsStatEditorPublishedPost:
            eventName = @"editor_published_post";
            break;
        case WPAnalyticsStatEditorTappedBlockquote:
            eventName = @"editor_tapped_blockquote_button";
            break;
        case WPAnalyticsStatEditorTappedBold:
            eventName = @"editor_tapped_bold_button";
            break;
        case WPAnalyticsStatEditorTappedHTML:
            eventName = @"editor_tapped_html";
            break;
        case WPAnalyticsStatEditorTappedImage:
            eventName = @"editor_tapped_image_button";
            break;
        case WPAnalyticsStatEditorTappedItalic:
            eventName = @"editor_tapped_italic_button";
            break;
        case WPAnalyticsStatEditorTappedLink:
            eventName = @"editor_tapped_link_button";
            break;
        case WPAnalyticsStatEditorTappedMore:
            eventName = @"editor_tapped_more_button";
            break;
        case WPAnalyticsStatEditorTappedOrderedList:
            eventName = @"editor_tapped_ordered_list";
            break;
        case WPAnalyticsStatEditorTappedStrikethrough:
            eventName = @"editor_tapped_strikethrough_button";
            break;
        case WPAnalyticsStatEditorTappedUnderline:
            eventName = @"editor_tapped_underline_button";
            break;
        case WPAnalyticsStatEditorTappedUnlink:
            eventName = @"editor_tapped_unlink";
            break;
        case WPAnalyticsStatEditorTappedUnorderedList:
            eventName = @"editor_tapped_unordered_list";
            break;
        case WPAnalyticsStatEditorToggledOff:
            eventName = @"editor_toggled_off";
            break;
        case WPAnalyticsStatEditorToggledOn:
            eventName = @"editor_toggled_on";
            break;
        case WPAnalyticsStatEditorUpdatedPost:
            eventName = @"editor_update_post";
            break;
        case WPAnalyticsStatEditorUploadMediaFailed:
            eventName = @"editor_upload_media_failed";
            break;
        case WPAnalyticsStatEditorUploadMediaRetried:
            eventName = @"editor_upload_media_retried";
            break;
        case WPAnalyticsStatLoginFailed:
            eventName = @"login_failed_login";
            break;
        case WPAnalyticsStatLoginFailedToGuessXMLRPC:
            eventName = @"login_failed_to_guess_xmlrpc";
            break;
        case WPAnalyticsStatLogout:
            eventName = @"logout";
            break;
        case WPAnalyticsStatLowMemoryWarning:
            eventName = @"low_memory_warning";
            break;
        case WPAnalyticsStatNotificationsAccessed:
            eventName = @"notifications_accessed";
            break;
        case WPAnalyticsStatNotificationApproved:
            eventName = @"notifications_approved";
            break;
        case WPAnalyticsStatNotificationFlaggedAsSpam:
            eventName = @"notifications_flagged_as_spam";
            break;
        case WPAnalyticsStatNotificationFollowAction:
            eventName = @"notifications_follow_action";
            break;
        case WPAnalyticsStatNotificationLiked:
            eventName = @"notifications_liked_comment";
            break;
        case WPAnalyticsStatNotificationRepliedTo:
            eventName = @"notifications_replied_to";
            break;
        case WPAnalyticsStatNotificationTrashed:
            eventName = @"notifications_trashed";
            break;
        case WPAnalyticsStatNotificationUnapproved:
            eventName = @"notifications_unapproved";
            break;
        case WPAnalyticsStatNotificationUnfollowAction:
            eventName = @"notifications_unfollow_action";
            break;
        case WPAnalyticsStatNotificationUnliked:
            eventName = @"notifications_unliked_comment";
            break;
        case WPAnalyticsStatNotificationsMissingSyncWarning:
            eventName = @"notifications_missing_sync_warning";
            break;
        case WPAnalyticsStatNotificationsOpenedNotificationDetails:
            eventName = @"notifications_opened_notification_details";
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
            eventName = @"site_menu_opened_comments";
            break;
        case WPAnalyticsStatOpenedMediaLibrary:
            eventName = @"site_menu_opened_media_library";
            break;
        case WPAnalyticsStatOpenedPages:
            eventName = @"site_menu_opened_pages";
            break;
        case WPAnalyticsStatOpenedPosts:
            eventName = @"site_menu_opened_posts";
            break;
        case WPAnalyticsStatOpenedSettings:
            eventName = @"site_menu_opened_settings";
            break;
        case WPAnalyticsStatOpenedSupport:
            eventName = @"opened_support";
            break;
        case WPAnalyticsStatOpenedViewAdmin:
            eventName = @"site_menu_opened_view_admin";
            break;
        case WPAnalyticsStatOpenedViewSite:
            eventName = @"site_menu_opened_view_site";
            break;
        case WPAnalyticsStatPerformedJetpackSignInFromStatsScreen:
            eventName = @"signed_into_jetpack_from_stats_screen";
            break;
        case WPAnalyticsStatPushNotificationAlertPressed:
            eventName = @"push_notification_alert_tapped";
            break;
        case WPAnalyticsStatReaderAccessed:
            eventName = @"reader_accessed";
            break;
        case WPAnalyticsStatReaderCommentedOnArticle:
            eventName = @"reader_commented_on_article";
            break;
        case WPAnalyticsStatReaderFollowedReaderTag:
            eventName = @"reader_followed_reader_tag";
            break;
        case WPAnalyticsStatReaderFollowedSite:
            eventName = @"reader_followed_site";
            break;
        case WPAnalyticsStatReaderInfiniteScroll:
            eventName = @"reader_infinite_scroll_performed";
            break;
        case WPAnalyticsStatReaderLikedArticle:
            eventName = @"reader_liked_article";
            break;
        case WPAnalyticsStatReaderLoadedFreshlyPressed:
            eventName = @"reader_loaded_freshly_pressed";
            break;
        case WPAnalyticsStatReaderLoadedTag:
            eventName = @"reader_loaded_tag";
            break;
        case WPAnalyticsStatReaderOpenedArticle:
            eventName = @"reader_opened_article";
            break;
        case WPAnalyticsStatReaderPreviewedSite:
            eventName = @"reader_blog_preview";
            break;
        case WPAnalyticsStatReaderRebloggedArticle:
            eventName = @"reader_reblogged_article";
            break;
        case WPAnalyticsStatReaderUnfollowedReaderTag:
            eventName = @"reader_unfollowed_reader_tag";
            break;
        case WPAnalyticsStatSelectedInstallJetpack:
            eventName = @"stats_selected_install_jetpack";
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
            eventName = @"stats_tapped_bar_chart";
            break;
        case WPAnalyticsStatStatsViewAllAccessed:
            eventName = @"stats_view_all_accessed";
            break;
        case WPAnalyticsStatSupportOpenedHelpshiftScreen:
            eventName = @"support_opened_helpshift_screen";
            break;
        case WPAnalyticsStatSupportReceivedResponseFromSupport:
            eventName = @"support_recieved_response_from_support";
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
            eventName = @"themes_accessed_theme_browser";
            break;
        case WPAnalyticsStatThemesChangedTheme:
            eventName = @"themes_changed_theme";
            break;
        case WPAnalyticsStatTwoFactorCodeRequested:
            eventName = @"two_factor_code_requested";
            break;
        case WPAnalyticsStatTwoFactorSentSMS:
            eventName = @"two_factor_sent_sms";
            break;
            
        case WPAnalyticsStatAppUpgraded:
        case WPAnalyticsStatDefaultAccountChanged:
        case WPAnalyticsStatNoStat:
        case WPAnalyticsStatPerformedCoreDataMigrationFixFor45:
            eventName = nil;
            break;
    }

    return eventName;
}

@end
