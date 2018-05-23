#import "WPAnalyticsTrackerAutomatticTracks.h"
#import "ContextManager.h"
#import "AccountService.h"
#import "BlogService.h"
#import "WPAccount.h"
#import "Blog.h"
@import AutomatticTracks;

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
@property (nonatomic, strong) NSString *loggedInID;

@end

NSString *const TracksEventPropertyButtonKey = @"button";
NSString *const TracksEventPropertyMenuItemKey = @"menu_item";
NSString *const TracksUserDefaultsAnonymousUserIDKey = @"TracksAnonymousUserID";
NSString *const TracksUserDefaultsLoggedInUserIDKey = @"TracksLoggedInUserID";

@implementation WPAnalyticsTrackerAutomatticTracks

@synthesize loggedInID = _loggedInID;
@synthesize anonymousID = _anonymousID;

+ (NSString *)eventNameForStat:(WPAnalyticsStat)stat
{
    return [self eventPairForStat:stat].eventName;
}

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
    TracksEventPair *eventPair = [[self class] eventPairForStat:stat];
    if (!eventPair) {
        DDLogInfo(@"WPAnalyticsStat not supported by WPAnalyticsTrackerAutomatticTracks: %@", @(stat));
        return;
    }

    NSMutableDictionary *mergedProperties = [NSMutableDictionary new];

    [mergedProperties addEntriesFromDictionary:eventPair.properties];
    [mergedProperties addEntriesFromDictionary:properties];

    if (eventPair.properties == nil && properties == nil) {
        DDLogInfo(@"🔵 Tracked: %@", eventPair.eventName);
    } else {
        DDLogInfo(@"🔵 Tracked: %@, properties: %@", eventPair.eventName, mergedProperties);
    }

    [self.tracksService trackEventName:eventPair.eventName withCustomProperties:mergedProperties];
}

- (void)beginSession
{
    if (self.loggedInID.length > 0) {
        [self.tracksService switchToAuthenticatedUserWithUsername:self.loggedInID userID:nil skipAliasEventCreation:YES];
    } else {
        [self.tracksService switchToAnonymousUserWithAnonymousID:self.anonymousID];
    }

    [self refreshMetadata];
}

