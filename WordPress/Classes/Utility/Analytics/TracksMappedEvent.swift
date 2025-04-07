import Foundation
import WordPressShared

struct TracksMappedEvent {
    let name: String
    let properties: [AnyHashable: Any]?
}

extension TracksMappedEvent {
    static func make(for stat: WPAnalyticsStat) -> TracksMappedEvent? {
        let name: String
        var properties: [AnyHashable: Any]?

        switch stat {
        case .abTestStart:
            name = "abtest_start"
        case .addedSelfHostedSite:
            name = "self_hosted_blog_added"
        case .addedSelfHostedSiteButJetpackNotConnectedToWPCom:
            name = "self_hosted_blog_added_jetpack_not_connected"
        case .activityLogViewed:
            name = "activity_log_list_opened"
        case .activityLogDetailViewed:
            name = "activity_log_detail_opened"
        case .activityLogRewindStarted:
            name = "activity_log_rewind_started"
        case .appIconChanged:
            name = "app_icon_changed"
        case .appIconReset:
            name = "app_icon_reset"
        case .appInstalled:
            name = "application_installed"
        case .appUpgraded:
            name = "application_upgraded"
        case .applicationOpened:
            name = "application_opened"
        case .autoUploadPostInvoked:
            name = "auto_upload_post_invoked"
        case .applicationClosed:
            name = "application_closed"
        case .appReviewsCanceledFeedbackScreen:
            name = "app_reviews_feedback_screen_canceled"
        case .appReviewsDeclinedToRateApp:
            name = "app_reviews_declined_to_rate_app"
        case .appReviewsDidntLikeApp:
            name = "app_reviews_didnt_like_app"
        case .appReviewsLikedApp:
            name = "app_reviews_liked_app"
        case .appReviewsOpenedFeedbackScreen:
            name = "app_reviews_feedback_screen_opened"
        case .appReviewsRatedApp:
            name = "app_reviews_rated_app"
        case .appReviewsSawPrompt:
            name = "app_reviews_saw_prompt"
        case .appReviewsSentFeedback:
            name = "app_reviews_feedback_sent"
        case .appSettingsImageOptimizationChanged:
            name = "app_settings_image_optimization_changed"
        case .appSettingsMediaRemoveLocationChanged:
            name = "app_settings_media_remove_location_changed"
        case .appSettingsVideoOptimizationChanged:
            name = "app_settings_video_optimization_changed"
        case .appSettingsGutenbergEnabled:
            name = "gutenberg_setting_enabled"
        case .appSettingsGutenbergDisabled:
            name = "gutenberg_setting_disabled"
        case .automatedTransferCustomDomainDialogShown:
            name = "automated_transfer_custom_domain_dialog_shown"
        case .automatedTransferCustomDomainDialogCancelled:
            name = "automated_transfer_custom_domain_dialog_cancelled"
        case .automatedTransferCustomDomainSuggestionQueried:
            name = "automated_transfer_custom_domain_suggestion_queried"
        case .automatedTransferCustomDomainSuggestionSelected:
            name = "automated_transfer_custom_domain_suggestion_selected"
        case .automatedTransferCustomDomainContactInfoValidated:
            name = "automated_transfer_custom_domain_contact_information_validated"
        case .automatedTransferCustomDomainContactInfoValidationFailed:
            name = "automated_transfer_custom_domain_contact_information_validation_failed"
        case .automatedTransferCustomDomainPurchased:
            name = "automated_transfer_custom_domain_purchased"
        case .automatedTransferCustomDomainPurchaseFailed:
            name = "automated_transfer_custom_domain_purchase_failed"
        case .automatedTransferDialogShown:
            name = "automated_transfer_confirm_dialog_shown"
        case .automatedTransferDialogCancelled:
            name = "automated_transfer_confirm_dialog_cancelled"
        case .automatedTransferEligibilityCheckInitiated:
            name = "automated_transfer_check_eligibility"
        case .automatedTransferSiteIneligible:
            name = "automated_transfer_not_eligible"
        case .automatedTransferInitiate:
            name = "automated_transfer_initiate"
        case .automatedTransferInitiated:
            name = "automated_transfer_initiated"
        case .automatedTransferInitiationFailed:
            name = "automated_transfer_initiation_failed"
        case .automatedTransferStatusComplete:
            name = "automated_transfer_status_complete"
        case .automatedTransferStatusFailed:
            name = "automated_transfer_status_failed"
        case .automatedTransferFlowComplete:
            name = "automated_transfer_flow_complete"
        case .createAccountInitiated:
            name = "account_create_initiated"
        case .createAccountEmailExists:
            name = "account_create_email_exists"
        case .createAccountUsernameExists:
            name = "account_create_username_exists"
        case .createAccountFailed:
            name = "account_create_failed"
        case .createdAccount:
            name = "account_created"
        case .createdSite:
            name = "site_created"
        case .createSiteProcessBegun:
            name = "site_creation_accessed"
        case .createSiteCategoryViewed:
            name = "site_creation_category_viewed"
        case .createSiteDetailsViewed:
            name = "site_creation_details_viewed"
        case .createSiteDomainViewed:
            name = "site_creation_domain_viewed"
        case .createSiteThemeViewed:
            name = "site_creation_theme_viewed"
        case .createSiteRequestInitiated:
            name = "site_creation_creating_viewed"
        case .createSiteSuccessViewed:
            name = "site_creation_success_viewed"
        case .createSiteCreationFailed:
            name = "create_site_creation_failed"
        case .createSiteSetTaglineFailed:
            name = "create_site_set_tagline_failed"
        case .createSiteSetThemeFailed:
            name = "create_site_set_theme_failed"
        case .createSiteValidationFailed:
            name = "create_site_validation_failed"
        case .deepLinked:
            name = "deep_linked"
        case .deepLinkFailed:
            name = "deep_link_failed"
        case .domainCreditPromptShown:
            name = "domain_credit_prompt_shown"
        case .domainCreditRedemptionSuccess:
            name = "domain_credit_redemption_success"
        case .domainCreditRedemptionTapped:
            name = "domain_credit_redemption_tapped"
        case .editorAddedPhotoViaLocalLibrary:
            name = "editor_photo_added"
            properties = [Constants.tracksEventPropertyViaKey: "local_library"]
        case .editorAddedPhotoViaWPMediaLibrary:
            name = "editor_photo_added"
            properties = [Constants.tracksEventPropertyViaKey: "media_library"]
        case .editorAddedVideoViaLocalLibrary:
            name = "editor_video_added"
            properties = [Constants.tracksEventPropertyViaKey: "local_library"]
        case .editorAddedVideoViaWPMediaLibrary:
            name = "editor_video_added"
            properties = [Constants.tracksEventPropertyViaKey: "media_library"]
        case .editorAddedOtherMediaViaWPMediaLibrary:
            name = "editor_other_media_added"
            properties = [Constants.tracksEventPropertyViaKey: "media_library"]
        case .editorAddedVideoViaOtherApps:
            name = "editor_video_added"
            properties = [Constants.tracksEventPropertyViaKey: "other_apps"]
        case .editorAddedPhotoViaOtherApps:
            name = "editor_photo_added"
            properties = [Constants.tracksEventPropertyViaKey: "other_apps"]
        case .editorAddedPhotoViaStockPhotos:
            name = "editor_photo_added"
            properties = [Constants.tracksEventPropertyViaKey: "stock_photos"]
        case .editorAddedPhotoViaMediaEditor:
            name = "editor_photo_added"
            properties = [Constants.tracksEventPropertyViaKey: "media_editor"]
        case .editorAztecBetaLink:
            name = "editor_aztec_beta_link"
        case .editorAztecPromoLink:
            name = "editor_aztec_promo_link"
        case .editorAztecPromoPositive:
            name = "editor_aztec_promo_positive"
        case .editorAztecPromoNegative:
            name = "editor_aztec_promo_negative"
        case .editorClosed:
            name = "editor_closed"
        case .editorCreatedPost:
            name = "editor_post_created"
        case .editorDiscardedChanges:
            name = "editor_discarded_changes"
        case .editorEditedImage:
            name = "editor_image_edited"
        case .editorEnabledNewVersion:
            name = "editor_enabled_new_version"
        case .editorResizedPhoto:
            name = "editor_resized_photo"
        case .editorResizedPhotoError:
            name = "editor_resized_photo_error"
        case .editorSavedDraft:
            name = "editor_draft_saved"
        case .editorScheduledPost:
            name = "editor_post_scheduled"
        case .editorSessionStart:
            name = "editor_session_start"
        case .editorSessionSwitchEditor:
            name = "editor_session_switch_editor"
        case .editorSessionEnd:
            name = "editor_session_end"
        case .editorSessionTemplateApply:
            name = "editor_session_template_apply"
        case .editorPublishedPost:
            name = "editor_post_published"
        case .editorQuickPublishedPost:
            name = "editor_quick_post_published"
        case .editorQuickSavedDraft:
            name = "editor_quick_draft_saved"
        case .editorTappedBlockquote:
            name = "editor_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "blockquote"]
        case .editorTappedBold:
            name = "editor_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "bold"]
        case .editorTappedHeader:
            name = "editor_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "header"]
        case .editorTappedHeaderSelection:
            name = "editor_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "header_selection"]
        case .editorTappedHorizontalRule:
            name = "editor_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "horizontal_rule"]
        case .editorTappedHTML:
            name = "editor_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "html"]
        case .editorTappedImage:
            name = "editor_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "image"]
        case .editorMediaPickerTappedDismiss:
            name = "media_picker_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "cancel"]
        case .editorMediaPickerTappedDevicePhotos:
            name = "media_picker_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "device_photos"]
        case .editorMediaPickerTappedCamera:
            name = "media_picker_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "camera"]
        case .editorMediaPickerTappedMediaLibrary:
            name = "media_picker_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "media_library"]
        case .editorMediaPickerTappedOtherApps:
            name = "media_picker_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "other_apps"]
        case .editorTappedItalic:
            name = "editor_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "italic"]
        case .editorTappedLink:
            name = "editor_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "link"]
        case .editorTappedMore:
            name = "editor_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "more"]
        case .editorTappedMoreItems:
            name = "editor_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "overflow_ellipsis"]
        case .editorTappedOrderedList:
            name = "editor_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "ordered_list"]
        case .editorTappedStrikethrough:
            name = "editor_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "strikethrough"]
        case .editorTappedUnderline:
            name = "editor_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "underline"]
        case .editorTappedUnlink:
            name = "editor_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "unlink"]
        case .editorTappedUnorderedList:
            name = "editor_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "unordered_list"]
        case .editorTappedList:
            name = "editor_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "list"]
        case .editorTappedUndo:
            name = "editor_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "undo"]
        case .editorTappedRedo:
            name = "editor_button_tapped"
            properties = [Constants.tracksEventPropertyButtonKey: "redo"]
        case .editorToggledOff:
            name = "editor_toggled_off"
        case .editorToggledOn:
            name = "editor_toggled_on"
        case .editorUpdatedPost:
            name = "editor_post_update"
        case .editorUploadMediaFailed:
            name = "editor_upload_media_failed"
        case .editorUploadMediaPaused:
            name = "editor_upload_media_paused"
        case .editorUploadMediaRetried:
            name = "editor_upload_media_retried"
        case .enhancedSiteCreationAccessed:
            name = "enhanced_site_creation_accessed"
        case .enhancedSiteCreationSegmentsViewed:
            name = "enhanced_site_creation_segments_viewed"
        case .enhancedSiteCreationSegmentsSelected:
            name = "enhanced_site_creation_segments_selected"
        case .enhancedSiteCreationSiteDesignViewed:
            name = "enhanced_site_creation_site_design_viewed"
        case .enhancedSiteCreationSiteDesignSelected:
            name = "enhanced_site_creation_site_design_selected"
        case .enhancedSiteCreationSiteDesignSkipped:
            name = "enhanced_site_creation_site_design_skipped"
        case .enhancedSiteCreationSiteDesignPreviewViewed:
            name = "enhanced_site_creation_site_design_preview_viewed"
        case .enhancedSiteCreationSiteDesignPreviewLoading:
            name = "enhanced_site_creation_site_design_preview_loading"
        case .enhancedSiteCreationSiteDesignPreviewLoaded:
            name = "enhanced_site_creation_site_design_preview_loaded"
        case .enhancedSiteCreationSiteDesignPreviewModeButtonTapped:
            name = "enhanced_site_creation_site_design_preview_mode_button_tapped"
        case .enhancedSiteCreationSiteDesignPreviewModeChanged:
            name = "enhanced_site_creation_site_design_preview_mode_changed"
        case .enhancedSiteCreationVerticalsViewed:
            name = "enhanced_site_creation_verticals_viewed"
        case .enhancedSiteCreationVerticalsSelected:
            name = "enhanced_site_creation_verticals_selected"
        case .enhancedSiteCreationVerticalsSkipped:
            name = "enhanced_site_creation_verticals_skipped"
        case .enhancedSiteCreationBasicInformationViewed:
            name = "enhanced_site_creation_basic_information_viewed"
        case .enhancedSiteCreationBasicInformationCompleted:
            name = "enhanced_site_creation_basic_information_completed"
        case .enhancedSiteCreationBasicInformationSkipped:
            name = "enhanced_site_creation_basic_information_skipped"
        case .enhancedSiteCreationDomainsAccessed:
            name = "enhanced_site_creation_domains_accessed"
        case .enhancedSiteCreationDomainsSelected:
            name = "enhanced_site_creation_domains_selected"
        case .enhancedSiteCreationSuccessLoading:
            name = "enhanced_site_creation_success_loading"
        case .enhancedSiteCreationSuccessPreviewViewed:
            name = "enhanced_site_creation_preview_viewed"
        case .enhancedSiteCreationSuccessPreviewLoaded:
            name = "enhanced_site_creation_preview_loaded"
        case .enhancedSiteCreationSuccessPreviewOkButtonTapped:
            name = "enhanced_site_creation_preview_ok_button_tapped"
        case .enhancedSiteCreationErrorShown:
            name = "enhanced_site_creation_error_shown"
        case .gravatarCropped:
            name = "me_gravatar_cropped"
        case .gravatarTapped:
            name = "me_gravatar_tapped"
        case .gravatarUploaded:
            name = "me_gravatar_uploaded"
        case .gutenbergWarningConfirmDialogShown:
            name = "gutenberg_warning_confirm_dialog_shown"
        case .gutenbergWarningConfirmDialogYesTapped:
            name = "gutenberg_warning_confirm_dialog_yes_tapped"
        case .gutenbergWarningConfirmDialogCancelTapped:
            name = "gutenberg_warning_confirm_dialog_cancel_tapped"
        case .gutenbergWarningConfirmDialogDontShowAgainChecked:
            name = "gutenberg_warning_confirm_dialog_dont_show_again_checked"
        case .gutenbergWarningConfirmDialogDontShowAgainUnchecked:
            name = "gutenberg_warning_confirm_dialog_dont_show_again_unchecked"
        case .gutenbergWarningConfirmDialogLearnMoreTapped:
            name = "gutenberg_warning_confirm_dialog_learn_more_tapped"
        case .installJetpackCanceled:
            name = "install_jetpack_canceled"
        case .installJetpackCompleted:
            name = "install_jetpack_completed"
        case .installJetpackRemoteStart:
            name = "install_jetpack_remote_start"
        case .installJetpackRemoteCompleted:
            name = "install_jetpack_remote_completed"
        case .installJetpackRemoteFailed:
            name = "install_jetpack_remote_failed"
        case .installJetpackRemoteRetry:
            name = "install_jetpack_remote_restart"
        case .installJetpackRemoteConnect:
            name = "install_jetpack_remote_connect"
        case .installJetpackRemoteLogin:
            name = "install_jetpack_remote_login"
        case .installJetpackRemoteStartManualFlow:
            name = "install_jetpack_remote_start_manual_flow"
        case .installJetpackWebviewSelect:
            name = "connect_jetpack_selected"
        case .installJetpackWebviewFailed:
            name = "connect_jetpack_failed"
        case .landingEditorShown:
            name = "landing_editor_shown"
        case .layoutPickerPreviewErrorShown:
            name = "layout_picker_preview_error_shown"
        case .layoutPickerPreviewLoaded:
            name = "layout_picker_preview_loaded"
        case .layoutPickerPreviewLoading:
            name = "layout_picker_preview_loading"
        case .layoutPickerPreviewModeButtonTapped:
            name = "layout_picker_preview_mode_button_tapped"
        case .layoutPickerPreviewModeChanged:
            name = "layout_picker_preview_mode_changed"
        case .layoutPickerPreviewViewed:
            name = "layout_picker_preview_viewed"
        case .layoutPickerThumbnailModeButtonTapped:
            name = "layout_picker_thumbnail_mode_button_tapped"
        case .logSpecialCondition:
            name = "log_special_condition"
        case .loginFailed:
            name = "login_failed_to_login"
        case .loginFailedToGuessXMLRPC:
            name = "login_failed_to_guess_xmlrpc"
        case .loginAutoFillCredentialsFilled:
            name = "login_autofill_credentials_filled"
        case .loginAutoFillCredentialsUpdated:
            name = "login_autofill_credentials_updated"
        case .loginProloguePaged:
            name = "login_prologue_paged"
        case .loginPrologueViewed:
            name = "login_prologue_viewed"
        case .loginEmailFormViewed:
            name = "login_email_form_viewed"
        case .loginMagicLinkOpenEmailClientViewed:
            name = "login_magic_link_open_email_client_viewed"
        case .loginMagicLinkRequestFormViewed:
            name = "login_magic_link_request_form_viewed"
        case .loginPasswordFormViewed:
            name = "login_password_form_viewed"
        case .loginURLFormViewed:
            name = "login_url_form_viewed"
        case .loginURLHelpScreenViewed:
            name = "login_url_help_screen_viewed"
        case .loginUsernamePasswordFormViewed:
            name = "login_username_password_form_viewed"
        case .loginTwoFactorFormViewed:
            name = "login_two_factor_form_viewed"
        case .loginEpilogueViewed:
            name = "login_epilogue_viewed"
        case .loginForgotPasswordClicked:
            name = "login_forgot_password_clicked"
        case .loginSocialButtonClick:
            name = "login_social_button_click"
        case .loginSocialButtonFailure:
            name = "login_social_button_failure"
        case .loginSocialConnectSuccess:
            name = "login_social_connect_success"
        case .loginSocialConnectFailure:
            name = "login_social_connect_failure"
        case .loginSocialSuccess:
            name = "login_social_login_success"
        case .loginSocialFailure:
            name = "login_social_login_failure"
        case .loginSocial2faNeeded:
            name = "login_social_2fa_needed"
        case .loginSocialAccountsNeedConnecting:
            name = "login_social_accounts_need_connecting"
        case .loginSocialErrorUnknownUser:
            name = "login_social_error_unknown_user"
        case .logout:
            name = "account_logout"
        case .lowMemoryWarning:
            name = "application_low_memory_warning"
        case .mediaLibraryDeletedItems:
            name = "media_library_deleted_items"
        case .mediaLibraryEditedItemMetadata:
            name = "media_library_edited_item_metadata"
        case .mediaLibraryPreviewedItem:
            name = "media_library_previewed_item"
        case .mediaLibrarySharedItemLink:
            name = "media_library_shared_item_link"
        case .mediaLibraryAddedPhoto:
            name = "media_library_photo_added"
        case .mediaLibraryAddedPhotoViaDeviceLibrary:
            name = "media_library_photo_added"
            properties = [Constants.tracksEventPropertyViaKey: "device_library"]
        case .mediaLibraryAddedPhotoViaOtherApps:
            name = "media_library_photo_added"
            properties = [Constants.tracksEventPropertyViaKey: "other_library"]
        case .mediaLibraryAddedPhotoViaStockPhotos:
            name = "media_library_photo_added"
            properties = [Constants.tracksEventPropertyViaKey: "stock_photos"]
        case .mediaLibraryAddedPhotoViaCamera:
            name = "media_library_photo_added"
            properties = [Constants.tracksEventPropertyViaKey: "camera"]
        case .mediaLibraryAddedVideo:
            name = "media_library_video_added"
        case .mediaLibraryAddedVideoViaDeviceLibrary:
            name = "media_library_video_added"
            properties = [Constants.tracksEventPropertyViaKey: "device_library"]
        case .mediaLibraryAddedVideoViaCamera:
            name = "media_library_video_added"
            properties = [Constants.tracksEventPropertyViaKey: "camera"]
        case .mediaLibraryAddedVideoViaOtherApps:
            name = "media_library_video_added"
            properties = [Constants.tracksEventPropertyViaKey: "other_apps"]
        case .mediaLibraryUploadMediaRetried:
            name = "media_library_upload_media_retried"
        case .mediaServiceUploadStarted:
            name = "media_service_upload_started"
        case .mediaServiceUploadFailed:
            name = "media_service_upload_failed"
        case .mediaServiceUploadSuccessful:
            name = "media_service_upload_successful"
        case .mediaServiceUploadCanceled:
            name = "media_service_upload_canceled"
        case .menusAccessed:
            name = "menus_accessed"
        case .menusCreatedItem:
            name = "menus_created_item"
        case .menusCreatedMenu:
            name = "menus_created_menu"
        case .menusDeletedMenu:
            name = "menus_deleted_menu"
        case .menusDeletedItem:
            name = "menus_deleted_item"
        case .menusDiscardedChanges:
            name = "menus_discarded_changes"
        case .menusEditedItem:
            name = "menus_edited_item"
        case .menusOpenedItemEditor:
            name = "menus_opened_item_editor"
        case .menusOrderedItems:
            name = "menus_ordered_items"
        case .menusSavedMenu:
            name = "menus_saved_menu"
        case .meTabAccessed:
            name = "me_tab_accessed"
        case .mySitesTabAccessed:
            name = "my_site_tab_accessed"
        case .notificationsCommentApproved:
            name = "notifications_comment_approved"
        case .notificationsCommentFlaggedAsSpam:
            name = "notifications_flagged_as_spam"
        case .notificationsSiteFollowAction:
            name = "notifications_follow_action"
        case .notificationsCommentLiked:
            name = "notifications_comment_liked"
        case .notificationsCommentRepliedTo:
            name = "notifications_replied_to"
        case .notificationsCommentTrashed:
            name = "notifications_comment_trashed"
        case .notificationsCommentUnapproved:
            name = "notifications_comment_unapproved"
        case .notificationsSiteUnfollowAction:
            name = "notifications_unfollow_action"
        case .notificationsCommentUnliked:
            name = "notifications_comment_unliked"
        case .notificationsMissingSyncWarning:
            name = "notifications_missing_sync_warning"
        case .notificationsSettingsUpdated:
            name = "notification_settings_updated"
        case .notificationsSettingsBlogNotificationsOn:
            name = "followed_blog_notifications_settings_on"
        case .notificationsSettingsBlogNotificationsOff:
            name = "followed_blog_notifications_settings_off"
        case .notificationsSettingsEmailNotificationsOn:
            name = "followed_blog_notifications_settings_email_on"
        case .notificationsSettingsEmailNotificationsOff:
            name = "followed_blog_notifications_settings_email_off"
        case .notificationsSettingsEmailDeliveryInstantly:
            name = "followed_blog_notifications_settings_email_instantly"
        case .notificationsSettingsEmailDeliveryDaily:
            name = "followed_blog_notifications_settings_email_daily"
        case .notificationsSettingsEmailDeliveryWeekly:
            name = "followed_blog_notifications_settings_email_weekly"
        case .notificationsSettingsCommentsNotificationsOn:
            name = "followed_blog_notifications_settings_comments_on"
        case .notificationsSettingsCommentsNotificationsOff:
            name = "followed_blog_notifications_settings_comments_off"
        case .notificationsTappedNewPost:
            name = "notification_tapped_new_post"
        case .notificationsTappedViewReader:
            name = "notification_tapped_view_reader"
        case .notificationsTappedSegmentedControl:
            name = "notification_tapped_segmented_control"
        case .notificationsUploadMediaSuccessWritePost:
            name = "notifications_upload_media_success_write_post"
        case .notificationsShareSuccessEditPost:
            name = "notifications_share_success_edit_post"
        case .onePasswordFailed:
            name = "one_password_failed"
        case .onePasswordLogin:
            name = "one_password_login"
        case .onePasswordSignup:
            name = "one_password_signup"
        case .openedComments:
            name = "site_menu_opened"
            properties = [Constants.tracksEventPropertyMenuItemKey: "comments"]
        case .openedLogin:
            name = "login_accessed"
        case .openedMediaLibrary:
            name = "site_menu_opened"
            properties = [Constants.tracksEventPropertyMenuItemKey: "library"]
        case .openedNotificationsList:
            name = "notifications_accessed"
        case .openedNotificationDetails:
            name = "notifications_notification_details_opened"
        case .openedNotificationSettingsList:
            name = "notification_settings_list_opened"
        case .openedNotificationSettingStreams:
            name = "notification_settings_streams_opened"
        case .openedNotificationSettingDetails:
            name = "notification_settings_details_opened"
        case .openedPages:
            name = "site_menu_opened"
            properties = [Constants.tracksEventPropertyMenuItemKey: "pages"]
        case .openedPeople:
            name = "people_management_list_opened"
        case .openedPerson:
            name = "people_management_details_opened"
        case .openedPlans:
            name = "site_menu_opened"
            properties = [Constants.tracksEventPropertyMenuItemKey: "plans"]
        case .openedPlansComparison:
            name = "plans_compare"
        case .openedPluginDirectory:
            name = "plugin_directory_opened"
        case .openedPluginList:
            name = "plugin_list_opened"
        case .openedPosts:
            name = "site_menu_opened"
            properties = [Constants.tracksEventPropertyMenuItemKey: "posts"]
        case .openedSiteSettings:
            name = "site_menu_opened"
            properties = [Constants.tracksEventPropertyMenuItemKey: "settings"]
        case .openedSharingManagement:
            name = "site_menu_opened"
            properties = [Constants.tracksEventPropertyMenuItemKey: "sharing_management"]
        case .openedSupport:
            name = "support_opened"
        case .openedViewAdmin:
            name = "site_menu_view_admin_opened"
        case .openedViewSite:
            name = "site_menu_view_site_opened"
        case .personRemoved:
            name = "people_management_person_removed"
        case .personUpdated:
            name = "people_management_person_updated"
        case .pluginUpdated:
            name = "plugin_updated"
        case .pluginRemoved:
            name = "plugin_removed"
        case .pluginInstalled:
            name = "plugin_installed"
        case .pluginActivated:
            name = "plugin_activated"
        case .pluginDeactivated:
            name = "plugin_deactivated"
        case .pluginAutoupdateEnabled:
            name = "plugin_autoupdate_enabled"
        case .pluginAutoupdateDisabled:
            name = "plugin_autoupdate_disabled"
        case .pluginSearchPerformed:
            name = "plugin_search_performed"
        case .pageSetParentViewed:
            name = "site_pages_set_parent_viewed"
        case .pageSetParentSearchAccessed:
            name = "site_pages_set_parent_search_accessed"
        case .pageSetParentDonePressed:
            name = "site_pages_set_parent_done_pressed"
        case .postEpilogueDisplayed:
            name = "post_epilogue_displayed"
        case .postEpilogueEdit:
            name = "post_epilogue_edit"
        case .postEpilogueShare:
            name = "post_epilogue_share"
        case .postEpilogueView:
            name = "post_epilogue_view"
        case .postListAuthorFilterChanged:
            name = "post_list_author_filter_changed"
        case .postListDraftAction:
            name = "post_list_button_pressed"
            properties = [Constants.tracksEventPropertyButtonKey: "draft"]
        case .postListEditAction:
            name = "post_list_button_pressed"
            properties = [Constants.tracksEventPropertyButtonKey: "edit"]
        case .postListDuplicateAction:
            name = "post_list_button_pressed"
            properties = [Constants.tracksEventPropertyButtonKey: "copy"] // Property aligned with Android
        case .postListExcessiveLoadMoreDetected:
            name = "post_list_excessive_load_more_detected"
        case .postListLoadedMore:
            name = "post_list_load_more_triggered"
        case .postListNoResultsButtonPressed:
            name = "post_list_create_post_tapped"
        case .postListOpenedCellMenu:
            name = "post_list_cell_menu_opened"
        case .postListPublishAction:
            name = "post_list_button_pressed"
            properties = [Constants.tracksEventPropertyButtonKey: "publish"]
        case .postListScheduleAction:
            name = "post_list_button_pressed"
            properties = [Constants.tracksEventPropertyButtonKey: "schedule"]
        case .postListPullToRefresh:
            name = "post_list_pull_to_refresh_triggered"
        case .postListRestoreAction:
            name = "post_list_button_pressed"
            properties = [Constants.tracksEventPropertyButtonKey: "restore"]
        case .postListSearchOpened:
            name = "post_list_search_opened"
        case .postListStatsAction:
            name = "post_list_button_pressed"
            properties = [Constants.tracksEventPropertyButtonKey: "stats"]
        case .postListStatusFilterChanged:
            name = "post_list_status_filter_changed"
        case .postListTrashAction:
            name = "post_list_button_pressed"
            properties = [Constants.tracksEventPropertyButtonKey: "trash"]
        case .postListViewAction:
            name = "post_list_button_pressed"
            properties = [Constants.tracksEventPropertyButtonKey: "view"]
        case .postListToggleButtonPressed:
            name = "post_list_toggle_button_pressed"
        case .postRevisionsListViewed:
            name = "revisions_list_viewed"
        case .postRevisionsDetailViewed:
            name = "revisions_detail_viewed"
        case .postRevisionsDetailCancelled:
            name = "revisions_detail_cancelled"
        case .postRevisionsRevisionLoaded:
            name = "revisions_revision_loaded"
        case .postRevisionsLoadUndone:
            name = "revisions_load_undone"
        case .postSettingsShown:
            name = "post_settings_shown"
        case .postSettingsAddTagsShown:
            name = "post_settings_add_tags_shown"
        case .postSettingsTagsAdded:
            name = "post_settings_tags_added"
        case .pushAuthenticationApproved:
            name = "push_authentication_approved"
        case .pushAuthenticationExpired:
            name = "push_authentication_expired"
        case .pushAuthenticationFailed:
            name = "push_authentication_failed"
        case .pushAuthenticationIgnored:
            name = "push_authentication_ignored"
        case .pushNotificationAlertPressed:
            name = "push_notification_alert_tapped"
        case .pushNotificationReceived:
            name = "push_notification_received"
        case .pushNotificationQuickActionCompleted:
            name = "quick_action_touched"
        case .pushNotificationPrimerSeen:
            name = "notifications_primer_seen"
        case .pushNotificationPrimerAllowTapped:
            name = "notifications_primer_allow_tapped"
        case .pushNotificationPrimerNoTapped:
            name = "notifications_primer_no_tapped"
        case .pushNotificationWinbackShown:
            name = "notifications_winback_shown"
        case .pushNotificationWinbackNoTapped:
            name = "notifications_winback_no_tapped"
        case .pushNotificationWinbackSettingsTapped:
            name = "notifications_winback_settings_tapped"
        case .pushNotificationOSAlertShown:
            name = "notifications_os_alert_shown"
        case .pushNotificationOSAlertAllowed:
            name = "notifications_os_alert_allowed"
        case .pushNotificationOSAlertDenied:
            name = "notifications_os_alert_denied"
        case .quickStartAllToursCompleted:
            name = "quick_start_all_tasks_completed"
        case .quickStartChecklistItemTapped:
            name = "quick_start_list_item_tapped"
        case .quickStartChecklistSkippedAll:
            name = "quick_start_list_all_tasks_skipped"
        case .quickStartChecklistViewed:
            name = "quick_start_list_viewed"
        case .quickStartCongratulationsViewed:
            name = "quick_start_list_completed_viewed"
        case .quickStartRequestAlertButtonTapped:
            name = "quick_start_request_dialog_button_tapped"
        case .quickStartRequestAlertViewed:
            name = "quick_start_request_dialog_viewed"
        case .quickStartSuggestionButtonTapped:
            name = "quick_start_dialog_button_tapped"
        case .quickStartSuggestionViewed:
            name = "quick_start_dialog_viewed"
        case .quickStartTourCompleted:
            name = "quick_start_task_completed"
        case .quickStartMigrationDialogViewed:
            name = "quick_start_migration_dialog_viewed"
        case .quickStartMigrationDialogPositiveTapped:
            name = "quick_start_migration_dialog_button_tapped"
            properties = ["type": "positive"]
        case .quickStartRemoveDialogButtonRemoveTapped:
            name = "quick_start_remove_dialog_button_tapped"
            properties = ["type": "positive"]
        case .quickStartRemoveDialogButtonCancelTapped:
            name = "quick_start_remove_dialog_button_tapped"
            properties = ["type": "negative"]
        case .quickStartTypeDismissed:
            name = "quick_start_type_dismissed"
        case .quickStartListCollapsed:
            name = "quick_start_list_collapsed"
        case .quickStartListExpanded:
            name = "quick_start_list_expanded"
        case .quickStartListItemSkipped:
            name = "quick_start_list_item_skipped"
        case .quickStartNotificationStarted:
            name = "quick_start_notification_sent"
        case .quickStartNotificationTapped:
            name = "quick_start_notification_tapped"
        case .readerAccessed:
            name = "reader_accessed"
        case .readerArticleCommentedOn:
            name = "reader_article_commented_on"
        case .readerArticleCommentLiked:
            name = "reader_article_comment_liked"
        case .readerArticleCommentUnliked:
            name = "reader_article_comment_unliked"
        case .readerArticleCommentsOpened:
            name = "reader_article_comments_opened"
        case .readerArticleLiked:
            name = "reader_article_liked"
        case .readerArticleReblogged:
            name = "reader_article_reblogged"
        case .readerArticleDetailReblogged:
            name = "reader_article_detail_reblogged"
        case .readerArticleOpened:
            name = "reader_article_opened"
        case .readerArticleUnliked:
            name = "reader_article_unliked"
        case .readerArticleDetailLiked:
            name = "reader_article_detail_liked"
        case .readerArticleDetailUnliked:
            name = "reader_article_detail_unliked"
        case .readerDiscoverViewed:
            name = "reader_discover_viewed"
        case .readerFreshlyPressedLoaded:
            name = "reader_freshly_pressed_loaded"
        case .readerInfiniteScroll:
            name = "reader_infinite_scroll_performed"
        case .readerListFollowed:
            name = "reader_list_followed"
        case .readerListLoaded:
            name = "reader_list_loaded"
        case .readerListPreviewed:
            name = "reader_list_preview"
        case .readerListUnfollowed:
            name = "reader_list_unfollowed"
        case .readerListNotificationMenuOn:
            name = "followed_blog_notifications_reader_menu_on"
        case .readerListNotificationMenuOff:
            name = "followed_blog_notifications_reader_menu_off"
        case .readerListNotificationEnabled:
            name = "followed_blog_notifications_reader_enabled"
        case .readerPostSaved:
            name = "reader_post_saved"
        case .readerPostUnsaved:
            name = "reader_post_unsaved"
        case .readerSavedPostOpened:
            name = "reader_saved_post_opened"
        case .readerSavedListViewed:
            name = "reader_saved_list_viewed"
        case .readerSearchLoaded:
            name = "reader_search_loaded"
        case .readerSearchPerformed:
            name = "reader_search_performed"
        case .readerSearchResultTapped:
            name = "reader_searchcard_clicked"
        case .readerSiteBlocked:
            name = "reader_blog_blocked"
        case .readerSiteFollowed:
            name = "reader_site_followed"
        case .readerSitePreviewed:
            name = "reader_blog_preview"
        case .readerSiteUnfollowed:
            name = "reader_site_unfollowed"
        case .readerSiteShared:
            name = "reader_site_shared"
        case .readerTagFollowed:
            name = "reader_reader_tag_followed"
            properties = ["source": "unknown"]
        case .readerTagLoaded:
            name = "reader_tag_loaded"
        case .readerTagPreviewed:
            name = "reader_tag_preview"
        case .readerTagUnfollowed:
            name = "reader_reader_tag_unfollowed"
        case .selectedInstallJetpack:
            name = "install_jetpack_selected"
        case .sentItemToGooglePlus:
            name = "sent_item_to_google_plus"
        case .sentItemToInstapaper:
            name = "sent_item_to_instapaper"
        case .sentItemToPocket:
            name = "sent_item_to_pocket"
        case .sentItemToWordPress:
            name = "sent_item_to_wordpress"
        case .sharedItem:
            name = "shared_item"
        case .sharedItemViaEmail:
            name = "shared_item_via_email"
        case .sharedItemViaFacebook:
            name = "shared_item_via_facebook"
        case .sharedItemViaSMS:
            name = "shared_item_via_sms"
        case .sharedItemViaTwitter:
            name = "shared_item_via_twitter"
        case .sharedItemViaWeibo:
            name = "shared_item_via_weibo"
        case .shortcutLogIn:
            name = "3d_touch_shortcut_log_in"
        case .shortcutNewPost:
            name = "3d_touch_shortcut_new_post"
        case .shortcutNotifications:
            name = "3d_touch_shortcut_notifications"
        case .shortcutNewPhotoPost:
            name = "3d_touch_shortcut_new_photo_post"
        case .shortcutStats:
            name = "3d_touch_shortcut_stats"
        case .signedIn:
            name = "signed_in"
        case .signedInToJetpack:
            name = "signed_into_jetpack"
        case .signupButtonTapped:
            name = "signup_button_tapped"
        case .signupCancelled:
            name = "signup_cancelled"
        case .signupEmailButtonTapped:
            name = "signup_email_button_tapped"
        case .signupEmailToLogin:
            name = "signup_email_to_login"
        case .signupEpilogueViewed:
            name = "signup_epilogue_viewed"
        case .signupEpilogueUnchanged:
            name = "signup_epilogue_unchanged"
        case .signupEpilogueDisplayNameUpdateSucceeded:
            name = "signup_epilogue_update_display_name_succeeded"
        case .signupEpilogueDisplayNameUpdateFailed:
            name = "signup_epilogue_update_display_name_failed"
        case .signupEpiloguePasswordUpdateSucceeded:
            name = "signup_epilogue_update_password_succeeded"
        case .signupEpiloguePasswordUpdateFailed:
            name = "signup_epilogue_update_password_failed"
        case .signupEpilogueUsernameTapped:
            name = "signup_epilogue_username_tapped"
        case .signupEpilogueUsernameSuggestionsFailed:
            name = "signup_epilogue_username_suggestions_failed"
        case .signupEpilogueUsernameUpdateSucceeded:
            name = "signup_epilogue_update_username_succeeded"
        case .signupEpilogueUsernameUpdateFailed:
            name = "signup_epilogue_update_username_failed"
        case .signupMagicLinkFailed:
            name = "signup_magic_link_failed"
        case .signupMagicLinkOpenEmailClientViewed:
            name = "signup_magic_link_open_email_client_viewed"
        case .signupMagicLinkOpened:
            name = "signup_magic_link_opened"
        case .signupMagicLinkSucceeded:
            name = "signup_magic_link_succeeded"
        case .signupSocialSuccess:
            name = "signup_social_success"
        case .signupSocialFailure:
            name = "signup_social_failure"
        case .signupSocialButtonFailure:
            name = "signup_social_button_failure"
        case .signupSocialButtonTapped:
            name = "signup_social_button_tapped"
        case .signupSocialToLogin:
            name = "signup_social_to_login"
        case .signupMagicLinkRequested:
            name = "signup_magic_link_requested"
        case .signupTermsButtonTapped:
            name = "signup_terms_of_service_tapped"
        case .siteSettingsSiteIconTapped:
            name = "my_site_icon_tapped"
        case .siteSettingsSiteIconRemoved:
            name = "my_site_icon_removed"
        case .siteSettingsSiteIconShotNew:
            name = "my_site_icon_shot_new"
        case .siteSettingsSiteIconGalleryPicked:
            name = "my_site_icon_gallery_picked"
        case .siteSettingsSiteIconCropped:
            name = "my_site_icon_cropped"
        case .siteSettingsSiteIconUploaded:
            name = "my_site_icon_uploaded"
        case .siteSettingsSiteIconUploadFailed:
            name = "my_site_icon_upload_unsuccessful"
        case .siteSettingsDeleteSiteAccessed:
            name = "site_settings_delete_site_accessed"
        case .siteSettingsDeleteSitePurchasesRequested:
            name = "site_settings_delete_site_purchases_requested"
        case .siteSettingsDeleteSitePurchasesShowClicked:
            name = "site_settings_delete_site_purchases_show_clicked"
        case .siteSettingsDeleteSitePurchasesShown:
            name = "site_settings_delete_site_purchases_shown"
        case .siteSettingsDeleteSiteRequested:
            name = "site_settings_delete_site_requested"
        case .siteSettingsDeleteSiteResponseError:
            name = "site_settings_delete_site_response_error"
        case .siteSettingsDeleteSiteResponseOK:
            name = "site_settings_delete_site_response_ok"
        case .siteSettingsExportSiteAccessed:
            name = "site_settings_export_site_accessed"
        case .siteSettingsExportSiteRequested:
            name = "site_settings_export_site_requested"
        case .siteSettingsExportSiteResponseError:
            name = "site_settings_export_site_response_error"
        case .siteSettingsExportSiteResponseOK:
            name = "site_settings_export_site_response_ok"
        case .siteSettingsStartOverAccessed:
            name = "site_settings_start_over_accessed"
        case .siteSettingsStartOverContactSupportClicked:
            name = "site_settings_start_over_contact_support_clicked"
        case .spotlightSearchOpenedApp:
            name = "spotlight_search_opened_app"
        case .spotlightSearchOpenedPost:
            name = "spotlight_search_opened_post"
        case .spotlightSearchOpenedPage:
            name = "spotlight_search_opened_page"
        case .spotlightSearchOpenedReaderPost:
            name = "spotlight_search_opened_reader_post"
        case .skippedConnectingToJetpack:
            name = "skipped_connecting_to_jetpack"
        case .statsAccessed:
            name = "stats_accessed"
        case .statsSubscribersAccessed:
            name = "stats_subscribers_accessed"
        case .statsDateTappedBackward:
            name = "stats_date_tapped_backward"
        case .statsDateTappedForward:
            name = "stats_date_tapped_forward"
        case .statsInsightsAccessed:
            name = "stats_insights_accessed"
        case .statsItemSelectedAddInsight:
            name = "stats_add_insight_item_selected"
        case .statsItemTappedAuthors:
            name = "stats_authors_view_post_tapped"
        case .statsItemTappedClicks:
            name = "stats_clicks_item_tapped"
        case .statsItemTappedInsightMoveDown:
            name = "stats_insight_move_down_tapped"
        case .statsItemTappedInsightMoveUp:
            name = "stats_insight_move_up_tapped"
        case .statsItemTappedInsightRemove:
            name = "stats_insight_remove_tapped"
        case .statsItemTappedInsightsAddStat:
            name = "stats_add_insight_item_tapped"
        case .statsItemTappedPostStatsMonthsYears:
            name = "stats_posts_and_pages_months_years_item_tapped"
        case .statsItemTappedPostStatsRecentWeeks:
            name = "stats_posts_and_pages_recent_weeks_item_tapped"
        case .statsItemTappedInsightsCustomizeDismiss:
            name = "stats_customize_insights_dismiss_item_tapped"
        case .statsItemTappedInsightsCustomizeTry:
            name = "stats_customize_insights_try_item_tapped"
        case .statsItemTappedLatestPostSummaryNewPost:
            name = "stats_latest_post_summary_add_new_post_tapped"
        case .statsItemTappedLatestPostSummarySharePost:
            name = "stats_latest_post_summary_share_post_tapped"
        case .statsItemTappedLatestPostSummaryPost:
            name = "stats_latest_post_summary_post_item_tapped"
        case .statsItemTappedLatestPostSummaryViewPostDetails:
            name = "stats_latest_post_summary_view_post_details_tapped"
        case .statsItemTappedManageInsight:
            name = "stats_manage_insight_tapped"
        case .statsItemTappedPostsAndPages:
            name = "stats_posts_and_pages_item_tapped"
        case .statsItemTappedPostingActivityDay:
            name = "stats_posting_activity_day_tapped"
        case .statsItemTappedSearchTerms:
            name = "stats_search_terms_item_tapped"
        case .statsItemTappedTagsAndCategories:
            name = "stats_tags_and_categories_view_tag_tapped"
        case .statsItemTappedVideoTapped:
            name = "stats_video_plays_video_tapped"
        case .statsOverviewBarChartTapped:
            name = "stats_overview_bar_chart_tapped"
        case .statsOverviewTypeTappedComments:
            name = "stats_overview_type_tapped_comments"
        case .statsOverviewTypeTappedLikes:
            name = "stats_overview_type_tapped_likes"
        case .statsOverviewTypeTappedViews:
            name = "stats_overview_type_tapped_views"
        case .statsOverviewTypeTappedVisitors:
            name = "stats_overview_type_tapped_visitors"
        case .statsPeriodDaysAccessed:
            name = "stats_period_accessed"
            properties = ["period": "days"]
        case .statsPeriodMonthsAccessed:
            name = "stats_period_accessed"
            properties = ["period": "months"]
        case .statsPeriodWeeksAccessed:
            name = "stats_period_accessed"
            properties = ["period": "weeks"]
        case .statsPeriodYearsAccessed:
            name = "stats_period_accessed"
            properties = ["period": "years"]
        case .statsScrolledToBottom:
            name = "stats_scrolled_to_bottom"
        case .statsSinglePostAccessed:
            name = "stats_single_post_accessed"
        case .statsTappedBarChart:
            name = "stats_bar_chart_tapped"
        case .statsViewAllAccessed:
            name = "stats_view_all_accessed"
        case .statsViewMoreTappedAuthors:
            name = "stats_authors_view_more_tapped"
        case .statsViewMoreTappedClicks:
            name = "stats_clicks_view_more_tapped"
        case .statsViewMoreTappedComments:
            name = "stats_comments_view_more_tapped"
        case .statsViewMoreTappedCountries:
            name = "stats_countries_view_more_tapped"
        case .statsViewMoreTappedFileDownloads:
            name = "stats_file_downloads_view_more_tapped"
        case .statsViewMoreTappedFollowers:
            name = "stats_followers_view_more_tapped"
        case .statsViewMoreTappedPostsAndPages:
            name = "stats_posts_and_pages_view_more_tapped"
        case .statsViewMoreTappedPostingActivity:
            name = "stats_posting_activity_view_more_tapped"
        case .statsViewMoreTappedPublicize:
            name = "stats_publicize_view_more_tapped"
        case .statsViewMoreTappedReferrers:
            name = "stats_referrers_view_more_tapped"
        case .statsViewMoreTappedSearchTerms:
            name = "stats_search_terms_view_more_tapped"
        case .statsViewMoreTappedTagsAndCategories:
            name = "stats_tags_and_categories_view_more_tapped"
        case .statsViewMoreTappedThisYear:
            name = "stats_this_year_view_more_tapped"
        case .statsViewMoreTappedVideoPlays:
            name = "stats_video_plays_view_more_tapped"
        case .stockMediaAccessed:
            name = "stock_media_accessed"
        case .stockMediaSearched:
            name = "stock_media_searched"
        case .stockMediaUploaded:
            name = "stock_media_uploaded"
        case .supportReceivedResponseFromSupport:
            name = "support_received_response_from_support"
        case .supportHelpCenterUserSearched:
            name = "support_help_center_user_searched"
        case .supportIdentityFormViewed:
            name = "support_identity_form_viewed"
        case .supportIdentitySet:
            name = "support_identity_set"
        case .supportHelpCenterViewed:
            name = "support_help_center_viewed"
        case .supportNewRequestViewed:
            name = "support_new_request_viewed"
        case .supportTicketListViewed:
            name = "support_ticket_list_viewed"
        case .supportNewRequestCreated:
            name = "support_new_request_created"
        case .supportNewRequestFailed:
            name = "support_new_request_failed"
        case .supportNewRequestFileAttached:
            name = "support_new_request_file_attached"
        case .supportNewRequestFileAttachmentFailed:
            name = "support_new_request_file_attachment_failed"
        case .supportTicketUserReplied:
            name = "support_ticket_user_replied"
        case .supportTicketUserReplyFailed:
            name = "support_ticket_user_reply_failed"
        case .supportTicketListViewFailed:
            name = "support_ticket_list_view_failed"
        case .supportTicketUserViewed:
            name = "support_ticket_user_viewed"
        case .supportTicketViewFailed:
            name = "support_ticket_view_failed"
        case .themesAccessedThemeBrowser:
            name = "themes_theme_browser_accessed"
        case .themesAccessedSearch:
            name = "themes_search_accessed"
        case .themesChangedTheme:
            name = "themes_theme_changed"
        case .themesCustomizeAccessed:
            name = "themes_customize_accessed"
        case .themesDemoAccessed:
            name = "themes_demo_accessed"
        case .themesDetailsAccessed:
            name = "themes_details_accessed"
        case .themesPreviewedSite:
            name = "themes_theme_for_site_previewed"
        case .themesSupportAccessed:
            name = "themes_support_accessed"
        case .trainTracksInteract:
            name = "traintracks_interact"
        case .trainTracksRender:
            name = "traintracks_render"
        case .twoFactorCodeRequested:
            name = "two_factor_code_requested"
        case .twoFactorSentSMS:
            name = "two_factor_sent_sms"
        case .openedAccountSettings:
            name = "account_settings_opened"
        case .accountSettingsChangeUsernameSucceeded:
            name = "account_settings_change_username_succeeded"
        case .accountSettingsChangeUsernameFailed:
            name = "account_settings_change_username_failed"
        case .accountSettingsChangeUsernameSuggestionsFailed:
            name = "account_settings_change_username_suggestions_failed"
        case .openedAppSettings:
            name = "app_settings_opened"
        case .openedWebPreview:
            name = "web_preview_opened"
        case .openedMyProfile:
            name = "my_profile_opened"
        case .sharingButtonSettingsChanged:
            name = "sharing_buttons_settings_changed"
        case .sharingButtonOrderChanged:
            name = "sharing_buttons_order_changed"
        case .sharingButtonShowReblogChanged:
            name = "sharing_buttons_show_reblog_changed"
        case .sharingOpenedPublicize:
            name = "publicize_opened"
        case .sharingOpenedSharingButtonSettings:
            name = "sharing_buttons_opened"
        case .sharingPublicizeConnected:
            name = "publicize_service_connected"
        case .sharingPublicizeDisconnected:
            name = "publicize_service_disconnected"
        case .sharingPublicizeConnectionAvailableToAllChanged:
            name = "publicize_connection_availability_changed"
        case .loginMagicLinkExited:
            name = "login_magic_link_exited"
        case .loginMagicLinkFailed:
            name = "login_magic_link_failed"
        case .loginMagicLinkOpened:
            name = "login_magic_link_opened"
        case .loginMagicLinkRequested:
            name = "login_magic_link_requested"
        case .loginMagicLinkSucceeded:
            name = "login_magic_link_succeeded"
        case .shareExtensionError:
            name = "share_extension_error"
        case .searchAdsAttribution:
            name = "searchads_attribution_detail_received"
        case .debugDeletedOrphanedEntities:
            name = "debug_deleted_orphaned_entities"
        case .widgetActiveSiteChanged:
            name = "widget_active_site_changed"
        case .welcomeNoSitesInterstitialShown:
            name = "welcome_no_sites_interstitial_shown"
        case .welcomeNoSitesInterstitialButtonTapped:
            name = "welcome_no_sites_interstitial_button_tapped"
        case .welcomeNoSitesInterstitialDismissed:
            name = "welcome_no_sites_interstitial_dismissed"

            // The following are yet to be implemented.
            //
            // If you get test failures in AnalyticsTrackerAutomatticTracks, it's most likely
            // because there are new . enum values. This can mean that somebody is
            // currently working on it. In cases like this, add the enum values here, returning
            // as `nil`. The tests should pass.
        case .defaultAccountChanged,
                .noStat,
                .performedCoreDataMigrationFixFor45,
                .maxValue:
            return nil
        @unknown default:
            return nil
        }

        return TracksMappedEvent(name: name, properties: properties)
    }
}

private enum Constants {
    static let tracksEventPropertyButtonKey = "button"
    static let tracksEventPropertyMenuItemKey = "menu_item"
    static let tracksEventPropertyViaKey = "via"
}