- (void)clearQueuedEvents
{
    [self.tracksService clearQueuedEvents];
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
    
    BOOL dotcom_user = (accountPresent && username.length > 0);
    
    NSMutableDictionary *userProperties = [NSMutableDictionary new];
    userProperties[@"platform"] = @"iOS";
    userProperties[@"dotcom_user"] = @(dotcom_user);
    userProperties[@"jetpack_user"] = @(jetpackBlogsPresent);
    userProperties[@"number_of_blogs"] = @(blogCount);
    userProperties[@"accessibility_voice_over_enabled"] = @(UIAccessibilityIsVoiceOverRunning());
    userProperties[@"is_rtl_language"] = @(UIApplication.sharedApplication.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft);

    [self.tracksService.userProperties removeAllObjects];
    [self.tracksService.userProperties addEntriesFromDictionary:userProperties];

    // Tell the client what kind of user
    if (dotcom_user == YES) {
        if (self.loggedInID.length == 0) {
            // No previous username logged
            self.loggedInID = username;
            self.anonymousID = nil;

            [self.tracksService switchToAuthenticatedUserWithUsername:username userID:@"" skipAliasEventCreation:NO];
        } else if ([self.loggedInID isEqualToString:username]){
            // Username did not change from last refreshMetadata - just make sure Tracks client has it
            [self.tracksService switchToAuthenticatedUserWithUsername:username userID:@"" skipAliasEventCreation:YES];
        } else {
            // Username changed for some reason - switch back to anonymous first
            [self.tracksService switchToAnonymousUserWithAnonymousID:self.anonymousID];
            [self.tracksService switchToAuthenticatedUserWithUsername:username userID:@"" skipAliasEventCreation:NO];
            self.loggedInID = username;
            self.anonymousID = nil;
        }
    } else {
        // User is not authenticated, switch to an anonymous mode
        [self.tracksService switchToAnonymousUserWithAnonymousID:self.anonymousID];
        self.loggedInID = nil;
    }
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

- (void)setAnonymousID:(NSString *)anonymousID
{
    _anonymousID = anonymousID;

    if (anonymousID == nil) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:TracksUserDefaultsAnonymousUserIDKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return;
    }

    [[NSUserDefaults standardUserDefaults] setObject:anonymousID forKey:TracksUserDefaultsAnonymousUserIDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)loggedInID
{
    if (_loggedInID == nil || _loggedInID.length == 0) {
        NSString *loggedInID = [[NSUserDefaults standardUserDefaults] stringForKey:TracksUserDefaultsLoggedInUserIDKey];
        if (loggedInID != nil) {
            _loggedInID = loggedInID;
        }
    }

    return _loggedInID;
}

- (void)setLoggedInID:(NSString *)loggedInID
{
    _loggedInID = loggedInID;

    if (loggedInID == nil) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:TracksUserDefaultsLoggedInUserIDKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return;
    }

    [[NSUserDefaults standardUserDefaults] setObject:loggedInID forKey:TracksUserDefaultsLoggedInUserIDKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (TracksEventPair *)eventPairForStat:(WPAnalyticsStat)stat
{
    NSString *eventName;
    NSDictionary *eventProperties;
    
    switch (stat) {
        case WPAnalyticsStatABTestStart:
            eventName = @"abtest_start";
            break;
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
        case WPAnalyticsStatAppSettingsImageOptimizationChanged:
            eventName = @"app_settings_image_optimization_changed";
            break;
        case WPAnalyticsStatAppSettingsMediaRemoveLocationChanged:
            eventName = @"app_settings_media_remove_location_changed";
            break;
        case WPAnalyticsStatAppSettingsVideoOptimizationChanged:
            eventName = @"app_settings_video_optimization_changed";
            break;
        case WPAnalyticsStatCreateAccountInitiated:
            eventName = @"account_create_initiated";
            break;
        case WPAnalyticsStatCreateAccountEmailExists:
            eventName = @"account_create_email_exists";
            break;
        case WPAnalyticsStatCreateAccountUsernameExists:
            eventName = @"account_create_username_exists";
            break;
        case WPAnalyticsStatCreateAccountFailed:
            eventName = @"account_create_failed";
            break;
        case WPAnalyticsStatCreatedAccount:
            eventName = @"account_created";
            break;
        case WPAnalyticsStatCreatedSite:
            eventName = @"site_created";
            break;
        case WPAnalyticsStatCreateSiteValidationFailed:
            eventName = @"create_site_validation_failed";
            break;
        case WPAnalyticsStatCreateSiteCreationFailed:
            eventName = @"create_site_creation_failed";
            break;
        case WPAnalyticsStatCreateSiteSetTaglineFailed:
            eventName = @"create_site_set_tagline_failed";
            break;
        case WPAnalyticsStatCreateSiteSetThemeFailed:
            eventName = @"create_site_set_theme_failed";
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
        case WPAnalyticsStatEditorAddedOtherMediaViaWPMediaLibrary:
            eventName = @"editor_other_media_added";
            eventProperties = @{ @"via" : @"media_library" };
            break;
        case WPAnalyticsStatEditorAddedVideoViaOtherApps:
            eventName = @"editor_video_added";
            eventProperties = @{ @"via" : @"other_apps" };
            break;
        case WPAnalyticsStatEditorAddedPhotoViaOtherApps:
            eventName = @"editor_photo_added";
            eventProperties = @{ @"via" : @"other_apps" };
            break;
        case WPAnalyticsStatEditorAddedPhotoViaStockPhotos:
            eventName = @"editor_photo_added";
            eventProperties = @{ @"via" : @"stock_photos" };
            break;
        case WPAnalyticsStatEditorAztecBetaLink:
            eventName = @"editor_aztec_beta_link";
            break;
        case WPAnalyticsStatEditorAztecPromoLink:
            eventName = @"editor_aztec_promo_link";
            break;
        case WPAnalyticsStatEditorAztecPromoPositive:
            eventName = @"editor_aztec_promo_positive";
            break;
        case WPAnalyticsStatEditorAztecPromoNegative:
            eventName = @"editor_aztec_promo_negative";
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
        case WPAnalyticsStatEditorResizedPhoto:
            eventName = @"editor_resized_photo";
            break;
        case WPAnalyticsStatEditorResizedPhotoError:
            eventName = @"editor_resized_photo_error";
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
        case WPAnalyticsStatEditorQuickPublishedPost:
            eventName = @"editor_quick_post_published";
            break;
        case WPAnalyticsStatEditorQuickSavedDraft:
            eventName = @"editor_quick_draft_saved";
            break;
        case WPAnalyticsStatEditorTappedBlockquote:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"blockquote" };
            break;
        case WPAnalyticsStatEditorTappedBold:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"bold" };
            break;
        case WPAnalyticsStatEditorTappedHeader:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"header" };
            break;
        case WPAnalyticsStatEditorTappedHeaderSelection:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"header_selection" };
            break;
        case WPAnalyticsStatEditorTappedHorizontalRule:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"horizontal_rule" };
            break;
        case WPAnalyticsStatEditorTappedHTML:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"html" };
            break;
        case WPAnalyticsStatEditorTappedImage:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"image" };
            break;
        case WPAnalyticsStatEditorMediaPickerTappedDismiss:
            eventName = @"media_picker_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"cancel" };
            break;
        case WPAnalyticsStatEditorMediaPickerTappedDevicePhotos:
            eventName = @"media_picker_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"device_photos" };
            break;
        case WPAnalyticsStatEditorMediaPickerTappedCamera:
            eventName = @"media_picker_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"camera" };
            break;
        case WPAnalyticsStatEditorMediaPickerTappedMediaLibrary:
            eventName = @"media_picker_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"media_library" };
            break;
        case WPAnalyticsStatEditorMediaPickerTappedOtherApps:
            eventName = @"media_picker_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"other_apps" };
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
        case WPAnalyticsStatEditorTappedMoreItems:
            eventName = @"editor_button_tapped";
            eventProperties = @{ TracksEventPropertyButtonKey : @"overflow_ellipsis" };
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
        case WPAnalyticsStatGravatarCropped:
            eventName = @"me_gravatar_cropped";
            break;
        case WPAnalyticsStatGravatarTapped:
            eventName = @"me_gravatar_tapped";
            break;
        case WPAnalyticsStatGravatarUploaded:
            eventName = @"me_gravatar_uploaded";
            break;
        case WPAnalyticsStatInstallJetpackCanceled:
            eventName = @"install_jetpack_canceled";
            break;
        case WPAnalyticsStatInstallJetpackCompleted:
            eventName = @"install_jetpack_completed";
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
        case WPAnalyticsStatLoginAutoFillCredentialsFilled:
            eventName = @"login_autofill_credentials_filled";
            break;
        case WPAnalyticsStatLoginAutoFillCredentialsUpdated:
            eventName = @"login_autofill_credentials_updated";
            break;
        case WPAnalyticsStatLoginProloguePaged:
            eventName = @"login_prologue_paged";
            break;
        case WPAnalyticsStatLoginPrologueViewed:
            eventName = @"login_prologue_viewed";
            break;
        case WPAnalyticsStatLoginEmailFormViewed:
            eventName = @"login_email_form_viewed";
            break;
        case WPAnalyticsStatLoginMagicLinkOpenEmailClientViewed:
            eventName = @"login_magic_link_open_email_client_viewed";
            break;
        case WPAnalyticsStatLoginMagicLinkRequestFormViewed:
            eventName = @"login_magic_link_request_form_viewed";
            break;
        case WPAnalyticsStatLoginPasswordFormViewed:
            eventName = @"login_password_form_viewed";
            break;
        case WPAnalyticsStatLoginURLFormViewed:
            eventName = @"login_url_form_viewed";
            break;
        case WPAnalyticsStatLoginURLHelpScreenViewed:
            eventName = @"login_url_help_screen_viewed";
            break;
        case WPAnalyticsStatLoginUsernamePasswordFormViewed:
            eventName = @"login_username_password_form_viewed";
            break;
        case WPAnalyticsStatLoginTwoFactorFormViewed:
            eventName = @"login_two_factor_form_viewed";
            break;
        case WPAnalyticsStatLoginEpilogueViewed:
            eventName = @"login_epilogue_viewed";
            break;
        case WPAnalyticsStatLoginForgotPasswordClicked:
            eventName = @"login_forgot_password_clicked";
            break;
        case WPAnalyticsStatLoginSocialButtonClick:
            eventName = @"login_social_button_click";
            break;
        case WPAnalyticsStatLoginSocialButtonFailure:
            eventName = @"login_social_button_failure";
            break;
        case WPAnalyticsStatLoginSocialConnectSuccess:
            eventName = @"login_social_connect_success";
            break;
        case WPAnalyticsStatLoginSocialConnectFailure:
            eventName = @"login_social_connect_failure";
            break;
        case WPAnalyticsStatLoginSocialSuccess:
            eventName = @"login_social_login_success";
            break;
        case WPAnalyticsStatLoginSocialFailure:
            eventName = @"login_social_login_failure";
            break;
        case WPAnalyticsStatLoginSocial2faNeeded:
            eventName = @"login_social_2fa_needed";
            break;
        case WPAnalyticsStatLoginSocialAccountsNeedConnecting:
            eventName = @"login_social_accounts_need_connecting";
            break;
        case WPAnalyticsStatLoginSocialErrorUnknownUser:
            eventName = @"login_social_error_unknown_user";
            break;
        case WPAnalyticsStatLogout:
            eventName = @"account_logout";
            break;
        case WPAnalyticsStatLowMemoryWarning:
            eventName = @"application_low_memory_warning";
            break;
        case WPAnalyticsStatMediaLibraryDeletedItems:
            eventName = @"media_library_deleted_items";
            break;
        case WPAnalyticsStatMediaLibraryEditedItemMetadata:
            eventName = @"media_library_edited_item_metadata";
            break;
        case WPAnalyticsStatMediaLibraryPreviewedItem:
            eventName = @"media_library_previewed_item";
            break;
        case WPAnalyticsStatMediaLibrarySharedItemLink:
            eventName = @"media_library_shared_item_link";
            break;
        case WPAnalyticsStatMediaLibraryAddedPhotoViaDeviceLibrary:
            eventName = @"media_library_photo_added";
            eventProperties = @{ @"via" : @"device_library" };
            break;
        case WPAnalyticsStatMediaLibraryAddedPhotoViaOtherApps:
            eventName = @"media_library_photo_added";
            eventProperties = @{ @"via" : @"other_library" };
            break;
        case WPAnalyticsStatMediaLibraryAddedPhotoViaStockPhotos:
            eventName = @"media_library_photo_added";
            eventProperties = @{ @"via" : @"stock_photos" };
            break;
        case WPAnalyticsStatMediaLibraryAddedPhotoViaCamera:
            eventName = @"media_library_photo_added";
            eventProperties = @{ @"via" : @"camera" };
            break;
        case WPAnalyticsStatMediaLibraryAddedVideoViaDeviceLibrary:
            eventName = @"media_library_video_added";
            eventProperties = @{ @"via" : @"device_library" };
            break;
        case WPAnalyticsStatMediaLibraryAddedVideoViaCamera:
            eventName = @"media_library_video_added";
            eventProperties = @{ @"via" : @"camera" };
            break;
        case WPAnalyticsStatMediaLibraryAddedVideoViaOtherApps:
            eventName = @"media_library_video_added";
            eventProperties = @{ @"via" : @"other_apps" };
            break;
        case WPAnalyticsStatMediaLibraryUploadMediaRetried:
            eventName = @"media_library_upload_media_retried";
            break;
        case WPAnalyticsStatMediaServiceUploadStarted:
            eventName = @"media_service_upload_started";
            break;
        case WPAnalyticsStatMediaServiceUploadFailed:
            eventName = @"media_service_upload_failed";
            break;
        case WPAnalyticsStatMediaServiceUploadSuccessful:
            eventName = @"media_service_upload_successful";
            break;
        case WPAnalyticsStatMediaServiceUploadCanceled:
            eventName = @"media_service_upload_canceled";
            break;
        case WPAnalyticsStatMenusAccessed:
            eventName = @"menus_accessed";
            break;
        case WPAnalyticsStatMenusCreatedItem:
            eventName = @"menus_created_item";
            break;
        case WPAnalyticsStatMenusCreatedMenu:
            eventName = @"menus_created_menu";
            break;
        case WPAnalyticsStatMenusDeletedMenu:
            eventName = @"menus_deleted_menu";
            break;
        case WPAnalyticsStatMenusDeletedItem:
            eventName = @"menus_deleted_item";
            break;
        case WPAnalyticsStatMenusDiscardedChanges:
            eventName = @"menus_discarded_changes";
            break;
        case WPAnalyticsStatMenusEditedItem:
            eventName = @"menus_edited_item";
            break;
        case WPAnalyticsStatMenusOpenedItemEditor:
            eventName = @"menus_opened_item_editor";
            break;
        case WPAnalyticsStatMenusOrderedItems:
            eventName = @"menus_ordered_items";
            break;
        case WPAnalyticsStatMenusSavedMenu:
            eventName = @"menus_saved_menu";
            break;
        case WPAnalyticsStatMeTabAccessed:
            eventName = @"me_tab_accessed";
            break;
        case WPAnalyticsStatMySitesTabAccessed:
            eventName = @"my_site_tab_accessed";
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
        case WPAnalyticsStatNotificationsSettingsBlogNotificationsOn:
            eventName = @"followed_blog_notifications_settings_on";
            break;
        case WPAnalyticsStatNotificationsSettingsBlogNotificationsOff:
            eventName = @"followed_blog_notifications_settings_off";
            break;
        case WPAnalyticsStatNotificationsSettingsEmailNotificationsOn:
            eventName = @"followed_blog_notifications_settings_email_on";
            break;
        case WPAnalyticsStatNotificationsSettingsEmailNotificationsOff:
            eventName = @"followed_blog_notifications_settings_email_off";
            break;
        case WPAnalyticsStatNotificationsSettingsEmailDeliveryInstantly:
            eventName = @"followed_blog_notifications_settings_email_instantly";
            break;
        case WPAnalyticsStatNotificationsSettingsEmailDeliveryDaily:
            eventName = @"followed_blog_notifications_settings_email_daily";
            break;
        case WPAnalyticsStatNotificationsSettingsEmailDeliveryWeekly:
            eventName = @"followed_blog_notifications_settings_email_weekly";
            break;
        case WPAnalyticsStatNotificationsSettingsCommentsNotificationsOn:
            eventName = @"followed_blog_notifications_settings_comments_on";
            break;
        case WPAnalyticsStatNotificationsSettingsCommentsNotificationsOff:
            eventName = @"followed_blog_notifications_settings_comments_off";
            break;
        case WPAnalyticsStatNotificationsTappedNewPost:
            eventName = @"notification_tapped_new_post";
            break;
        case WPAnalyticsStatNotificationsTappedViewReader:
            eventName = @"notification_tapped_view_reader";
            break;
        case WPAnalyticsStatNotificationsTappedSegmentedControl:
            eventName = @"notification_tapped_segmented_control";
            break;
        case WPAnalyticsStatNotificationsUploadMediaSuccessWritePost:
            eventName = @"notifications_upload_media_success_write_post";
            break;
        case WPAnalyticsStatNotificationsShareSuccessEditPost:
            eventName = @"notifications_share_success_edit_post";
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
        case WPAnalyticsStatOpenedLogin:
            eventName = @"login_accessed";
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
        case WPAnalyticsStatOpenedPeople:
            eventName = @"people_management_list_opened";
            break;
        case WPAnalyticsStatOpenedPerson:
            eventName = @"people_management_details_opened";
            break;
        case WPAnalyticsStatOpenedPlans:
            eventName = @"site_menu_opened";
            eventProperties = @{ TracksEventPropertyMenuItemKey : @"plans" };
            break;
        case WPAnalyticsStatOpenedPlansComparison:
            eventName = @"plans_compare";
            break;
        case WPAnalyticsStatOpenedPluginDirectory:
            eventName = @"plugin_directory_opened";
            break;
        case WPAnalyticsStatOpenedPluginList:
            eventName = @"plugin_list_opened";
            break;
        case WPAnalyticsStatOpenedPosts:
            eventName = @"site_menu_opened";
            eventProperties = @{ TracksEventPropertyMenuItemKey : @"posts" };
            break;
        case WPAnalyticsStatOpenedSiteSettings:
            eventName = @"site_menu_opened";
            eventProperties = @{ TracksEventPropertyMenuItemKey : @"settings" };
            break;
        case WPAnalyticsStatOpenedSharingManagement:
            eventName = @"site_menu_opened";
            eventProperties = @{ TracksEventPropertyMenuItemKey : @"sharing_management" };
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
        case WPAnalyticsStatPersonRemoved:
            eventName = @"people_management_person_removed";
            break;
        case WPAnalyticsStatPersonUpdated:
            eventName = @"people_management_person_updated";
            break;
        case WPAnalyticsStatPluginUpdated:
            eventName = @"plugin_updated";
            break;
        case WPAnalyticsStatPluginRemoved:
            eventName = @"plugin_removed";
            break;
        case WPAnalyticsStatPluginInstalled:
            eventName = @"plugin_installed";
            break;
        case WPAnalyticsStatPluginActivated:
            eventName = @"plugin_activated";
            break;
        case WPAnalyticsStatPluginDeactivated:
            eventName = @"plugin_deactivated";
            break;
        case WPAnalyticsStatPluginAutoupdateEnabled:
            eventName = @"plugin_autoupdate_enabled";
            break;
        case WPAnalyticsStatPluginAutoupdateDisabled:
            eventName = @"plugin_autoupdate_disabled";
            break;
        case WPAnalyticsStatPluginSearchPerformed:
            eventName = @"plugin_search_performed";
            break;
        case WPAnalyticsStatPostEpilogueDisplayed:
            eventName = @"post_epilogue_displayed";
            break;
        case WPAnalyticsStatPostEpilogueEdit:
            eventName = @"post_epilogue_edit";
            break;
        case WPAnalyticsStatPostEpilogueShare:
            eventName = @"post_epilogue_share";
            break;
        case WPAnalyticsStatPostEpilogueView:
            eventName = @"post_epilogue_view";
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
        case WPAnalyticsStatPostListScheduleAction:
            eventName = @"post_list_button_pressed";
            eventProperties = @{ TracksEventPropertyButtonKey : @"schedule" };
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
        case WPAnalyticsStatPushNotificationPrimerSeen:
            eventName = @"notifications_primer_seen";
            break;
        case WPAnalyticsStatPushNotificationPrimerAllowTapped:
            eventName = @"notifications_primer_allow_tapped";
            break;
        case WPAnalyticsStatPushNotificationPrimerNoTapped:
            eventName = @"notifications_primer_no_tapped";
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
        case WPAnalyticsStatReaderListNotificationMenuOn:
            eventName = @"followed_blog_notifications_reader_menu_on";
            break;
        case WPAnalyticsStatReaderListNotificationMenuOff:
            eventName = @"followed_blog_notifications_reader_menu_off";
            break;
        case WPAnalyticsStatReaderListNotificationEnabled:
            eventName = @"followed_blog_notifications_reader_enabled";
            break;
        case WPAnalyticsStatReaderSearchLoaded:
            eventName = @"reader_search_loaded";
            break;
        case WPAnalyticsStatReaderSearchPerformed:
            eventName = @"reader_search_performed";
            break;
        case WPAnalyticsStatReaderSearchResultTapped:
            eventName = @"reader_searchcard_clicked";
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
        case WPAnalyticsStatSelectedInstallJetpack:
            eventName = @"install_jetpack_selected";
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
        case WPAnalyticsStatSignupButtonTapped:
            eventName = @"signup_button_tapped";
            break;
        case WPAnalyticsStatSignupCancelled:
            eventName = @"signup_cancelled";
            break;
        case WPAnalyticsStatSignupEmailButtonTapped:
            eventName = @"signup_email_button_tapped";
            break;
        case WPAnalyticsStatSignupEmailToLogin:
            eventName = @"signup_email_to_login";
            break;
        case WPAnalyticsStatSignupEpilogueViewed:
            eventName = @"signup_epilogue_viewed";
            break;
        case WPAnalyticsStatSignupEpilogueUnchanged:
            eventName = @"signup_epilogue_unchanged";
            break;
        case WPAnalyticsStatSignupEpilogueDisplayNameUpdateSucceeded:
            eventName = @"signup_epilogue_update_display_name_succeeded";
            break;
        case WPAnalyticsStatSignupEpilogueDisplayNameUpdateFailed:
            eventName = @"signup_epilogue_update_display_name_failed";
            break;
        case WPAnalyticsStatSignupEpiloguePasswordUpdateSucceeded:
            eventName = @"signup_epilogue_update_password_succeeded";
            break;
        case WPAnalyticsStatSignupEpiloguePasswordUpdateFailed:
            eventName = @"signup_epilogue_update_password_failed";
            break;
        case WPAnalyticsStatSignupEpilogueUsernameTapped:
            eventName = @"signup_epilogue_username_tapped";
            break;
        case WPAnalyticsStatSignupEpilogueUsernameSuggestionsFailed:
            eventName = @"signup_epilogue_username_suggestions_failed";
            break;
        case WPAnalyticsStatSignupEpilogueUsernameUpdateSucceeded:
            eventName = @"signup_epilogue_update_username_succeeded";
            break;
        case WPAnalyticsStatSignupEpilogueUsernameUpdateFailed:
            eventName = @"signup_epilogue_update_username_failed";
            break;
        case WPAnalyticsStatSignupMagicLinkFailed:
            eventName = @"signup_magic_link_failed";
            break;
        case WPAnalyticsStatSignupMagicLinkOpenEmailClientViewed:
            eventName = @"signup_magic_link_open_email_client_viewed";
            break;
        case WPAnalyticsStatSignupMagicLinkOpened:
            eventName = @"signup_magic_link_opened";
            break;
        case WPAnalyticsStatSignupMagicLinkSucceeded:
            eventName = @"signup_magic_link_succeeded";
            break;
        case WPAnalyticsStatSignupSocialSuccess:
            eventName = @"signup_social_success";
            break;
        case WPAnalyticsStatSignupSocialFailure:
            eventName = @"signup_social_failure";
            break;
        case WPAnalyticsStatSignupSocialButtonFailure:
            eventName = @"signup_social_button_failure";
            break;
        case WPAnalyticsStatSignupSocialButtonTapped:
            eventName = @"signup_google_button_tapped";
            break;
        case WPAnalyticsStatSignupSocialToLogin:
            eventName = @"signup_social_to_login";
            break;
        case WPAnalyticsStatSignupMagicLinkRequested:
            eventName = @"signup_magic_link_requested";
            break;
        case WPAnalyticsStatSignupTermsButtonTapped:
            eventName = @"signup_terms_of_service_tapped";
            break;
        case WPAnalyticsStatSiteSettingsSiteIconTapped:
            eventName = @"my_site_icon_tapped";
            break;
        case WPAnalyticsStatSiteSettingsSiteIconRemoved:
            eventName = @"my_site_icon_removed";
            break;
        case WPAnalyticsStatSiteSettingsSiteIconShotNew:
            eventName = @"my_site_icon_shot_new";
            break;
        case WPAnalyticsStatSiteSettingsSiteIconGalleryPicked:
            eventName = @"my_site_icon_gallery_picked";
            break;
        case WPAnalyticsStatSiteSettingsSiteIconCropped:
            eventName = @"my_site_icon_cropped";
            break;
        case WPAnalyticsStatSiteSettingsSiteIconUploaded:
            eventName = @"my_site_icon_uploaded";
            break;
        case WPAnalyticsStatSiteSettingsSiteIconUploadFailed:
            eventName = @"my_site_icon_upload_unsuccessful";
            break;
        case WPAnalyticsStatSiteSettingsDeleteSiteAccessed:
            eventName = @"site_settings_delete_site_accessed";
            break;
        case WPAnalyticsStatSiteSettingsDeleteSitePurchasesRequested:
            eventName = @"site_settings_delete_site_purchases_requested";
            break;
        case WPAnalyticsStatSiteSettingsDeleteSitePurchasesShowClicked:
            eventName = @"site_settings_delete_site_purchases_show_clicked";
            break;
        case WPAnalyticsStatSiteSettingsDeleteSitePurchasesShown:
            eventName = @"site_settings_delete_site_purchases_shown";
            break;
        case WPAnalyticsStatSiteSettingsDeleteSiteRequested:
            eventName = @"site_settings_delete_site_requested";
            break;
        case WPAnalyticsStatSiteSettingsDeleteSiteResponseError:
            eventName = @"site_settings_delete_site_response_error";
            break;
        case WPAnalyticsStatSiteSettingsDeleteSiteResponseOK:
            eventName = @"site_settings_delete_site_response_ok";
            break;
        case WPAnalyticsStatSiteSettingsExportSiteAccessed:
            eventName = @"site_settings_export_site_accessed";
            break;
        case WPAnalyticsStatSiteSettingsExportSiteRequested:
            eventName = @"site_settings_export_site_requested";
            break;
        case WPAnalyticsStatSiteSettingsExportSiteResponseError:
            eventName = @"site_settings_export_site_response_error";
            break;
        case WPAnalyticsStatSiteSettingsExportSiteResponseOK:
            eventName = @"site_settings_export_site_response_ok";
            break;
        case WPAnalyticsStatSiteSettingsStartOverAccessed:
            eventName = @"site_settings_start_over_accessed";
            break;
        case WPAnalyticsStatSiteSettingsStartOverContactSupportClicked:
            eventName = @"site_settings_start_over_contact_support_clicked";
            break;
        case WPAnalyticsStatSpotlightSearchOpenedApp:
            eventName = @"spotlight_search_opened_app";
            break;
        case WPAnalyticsStatSpotlightSearchOpenedPost:
            eventName = @"spotlight_search_opened_post";
            break;
        case WPAnalyticsStatSpotlightSearchOpenedPage:
            eventName = @"spotlight_search_opened_page";
            break;
        case WPAnalyticsStatSpotlightSearchOpenedReaderPost:
            eventName = @"spotlight_search_opened_reader_post";
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
        case WPAnalyticsStatStatsScrolledToBottom:
            eventName = @"stats_scrolled_to_bottom";
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
        case WPAnalyticsStatStockMediaAccessed:
            eventName = @"stock_media_accessed";
            break;
        case WPAnalyticsStatStockMediaSearched:
            eventName = @"stock_media_searched";
            break;
        case WPAnalyticsStatStockMediaUploaded:
            eventName = @"stock_media_uploaded";
            break;
        case WPAnalyticsStatSupportOpenedHelpshiftScreen:
            eventName = @"support_opened_helpshift_screen";
            break;
        case WPAnalyticsStatSupportReceivedResponseFromSupport:
            eventName = @"support_received_response_from_support";
            break;
        case WPAnalyticsStatSupportUserAcceptedTheSolution:
            eventName = @"support_user_accepted_the_solution";
            break;
        case WPAnalyticsStatSupportUserRejectedTheSolution:
            eventName = @"support_user_rejected_the_solution";
            break;
        case WPAnalyticsStatSupportUserSentScreenshot:
            eventName = @"support_user_sent_screenshot";
            break;
        case WPAnalyticsStatSupportUserReviewedTheApp:
            eventName = @"support_user_reviewed_the_app";
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
        case WPAnalyticsStatTrainTracksInteract:
            eventName = @"traintracks_interact";
            break;
        case WPAnalyticsStatTrainTracksRender:
            eventName = @"traintracks_render";
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
        case WPAnalyticsStatOpenedAppSettings:
            eventName = @"app_settings_opened";
            break;
        case WPAnalyticsStatOpenedMyProfile:
            eventName = @"my_profile_opened";
            break;
        case WPAnalyticsStatSharingButtonSettingsChanged:
            eventName = @"sharing_buttons_settings_changed";
            break;
        case WPAnalyticsStatSharingButtonOrderChanged:
            eventName = @"sharing_buttons_order_changed";
            break;
        case WPAnalyticsStatSharingButtonShowReblogChanged:
            eventName = @"sharing_buttons_show_reblog_changed";
            break;
        case WPAnalyticsStatSharingOpenedPublicize:
            eventName = @"publicize_opened";
            break;
        case WPAnalyticsStatSharingOpenedSharingButtonSettings:
            eventName = @"sharing_buttons_opened";
            break;
        case WPAnalyticsStatSharingPublicizeConnected:
            eventName = @"publicize_service_connected";
            break;
        case WPAnalyticsStatSharingPublicizeDisconnected:
            eventName = @"publicize_service_disconnected";
            break;
        case WPAnalyticsStatSharingPublicizeConnectionAvailableToAllChanged:
            eventName = @"publicize_connection_availability_changed";
            break;
        case WPAnalyticsStatLoginMagicLinkExited:
            eventName = @"login_magic_link_exited";
            break;
        case WPAnalyticsStatLoginMagicLinkFailed:
            eventName = @"login_magic_link_failed";
            break;
        case WPAnalyticsStatLoginMagicLinkOpened:
            eventName = @"login_magic_link_opened";
            break;
        case WPAnalyticsStatLoginMagicLinkRequested:
            eventName = @"login_magic_link_requested";
            break;
        case WPAnalyticsStatLoginMagicLinkSucceeded:
            eventName = @"login_magic_link_succeeded";
            break;
        case WPAnalyticsStatShareExtensionError:
            eventName = @"share_extension_error";
            break;
        case WPAnalyticsStatSearchAdsAttribution:
            eventName = @"searchads_attribution_detail_received";
            break;

            // to be implemented
        case WPAnalyticsStatMediaLibraryAddedPhoto:
        case WPAnalyticsStatMediaLibraryAddedVideo:
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
