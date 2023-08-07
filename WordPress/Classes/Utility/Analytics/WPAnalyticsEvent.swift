import Foundation

// WPiOS-only events
@objc enum WPAnalyticsEvent: Int {

    case createSheetShown
    case createSheetActionTapped
    case createAnnouncementModalShown

    // Media Editor
    case mediaEditorShown
    case mediaEditorUsed
    case editorCreatedPage

    // Tenor
    case tenorAccessed
    case tenorSearched
    case tenorUploaded
    case mediaLibraryAddedPhotoViaTenor
    case editorAddedPhotoViaTenor

    // Settings and Prepublishing Nudges
    case editorPostPublishTap
    case editorPostPublishDismissed
    case editorPostScheduledChanged
    case editorPostTitleChanged
    case editorPostVisibilityChanged
    case editorPostTagsChanged
    case editorPostAuthorChanged
    case editorPostPublishNowTapped
    case editorPostCategoryChanged
    case editorPostStatusChanged
    case editorPostFormatChanged
    case editorPostFeaturedImageChanged
    case editorPostStickyChanged
    case editorPostLocationChanged
    case editorPostSlugChanged
    case editorPostExcerptChanged
    case editorPostSiteChanged

    // App Settings
    case appSettingsAppearanceChanged

    // Gutenberg Features
    case gutenbergUnsupportedBlockWebViewShown
    case gutenbergUnsupportedBlockWebViewClosed
    case gutenbergSuggestionSessionFinished
    case gutenbergEditorSettingsFetched
    case gutenbergEditorHelpShown
    case gutenbergEditorBlockInserted
    case gutenbergEditorBlockMoved

    // Notifications Permissions
    case pushNotificationsPrimerSeen
    case pushNotificationsPrimerAllowTapped
    case pushNotificationsPrimerNoTapped
    case secondNotificationsAlertSeen
    case secondNotificationsAlertAllowTapped
    case secondNotificationsAlertNoTapped

    // Reader
    case selectInterestsShown
    case selectInterestsPicked
    case readerDiscoverShown
    case readerFollowingShown
    case readerSavedListShown
    case readerLikedShown
    case readerA8CShown
    case readerP2Shown
    case readerBlogPreviewed
    case readerDiscoverPaginated
    case readerPostCardTapped
    case readerPullToRefresh
    case readerDiscoverTopicTapped
    case postCardMoreTapped
    case followedBlogNotificationsReaderMenuOff
    case followedBlogNotificationsReaderMenuOn
    case readerArticleVisited
    case itemSharedReader
    case readerBlogBlocked
    case readerAuthorBlocked
    case readerChipsMoreToggled
    case readerToggleFollowConversation
    case readerToggleCommentNotifications
    case readerMoreToggleFollowConversation
    case readerPostReported
    case readerPostAuthorReported
    case readerArticleDetailMoreTapped
    case readerSharedItem
    case readerSuggestedSiteVisited
    case readerSuggestedSiteToggleFollow
    case readerDiscoverContentPresented
    case readerPostMarkSeen
    case readerPostMarkUnseen
    case readerRelatedPostFromOtherSiteClicked
    case readerRelatedPostFromSameSiteClicked
    case readerSearchHistoryCleared
    case readerArticleLinkTapped
    case readerArticleImageTapped
    case readerFollowConversationTooltipTapped
    case readerFollowConversationAnchorTapped

    // Stats - Empty Stats nudges
    case statsPublicizeNudgeShown
    case statsPublicizeNudgeTapped
    case statsPublicizeNudgeDismissed
    case statsPublicizeNudgeCompleted
    case statsBloggingRemindersNudgeShown
    case statsBloggingRemindersNudgeTapped
    case statsBloggingRemindersNudgeDismissed
    case statsBloggingRemindersNudgeCompleted
    case statsReaderDiscoverNudgeShown
    case statsReaderDiscoverNudgeTapped
    case statsReaderDiscoverNudgeDismissed
    case statsReaderDiscoverNudgeCompleted
    case statsLineChartTapped

    // Stats - Insights
    case statsCustomizeInsightsShown
    case statsInsightsManagementSaved
    case statsInsightsManagementDismissed
    case statsInsightsViewMore
    case statsInsightsViewsVisitorsToggled
    case statsInsightsViewsGrowAudienceDismissed
    case statsInsightsViewsGrowAudienceConfirmed
    case statsInsightsAnnouncementShown
    case statsInsightsAnnouncementConfirmed
    case statsInsightsAnnouncementDismissed
    case statsInsightsTotalLikesGuideTapped

    // What's New - Feature announcements
    case featureAnnouncementShown
    case featureAnnouncementButtonTapped

    // Stories
    case storyIntroShown
    case storyIntroDismissed
    case storyIntroCreateStoryButtonTapped
    case storyAddedMedia
    case storyBlockAddMediaTapped

    // Jetpack
    case jetpackSettingsViewed
    case jetpackManageConnectionViewed
    case jetpackDisconnectTapped
    case jetpackDisconnectRequested
    case jetpackAllowlistedIpsViewed
    case jetpackAllowlistedIpsChanged
    case activitylogFilterbarSelectType
    case activitylogFilterbarResetType
    case activitylogFilterbarTypeButtonTapped
    case activitylogFilterbarRangeButtonTapped
    case activitylogFilterbarSelectRange
    case activitylogFilterbarResetRange
    case backupListOpened
    case backupFilterbarRangeButtonTapped
    case backupFilterbarSelectRange
    case backupFilterbarResetRange
    case restoreOpened
    case restoreConfirmed
    case restoreError
    case restoreNotifiyMeButtonTapped
    case backupDownloadOpened
    case backupDownloadConfirmed
    case backupFileDownloadError
    case backupNotifiyMeButtonTapped
    case backupFileDownloadTapped
    case backupDownloadShareLinkTapped

    // Jetpack Scan
    case jetpackScanAccessed
    case jetpackScanHistoryAccessed
    case jetpackScanHistoryFilter
    case jetpackScanThreatListItemTapped
    case jetpackScanRunTapped
    case jetpackScanIgnoreThreatDialogOpen
    case jetpackScanThreatIgnoreTapped
    case jetpackScanFixThreatDialogOpen
    case jetpackScanThreatFixTapped
    case jetpackScanAllThreatsOpen
    case jetpackScanAllthreatsFixTapped
    case jetpackScanError

    // Comments
    case commentViewed
    case commentApproved
    case commentUnApproved
    case commentLiked
    case commentUnliked
    case commentTrashed
    case commentSpammed
    case commentEditorOpened
    case commentEdited
    case commentRepliedTo
    case commentFilterChanged
    case commentSnackbarNext
    case commentFullScreenEntered
    case commentFullScreenExited

    // InviteLinks
    case inviteLinksGetStatus
    case inviteLinksGenerate
    case inviteLinksShare
    case inviteLinksDisable

    // Page Layout and Site Design Picker
    case categoryFilterSelected
    case categoryFilterDeselected

    // User Profile Sheet
    case userProfileSheetShown
    case userProfileSheetSiteShown

    // Blog preview by URL (that is, in a WebView)
    case blogUrlPreviewed

    // Likes list shown from Reader Post details
    case likeListOpened

    // When Likes list is scrolled
    case likeListFetchedMore

    // Recommend app to others
    case recommendAppEngaged
    case recommendAppContentFetchFailed

    // Domains
    case domainsDashboardViewed
    case domainsDashboardAddDomainTapped
    case domainsSearchSelectDomainTapped
    case domainsRegistrationFormViewed
    case domainsRegistrationFormSubmitted
    case domainsPurchaseWebviewViewed
    case domainsPurchaseSucceeded

    // My Site
    case mySitePullToRefresh

    // My Site: No sites view displayed
    case mySiteNoSitesViewDisplayed
    case mySiteNoSitesViewActionTapped
    case mySiteNoSitesViewHidden

    // Site Switcher
    case mySiteSiteSwitcherTapped
    case siteSwitcherDisplayed
    case siteSwitcherDismissed
    case siteSwitcherToggleEditTapped
    case siteSwitcherAddSiteTapped
    case siteSwitcherSearchPerformed
    case siteSwitcherToggleBlogVisible

    // Post List
    case postListShareAction
    case postListSetAsPostsPageAction
    case postListSetHomePageAction

    // Page List
    case pageListEditHomepageTapped
    case pageListEditHomepageInfoTapped

    // Reader: Filter Sheet
    case readerFilterSheetDisplayed
    case readerFilterSheetDismissed
    case readerFilterSheetItemSelected
    case readerFilterSheetCleared

    // Reader: Manage
    case readerManageViewDisplayed
    case readerManageViewDismissed

    // App Settings
    case settingsDidChange
    case initialScreenChanged

    // Account Close
    case accountCloseTapped
    case accountCloseCompleted

    // App Settings
    case appSettingsClearMediaCacheTapped
    case appSettingsClearSpotlightIndexTapped
    case appSettingsClearSiriSuggestionsTapped
    case appSettingsOpenDeviceSettingsTapped

    // Notifications
    case notificationsPreviousTapped
    case notificationsNextTapped
    case notificationsMarkAllReadTapped
    case notificationMarkAsReadTapped
    case notificationMarkAsUnreadTapped

    // Sharing Buttons
    case sharingButtonsEditSharingButtonsToggled
    case sharingButtonsEditMoreButtonToggled
    case sharingButtonsLabelChanged

    // Comment Sharing
    case readerArticleCommentShared
    case siteCommentsCommentShared

    // People
    case peopleFilterChanged
    case peopleUserInvited

    // Login: Epilogue
    case loginEpilogueChooseSiteTapped
    case loginEpilogueCreateNewSiteTapped

    // WebKitView
    case webKitViewDisplayed
    case webKitViewDismissed
    case webKitViewOpenInSafariTapped
    case webKitViewReloadTapped
    case webKitViewShareTapped
    case webKitViewNavigatedBack
    case webKitViewNavigatedForward

    // Preview WebKitView
    case previewWebKitViewDeviceChanged

    // Add Site
    case addSiteAlertDisplayed

    // Change Username
    case changeUsernameSearchPerformed
    case changeUsernameDisplayed
    case changeUsernameDismissed

    // My Site Dashboard
    case dashboardCardShown
    case dashboardCardItemTapped
    case dashboardCardContextualMenuAccessed
    case dashboardCardHideTapped
    case mySiteTabTapped
    case mySiteSiteMenuShown
    case mySiteDashboardShown
    case mySiteDefaultTabExperimentVariantAssigned

    // Site Intent Question
    case enhancedSiteCreationIntentQuestionCanceled
    case enhancedSiteCreationIntentQuestionSkipped
    case enhancedSiteCreationIntentQuestionVerticalSelected
    case enhancedSiteCreationIntentQuestionCustomVerticalSelected
    case enhancedSiteCreationIntentQuestionSearchFocused
    case enhancedSiteCreationIntentQuestionViewed
    case enhancedSiteCreationIntentQuestionExperiment

    // Site Name
    case enhancedSiteCreationSiteNameCanceled
    case enhancedSiteCreationSiteNameSkipped
    case enhancedSiteCreationSiteNameEntered
    case enhancedSiteCreationSiteNameViewed

    // Quick Start
    case quickStartStarted
    case quickStartTapped

    // Onboarding Question Prompt
    case onboardingQuestionsDisplayed
    case onboardingQuestionsItemSelected
    case onboardingQuestionsSkipped

    // Onboarding Enable Notifications Prompt
    case onboardingEnableNotificationsDisplayed
    case onboardingEnableNotificationsSkipped
    case onboardingEnableNotificationsEnableTapped

    // QR Login
    case qrLoginScannerDisplayed
    case qrLoginScannerScannedCode
    case qrLoginScannerDismissed

    case qrLoginCameraPermissionDisplayed
    case qrLoginCameraPermissionApproved
    case qrLoginCameraPermissionDenied

    case qrLoginVerifyCodeDisplayed
    case qrLoginVerifyCodeDismissed
    case qrLoginVerifyCodeScanAgain
    case qrLoginVerifyCodeFailed
    case qrLoginVerifyCodeTokenValidated
    case qrLoginVerifyCodeApproved
    case qrLoginVerifyCodeCancelled
    case qrLoginAuthenticated
    // Blogging Reminders Notification
    case bloggingRemindersNotificationReceived

    // Blogging Prompts
    case promptsBottomSheetAnswerPrompt
    case promptsBottomSheetHelp
    case promptsBottomSheetViewed
    case promptsIntroductionModalViewed
    case promptsIntroductionModalDismissed
    case promptsIntroductionModalTryItNow
    case promptsIntroductionModalRemindMe
    case promptsIntroductionModalGotIt
    case promptsDashboardCardAnswerPrompt
    case promptsDashboardCardMenu
    case promptsDashboardCardMenuViewMore
    case promptsDashboardCardMenuSkip
    case promptsDashboardCardMenuRemove
    case promptsDashboardCardMenuLearnMore
    case promptsDashboardCardViewed
    case promptsListViewed
    case promptsReminderSettingsIncludeSwitch
    case promptsReminderSettingsHelp
    case promptsNotificationAnswerActionTapped
    case promptsNotificationDismissActionTapped
    case promptsNotificationTapped
    case promptsNotificationDismissed
    case promptsOtherAnswersTapped
    case promptsSettingsShowPromptsTapped

    // Jetpack branding
    case jetpackPoweredBadgeTapped
    case jetpackPoweredBannerTapped
    case jetpackPoweredBottomSheetButtonTapped
    case jetpackFullscreenOverlayDisplayed
    case jetpackFullscreenOverlayLinkTapped
    case jetpackFullscreenOverlayButtonTapped
    case jetpackFullscreenOverlayDismissed
    case jetpackSiteCreationOverlayDisplayed
    case jetpackSiteCreationOverlayButtonTapped
    case jetpackSiteCreationOverlayDismissed
    case jetpackBrandingMenuCardDisplayed
    case jetpackBrandingMenuCardTapped
    case jetpackBrandingMenuCardLinkTapped
    case jetpackBrandingMenuCardHidden
    case jetpackBrandingMenuCardRemindLater
    case jetpackBrandingMenuCardContextualMenuAccessed
    case jetpackFeatureIncorrectlyAccessed

    // Jetpack plugin overlay modal
    case jetpackInstallPluginModalViewed
    case jetpackInstallPluginModalDismissed
    case jetpackInstallPluginModalInstallTapped
    case wordPressInstallPluginModalViewed
    case wordPressInstallPluginModalDismissed
    case wordPressInstallPluginModalSwitchTapped

    // Jetpack full plugin installation for individual sites
    case jetpackInstallFullPluginViewed
    case jetpackInstallFullPluginCancelTapped
    case jetpackInstallFullPluginInstallTapped
    case jetpackInstallFullPluginRetryTapped
    case jetpackInstallFullPluginCompleted
    case jetpackInstallFullPluginDoneTapped
    case jetpackInstallFullPluginCardViewed
    case jetpackInstallFullPluginCardTapped
    case jetpackInstallFullPluginCardDismissed

    // Blaze
    case blazeEntryPointDisplayed
    case blazeEntryPointTapped
    case blazeContextualMenuAccessed
    case blazeCardHidden
    case blazeCardLearnMoreTapped
    case blazeOverlayDisplayed
    case blazeOverlayButtonTapped
    case blazeOverlayDismissed
    case blazeFlowStarted
    case blazeFlowCanceled
    case blazeFlowCompleted
    case blazeFlowError
    case blazeCampaignListOpened
    case blazeCampaignDetailsOpened
    case blazeCampaignDetailsError
    case blazeCampaignDetailsDismissed

    // Moved to Jetpack static screen
    case removeStaticPosterDisplayed
    case removeStaticPosterButtonTapped
    case removeStaticPosterLinkTapped

    // Help & Support
    case supportOpenMobileForumTapped
    case supportMigrationFAQButtonTapped
    case supportMigrationFAQCardViewed

    // Jetpack plugin connection to user's WP.com account
    case jetpackPluginConnectUserAccountStarted
    case jetpackPluginConnectUserAccountFailed
    case jetpackPluginConnectUserAccountCompleted

    // Domains Dashboard Card
    case directDomainsPurchaseDashboardCardShown
    case directDomainsPurchaseDashboardCardTapped
    case directDomainsPurchaseDashboardCardHidden

    // Jetpack Social - Twitter Deprecation Notice
    case jetpackSocialTwitterNoticeLinkTapped

    // Jetpack Social Improvements v1
    case jetpackSocialConnectionToggled
    case jetpackSocialShareLimitDisplayed
    case jetpackSocialShareLimitDismissed
    case jetpackSocialUpgradeLinkTapped
    case jetpackSocialNoConnectionCardDisplayed
    case jetpackSocialNoConnectionCTATapped
    case jetpackSocialNoConnectionCardDismissed

    // Free to Paid Plans Dashboard Card
    case freeToPaidPlansDashboardCardShown
    case freeToPaidPlansDashboardCardTapped
    case freeToPaidPlansDashboardCardMenuTapped
    case freeToPaidPlansDashboardCardHidden

    /// A String that represents the event
    var value: String {
        switch self {
        case .createSheetShown:
            return "create_sheet_shown"
        case .createSheetActionTapped:
            return "create_sheet_action_tapped"
        case .createAnnouncementModalShown:
            return "create_announcement_modal_shown"
        // Media Editor
        case .mediaEditorShown:
            return "media_editor_shown"
        case .mediaEditorUsed:
            return "media_editor_used"
        case .editorCreatedPage:
            return "editor_page_created"
        // Tenor
        case .tenorAccessed:
            return "tenor_accessed"
        case .tenorSearched:
            return "tenor_searched"
        case .tenorUploaded:
            return "tenor_uploaded"
        case .mediaLibraryAddedPhotoViaTenor:
            return "media_library_photo_added"
        case .editorAddedPhotoViaTenor:
            return "editor_photo_added"
        // Editor
        case .editorPostPublishTap:
            return "editor_post_publish_tapped"
        case .editorPostPublishDismissed:
            return "editor_post_publish_dismissed"
        case .editorPostScheduledChanged:
            return "editor_post_scheduled_changed"
        case .editorPostTitleChanged:
            return "editor_post_title_changed"
        case .editorPostVisibilityChanged:
            return "editor_post_visibility_changed"
        case .editorPostTagsChanged:
            return "editor_post_tags_changed"
        case .editorPostPublishNowTapped:
            return "editor_post_publish_now_tapped"
        case .editorPostCategoryChanged:
            return "editor_post_category_changed"
        case .editorPostStatusChanged:
            return "editor_post_status_changed"
        case .editorPostFormatChanged:
            return "editor_post_format_changed"
        case .editorPostFeaturedImageChanged:
            return "editor_post_featured_image_changed"
        case .editorPostStickyChanged:
            return "editor_post_sticky_changed"
        case .editorPostAuthorChanged:
            return "editor_post_author_changed"
        case .editorPostLocationChanged:
            return "editor_post_location_changed"
        case .editorPostSlugChanged:
            return "editor_post_slug_changed"
        case .editorPostExcerptChanged:
            return "editor_post_excerpt_changed"
        case .editorPostSiteChanged:
            return "editor_post_site_changed"
        case .appSettingsAppearanceChanged:
            return "app_settings_appearance_changed"
        case .gutenbergUnsupportedBlockWebViewShown:
            return "gutenberg_unsupported_block_webview_shown"
        case .gutenbergUnsupportedBlockWebViewClosed:
            return "gutenberg_unsupported_block_webview_closed"
        case .gutenbergSuggestionSessionFinished:
            return "suggestion_session_finished"
        case .gutenbergEditorSettingsFetched:
            return "editor_settings_fetched"
        case .gutenbergEditorHelpShown:
            return "editor_help_shown"
        case .gutenbergEditorBlockInserted:
            return "editor_block_inserted"
        case .gutenbergEditorBlockMoved:
            return "editor_block_moved"
        // Notifications permissions
        case .pushNotificationsPrimerSeen:
            return "notifications_primer_seen"
        case .pushNotificationsPrimerAllowTapped:
            return "notifications_primer_allow_tapped"
        case .pushNotificationsPrimerNoTapped:
            return "notifications_primer_no_tapped"
        case .secondNotificationsAlertSeen:
            return "notifications_second_alert_seen"
        case .secondNotificationsAlertAllowTapped:
            return "notifications_second_alert_allow_tapped"
        case .secondNotificationsAlertNoTapped:
            return "notifications_second_alert_no_tapped"
        // Reader
        case .selectInterestsShown:
            return "select_interests_shown"
        case .selectInterestsPicked:
            return "select_interests_picked"
        case .readerDiscoverShown:
            return "reader_discover_shown"
        case .readerFollowingShown:
            return "reader_following_shown"
        case .readerLikedShown:
            return "reader_liked_shown"
        case .readerA8CShown:
            return "reader_a8c_shown"
        case .readerP2Shown:
            return "reader_p2_shown"
        case .readerSavedListShown:
            return "reader_saved_list_shown"
        case .readerBlogPreviewed:
            return "reader_blog_previewed"
        case .readerDiscoverPaginated:
            return "reader_discover_paginated"
        case .readerPostCardTapped:
            return "reader_post_card_tapped"
        case .readerPullToRefresh:
            return "reader_pull_to_refresh"
        case .readerDiscoverTopicTapped:
            return "reader_discover_topic_tapped"
        case .postCardMoreTapped:
            return "post_card_more_tapped"
        case .followedBlogNotificationsReaderMenuOff:
            return "followed_blog_notifications_reader_menu_off"
        case .followedBlogNotificationsReaderMenuOn:
            return "followed_blog_notifications_reader_menu_on"
        case .readerArticleVisited:
            return "reader_article_visited"
        case .itemSharedReader:
            return "item_shared_reader"
        case .readerBlogBlocked:
            return "reader_blog_blocked"
        case .readerAuthorBlocked:
            return "reader_author_blocked"
        case .readerChipsMoreToggled:
            return "reader_chips_more_toggled"
        case .readerToggleFollowConversation:
            return "reader_toggle_follow_conversation"
        case .readerToggleCommentNotifications:
            return "reader_toggle_comment_notifications"
        case .readerMoreToggleFollowConversation:
            return "reader_more_toggle_follow_conversation"
        case .readerPostReported:
            return "reader_post_reported"
        case .readerPostAuthorReported:
            return "reader_post_author_reported"
        case .readerArticleDetailMoreTapped:
            return "reader_article_detail_more_tapped"
        case .readerSharedItem:
            return "reader_shared_item"
        case .readerSuggestedSiteVisited:
            return "reader_suggested_site_visited"
        case .readerSuggestedSiteToggleFollow:
            return "reader_suggested_site_toggle_follow"
        case .readerDiscoverContentPresented:
            return "reader_discover_content_presented"
        case .readerPostMarkSeen:
            return "reader_mark_as_seen"
        case .readerPostMarkUnseen:
            return "reader_mark_as_unseen"
        case .readerRelatedPostFromOtherSiteClicked:
            return "reader_related_post_from_other_site_clicked"
        case .readerRelatedPostFromSameSiteClicked:
            return "reader_related_post_from_same_site_clicked"
        case .readerSearchHistoryCleared:
            return "reader_search_history_cleared"
        case .readerArticleLinkTapped:
            return "reader_article_link_tapped"
        case .readerArticleImageTapped:
            return "reader_article_image_tapped"
        case .readerFollowConversationTooltipTapped:
            return "reader_follow_conversation_tooltip_tapped"
        case .readerFollowConversationAnchorTapped:
            return "reader_follow_conversation_anchor_tapped"

        // Stats - Empty Stats nudges
        case .statsPublicizeNudgeShown:
            return "stats_publicize_nudge_shown"
        case .statsPublicizeNudgeTapped:
            return "stats_publicize_nudge_tapped"
        case .statsPublicizeNudgeDismissed:
            return "stats_publicize_nudge_dismissed"
        case .statsPublicizeNudgeCompleted:
            return "stats_publicize_nudge_completed"
        case .statsBloggingRemindersNudgeShown:
            return "stats_blogging_reminders_nudge_shown"
        case .statsBloggingRemindersNudgeTapped:
            return "stats_blogging_reminders_nudge_tapped"
        case .statsBloggingRemindersNudgeDismissed:
            return "stats_blogging_reminders_nudge_dismissed"
        case .statsBloggingRemindersNudgeCompleted:
            return "stats_blogging_reminders_nudge_completed"
        case .statsReaderDiscoverNudgeShown:
            return "stats_reader_discover_nudge_shown"
        case .statsReaderDiscoverNudgeTapped:
            return "stats_reader_discover_nudge_tapped"
        case .statsReaderDiscoverNudgeDismissed:
            return "stats_reader_discover_nudge_dismissed"
        case .statsReaderDiscoverNudgeCompleted:
            return "stats_reader_discover_nudge_completed"
        case .statsLineChartTapped:
            return "stats_line_chart_tapped"

        // Stats - Insights
        case .statsCustomizeInsightsShown:
            return "stats_customize_insights_shown"
        case .statsInsightsManagementSaved:
            return "stats_insights_management_saved"
        case .statsInsightsManagementDismissed:
            return "stats_insights_management_dismissed"
        case .statsInsightsViewMore:
            return "stats_insights_view_more"
        case .statsInsightsViewsVisitorsToggled:
            return "stats_insights_views_visitors_toggled"
        case .statsInsightsViewsGrowAudienceDismissed:
            return "stats_insights_views_grow_audience_dismissed"
        case .statsInsightsViewsGrowAudienceConfirmed:
            return "stats_insights_views_grow_audience_confirmed"
        case .statsInsightsAnnouncementShown:
            return "stats_insights_announcement_shown"
        case .statsInsightsAnnouncementConfirmed:
            return "stats_insights_announcement_confirmed"
        case .statsInsightsAnnouncementDismissed:
            return "stats_insights_announcement_dismissed"
        case .statsInsightsTotalLikesGuideTapped:
            return "stats_insights_total_likes_guide_tapped"

        // What's New - Feature announcements
        case .featureAnnouncementShown:
            return "feature_announcement_shown"
        case .featureAnnouncementButtonTapped:
            return "feature_announcement_button_tapped"

        // Stories
        case .storyIntroShown:
            return "story_intro_shown"
        case .storyIntroDismissed:
            return "story_intro_dismissed"
        case .storyIntroCreateStoryButtonTapped:
            return "story_intro_create_story_button_tapped"
        case .storyAddedMedia:
            return "story_added_media"
        case .storyBlockAddMediaTapped:
            return "story_block_add_media_tapped"

        // Jetpack
        case .jetpackSettingsViewed:
            return "jetpack_settings_viewed"
        case .jetpackManageConnectionViewed:
            return "jetpack_manage_connection_viewed"
        case .jetpackDisconnectTapped:
            return "jetpack_disconnect_tapped"
        case .jetpackDisconnectRequested:
            return "jetpack_disconnect_requested"
        case .jetpackAllowlistedIpsViewed:
            return "jetpack_allowlisted_ips_viewed"
        case .jetpackAllowlistedIpsChanged:
            return "jetpack_allowlisted_ips_changed"
        case .activitylogFilterbarSelectType:
            return "activitylog_filterbar_select_type"
        case .activitylogFilterbarResetType:
            return "activitylog_filterbar_reset_type"
        case .activitylogFilterbarTypeButtonTapped:
            return "activitylog_filterbar_type_button_tapped"
        case .activitylogFilterbarRangeButtonTapped:
            return "activitylog_filterbar_range_button_tapped"
        case .activitylogFilterbarSelectRange:
            return "activitylog_filterbar_select_range"
        case .activitylogFilterbarResetRange:
            return "activitylog_filterbar_reset_range"
        case .backupListOpened:
            return "jetpack_backup_list_opened"
        case .backupFilterbarRangeButtonTapped:
            return "jetpack_backup_filterbar_range_button_tapped"
        case .backupFilterbarSelectRange:
            return "jetpack_backup_filterbar_select_range"
        case .backupFilterbarResetRange:
            return "jetpack_backup_filterbar_reset_range"
        case .restoreOpened:
            return "jetpack_restore_opened"
        case .restoreConfirmed:
            return "jetpack_restore_confirmed"
        case .restoreError:
            return "jetpack_restore_error"
        case .restoreNotifiyMeButtonTapped:
            return "jetpack_restore_notify_me_button_tapped"
        case .backupDownloadOpened:
            return "jetpack_backup_download_opened"
        case .backupDownloadConfirmed:
            return "jetpack_backup_download_confirmed"
        case .backupFileDownloadError:
            return "jetpack_backup_file_download_error"
        case .backupNotifiyMeButtonTapped:
            return "jetpack_backup_notify_me_button_tapped"
        case .backupFileDownloadTapped:
            return "jetpack_backup_file_download_tapped"
        case .backupDownloadShareLinkTapped:
            return "jetpack_backup_download_share_link_tapped"

        // Jetpack Scan
        case .jetpackScanAccessed:
            return "jetpack_scan_accessed"
        case .jetpackScanHistoryAccessed:
            return "jetpack_scan_history_accessed"
        case .jetpackScanHistoryFilter:
            return "jetpack_scan_history_filter"
        case .jetpackScanThreatListItemTapped:
            return "jetpack_scan_threat_list_item_tapped"
        case .jetpackScanRunTapped:
            return "jetpack_scan_run_tapped"
        case .jetpackScanIgnoreThreatDialogOpen:
            return "jetpack_scan_ignorethreat_dialogopen"
        case .jetpackScanThreatIgnoreTapped:
            return "jetpack_scan_threat_ignore_tapped"
        case .jetpackScanFixThreatDialogOpen:
            return "jetpack_scan_fixthreat_dialogopen"
        case .jetpackScanThreatFixTapped:
            return "jetpack_scan_threat_fix_tapped"
        case .jetpackScanAllThreatsOpen:
            return "jetpack_scan_allthreats_open"
        case .jetpackScanAllthreatsFixTapped:
            return "jetpack_scan_allthreats_fix_tapped"
        case .jetpackScanError:
            return "jetpack_scan_error"

        // Comments
        case .commentViewed:
            return "comment_viewed"
        case .commentApproved:
            return "comment_approved"
        case .commentUnApproved:
            return "comment_unapproved"
        case .commentLiked:
            return "comment_liked"
        case .commentUnliked:
            return "comment_unliked"
        case .commentTrashed:
            return "comment_trashed"
        case .commentSpammed:
            return "comment_spammed"
        case .commentEditorOpened:
            return "comment_editor_opened"
        case .commentEdited:
            return "comment_edited"
        case .commentRepliedTo:
            return "comment_replied_to"
        case .commentFilterChanged:
            return "comment_filter_changed"
        case .commentSnackbarNext:
            return "comment_snackbar_next"
        case .commentFullScreenEntered:
            return "comment_fullscreen_entered"
        case .commentFullScreenExited:
            return "comment_fullscreen_exited"

        // Invite Links
        case .inviteLinksGetStatus:
            return "invite_links_get_status"
        case .inviteLinksGenerate:
            return "invite_links_generate"
        case .inviteLinksShare:
            return "invite_links_share"
        case .inviteLinksDisable:
            return "invite_links_disable"

        // Page Layout and Site Design Picker
        case .categoryFilterSelected:
            return "category_filter_selected"
        case .categoryFilterDeselected:
            return "category_filter_deselected"

        // User Profile Sheet
        case .userProfileSheetShown:
            return "user_profile_sheet_shown"
        case .userProfileSheetSiteShown:
            return "user_profile_sheet_site_shown"

        // Blog preview by URL (that is, in a WebView)
        case .blogUrlPreviewed:
            return "blog_url_previewed"

        // Likes list shown from Reader Post details
        case .likeListOpened:
            return "like_list_opened"

        // When Likes list is scrolled
        case .likeListFetchedMore:
            return "like_list_fetched_more"

        // When the recommend app button is tapped
        case .recommendAppEngaged:
            return "recommend_app_engaged"

        // When the content fetching for the recommend app failed
        case .recommendAppContentFetchFailed:
            return "recommend_app_content_fetch_failed"

        // Domains
        case .domainsDashboardViewed:
            return "domains_dashboard_viewed"
        case .domainsDashboardAddDomainTapped:
            return "domains_dashboard_add_domain_tapped"
        case .domainsSearchSelectDomainTapped:
            return "domains_dashboard_select_domain_tapped"
        case .domainsRegistrationFormViewed:
            return "domains_registration_form_viewed"
        case .domainsRegistrationFormSubmitted:
            return "domains_registration_form_submitted"
        case .domainsPurchaseWebviewViewed:
            return "domains_purchase_webview_viewed"
        case .domainsPurchaseSucceeded:
            return "domains_purchase_domain_success"

        // My Site
        case .mySitePullToRefresh:
            return "my_site_pull_to_refresh"

        // My Site No Sites View
        case .mySiteNoSitesViewDisplayed:
            return "my_site_no_sites_view_displayed"
        case .mySiteNoSitesViewActionTapped:
            return "my_site_no_sites_view_action_tapped"
        case .mySiteNoSitesViewHidden:
            return "my_site_no_sites_view_hidden"

        // Site Switcher
        case .mySiteSiteSwitcherTapped:
            return "my_site_site_switcher_tapped"
        case .siteSwitcherDisplayed:
            return "site_switcher_displayed"
        case .siteSwitcherDismissed:
            return "site_switcher_dismissed"
        case .siteSwitcherToggleEditTapped:
            return "site_switcher_toggle_edit_tapped"
        case .siteSwitcherAddSiteTapped:
            return "site_switcher_add_site_tapped"
        case .siteSwitcherSearchPerformed:
            return "site_switcher_search_performed"
        case .siteSwitcherToggleBlogVisible:
            return "site_switcher_toggle_blog_visible"

        // Post List
        case .postListShareAction:
            return "post_list_button_pressed"
        case .postListSetAsPostsPageAction:
            return "post_list_button_pressed"
        case .postListSetHomePageAction:
            return "post_list_button_pressed"

        // Page List
        case .pageListEditHomepageTapped:
            return "page_list_edit_homepage_item_pressed"
        case .pageListEditHomepageInfoTapped:
            return "page_list_edit_homepage_info_pressed"

        // Reader: Filter Sheet
        case .readerFilterSheetDisplayed:
            return "reader_filter_sheet_displayed"
        case .readerFilterSheetDismissed:
            return "reader_filter_sheet_dismissed"
        case .readerFilterSheetItemSelected:
            return "reader_filter_sheet_item_selected"
        case .readerFilterSheetCleared:
            return "reader_filter_sheet_cleared"

        // Reader: Manage View
        case .readerManageViewDisplayed:
            return "reader_manage_view_displayed"
        case .readerManageViewDismissed:
            return "reader_manage_view_dismissed"

        // App Settings
        case .settingsDidChange:
            return "settings_did_change"
        case .initialScreenChanged:
            return "app_settings_initial_screen_changed"
        case .appSettingsClearMediaCacheTapped:
            return "app_settings_clear_media_cache_tapped"
        case .appSettingsClearSpotlightIndexTapped:
            return "app_settings_clear_spotlight_index_tapped"
        case .appSettingsClearSiriSuggestionsTapped:
            return "app_settings_clear_siri_suggestions_tapped"
        case .appSettingsOpenDeviceSettingsTapped:
            return "app_settings_open_device_settings_tapped"

        // Account Close
        case .accountCloseTapped:
            return "account_close_tapped"
        case .accountCloseCompleted:
            return "account_close_completed"

        // Notifications
        case .notificationsPreviousTapped:
            return "notifications_previous_tapped"
        case .notificationsNextTapped:
            return "notifications_next_tapped"
        case .notificationsMarkAllReadTapped:
            return "notifications_mark_all_read_tapped"
        case .notificationMarkAsReadTapped:
            return "notification_mark_as_read_tapped"
        case .notificationMarkAsUnreadTapped:
            return "notification_mark_as_unread_tapped"

        // Sharing
        case .sharingButtonsEditSharingButtonsToggled:
            return "sharing_buttons_edit_sharing_buttons_toggled"
        case .sharingButtonsEditMoreButtonToggled:
            return "sharing_buttons_edit_more_button_toggled"
        case .sharingButtonsLabelChanged:
            return "sharing_buttons_label_changed"

        // Comment Sharing
        case .readerArticleCommentShared:
            return "reader_article_comment_shared"
        case .siteCommentsCommentShared:
            return "site_comments_comment_shared"

        // People
        case .peopleFilterChanged:
            return "people_management_filter_changed"
        case .peopleUserInvited:
            return "people_management_user_invited"

        // Login: Epilogue
        case .loginEpilogueChooseSiteTapped:
            return "login_epilogue_choose_site_tapped"
        case .loginEpilogueCreateNewSiteTapped:
            return "login_epilogue_create_new_site_tapped"

        // WebKitView
        case .webKitViewDisplayed:
            return "webkitview_displayed"
        case .webKitViewDismissed:
            return "webkitview_dismissed"
        case .webKitViewOpenInSafariTapped:
            return "webkitview_open_in_safari_tapped"
        case .webKitViewReloadTapped:
            return "webkitview_reload_tapped"
        case .webKitViewShareTapped:
            return "webkitview_share_tapped"
        case .webKitViewNavigatedBack:
            return "webkitview_navigated_back"
        case .webKitViewNavigatedForward:
            return "webkitview_navigated_forward"

        case .previewWebKitViewDeviceChanged:
            return "preview_webkitview_device_changed"

        case .addSiteAlertDisplayed:
            return "add_site_alert_displayed"

        // Change Username
        case .changeUsernameSearchPerformed:
            return "change_username_search_performed"
        case .changeUsernameDisplayed:
            return "change_username_displayed"
        case .changeUsernameDismissed:
            return "change_username_dismissed"

        // My Site Dashboard
        case .dashboardCardShown:
            return "my_site_dashboard_card_shown"
        case .dashboardCardItemTapped:
            return "my_site_dashboard_card_item_tapped"
        case .dashboardCardContextualMenuAccessed:
            return "my_site_dashboard_contextual_menu_accessed"
        case .dashboardCardHideTapped:
            return "my_site_dashboard_card_hide_tapped"
        case .mySiteTabTapped:
            return "my_site_tab_tapped"
        case .mySiteSiteMenuShown:
            return "my_site_site_menu_shown"
        case .mySiteDashboardShown:
            return "my_site_dashboard_shown"
        case .mySiteDefaultTabExperimentVariantAssigned:
            return "my_site_default_tab_experiment_variant_assigned"

        // Quick Start
        case .quickStartStarted:
            return "quick_start_started"
        case .quickStartTapped:
            return "quick_start_tapped"

        // Site Intent Question
        case .enhancedSiteCreationIntentQuestionCanceled:
            return "enhanced_site_creation_intent_question_canceled"
        case .enhancedSiteCreationIntentQuestionSkipped:
            return "enhanced_site_creation_intent_question_skipped"
        case .enhancedSiteCreationIntentQuestionVerticalSelected:
            return "enhanced_site_creation_intent_question_vertical_selected"
        case .enhancedSiteCreationIntentQuestionCustomVerticalSelected:
            return "enhanced_site_creation_intent_question_custom_vertical_selected"
        case .enhancedSiteCreationIntentQuestionSearchFocused:
            return "enhanced_site_creation_intent_question_search_focused"
        case .enhancedSiteCreationIntentQuestionViewed:
            return "enhanced_site_creation_intent_question_viewed"
        case .enhancedSiteCreationIntentQuestionExperiment:
            return "enhanced_site_creation_intent_question_experiment"

        // Onboarding Question Prompt
        case .onboardingQuestionsDisplayed:
            return "onboarding_questions_displayed"
        case .onboardingQuestionsItemSelected:
            return "onboarding_questions_item_selected"
        case .onboardingQuestionsSkipped:
            return "onboarding_questions_skipped"

        // Onboarding Enable Notifications Prompt
        case .onboardingEnableNotificationsDisplayed:
            return "onboarding_enable_notifications_displayed"
        case .onboardingEnableNotificationsSkipped:
            return "onboarding_enable_notifications_skipped"
        case .onboardingEnableNotificationsEnableTapped:
            return "onboarding_enable_notifications_enable_tapped"

        // Site Name
        case .enhancedSiteCreationSiteNameCanceled:
            return "enhanced_site_creation_site_name_canceled"
        case .enhancedSiteCreationSiteNameSkipped:
            return "enhanced_site_creation_site_name_skipped"
        case .enhancedSiteCreationSiteNameEntered:
            return "enhanced_site_creation_site_name_entered"
        case .enhancedSiteCreationSiteNameViewed:
            return "enhanced_site_creation_site_name_viewed"

        // QR Login
        case .qrLoginScannerDisplayed:
            return "qrlogin_scanner_displayed"
        case .qrLoginScannerScannedCode:
            return "qrlogin_scanner_scanned_code"
        case .qrLoginScannerDismissed:
            return "qrlogin_scanned_dismissed"
        case .qrLoginVerifyCodeDisplayed:
            return "qrlogin_verify_displayed"
        case .qrLoginVerifyCodeDismissed:
            return "qrlogin_verify_dismissed"
        case .qrLoginVerifyCodeFailed:
            return "qrlogin_verify_failed"
        case .qrLoginVerifyCodeApproved:
            return "qrlogin_verify_approved"
        case .qrLoginVerifyCodeScanAgain:
            return "qrlogin_verify_scan_again"
        case .qrLoginVerifyCodeCancelled:
            return "qrlogin_verify_cancelled"
        case .qrLoginVerifyCodeTokenValidated:
            return "qrlogin_verify_token_validated"
        case .qrLoginAuthenticated:
            return "qrlogin_authenticated"
        case .qrLoginCameraPermissionDisplayed:
            return "qrlogin_camera_permission_displayed"
        case .qrLoginCameraPermissionApproved:
            return "qrlogin_camera_permission_approved"
        case .qrLoginCameraPermissionDenied:
            return "qrlogin_camera_permission_denied"

        // Blogging Reminders Notification
        case .bloggingRemindersNotificationReceived:
            return "blogging_reminders_notification_received"

        // Blogging Prompts
        case .promptsBottomSheetAnswerPrompt:
            return "my_site_create_sheet_answer_prompt_tapped"
        case .promptsBottomSheetHelp:
            return "my_site_create_sheet_prompt_help_tapped"
        case .promptsBottomSheetViewed:
            return "blogging_prompts_create_sheet_card_viewed"
        case .promptsIntroductionModalViewed:
            return "blogging_prompts_introduction_modal_viewed"
        case .promptsIntroductionModalDismissed:
            return "blogging_prompts_introduction_modal_dismissed"
        case .promptsIntroductionModalTryItNow:
            return "blogging_prompts_introduction_modal_try_it_now_tapped"
        case .promptsIntroductionModalRemindMe:
            return "blogging_prompts_introduction_modal_remind_me_tapped"
        case .promptsIntroductionModalGotIt:
            return "blogging_prompts_introduction_modal_got_it_tapped"
        case .promptsDashboardCardAnswerPrompt:
            return "blogging_prompts_my_site_card_answer_prompt_tapped"
        case .promptsDashboardCardMenu:
            return "blogging_prompts_my_site_card_menu_tapped"
        case .promptsDashboardCardMenuViewMore:
            return "blogging_prompts_my_site_card_menu_view_more_prompts_tapped"
        case .promptsDashboardCardMenuSkip:
            return "blogging_prompts_my_site_card_menu_skip_this_prompt_tapped"
        case .promptsDashboardCardMenuRemove:
            return "blogging_prompts_my_site_card_menu_remove_from_dashboard_tapped"
        case .promptsDashboardCardMenuLearnMore:
            return "blogging_prompts_my_site_card_menu_learn_more_tapped"
        case .promptsDashboardCardViewed:
            return "blogging_prompts_my_site_card_viewed"
        case .promptsListViewed:
            return "blogging_prompts_prompts_list_viewed"
        case .promptsReminderSettingsIncludeSwitch:
            return "blogging_reminders_include_prompt_tapped"
        case .promptsReminderSettingsHelp:
            return "blogging_reminders_include_prompt_help_tapped"
        case .promptsNotificationAnswerActionTapped:
            return "blogging_reminders_notification_prompt_answer_tapped"
        case .promptsNotificationDismissActionTapped:
            return "blogging_reminders_notification_prompt_dismiss_tapped"
        case .promptsNotificationTapped:
            return "blogging_reminders_notification_prompt_tapped"
        case .promptsNotificationDismissed:
            return "blogging_reminders_notification_prompt_dismissed"
        case .promptsOtherAnswersTapped:
            return "blogging_prompts_my_site_card_view_answers_tapped"
        case .promptsSettingsShowPromptsTapped:
            return "blogging_prompts_settings_show_prompts_tapped"

        // Jetpack branding
        case .jetpackPoweredBadgeTapped:
            return "jetpack_powered_badge_tapped"
        case .jetpackPoweredBannerTapped:
            return "jetpack_powered_banner_tapped"
        case .jetpackPoweredBottomSheetButtonTapped:
            return "jetpack_powered_bottom_sheet_button_tapped"
        case .jetpackFullscreenOverlayDisplayed:
            return "remove_feature_overlay_displayed"
        case .jetpackFullscreenOverlayLinkTapped:
            return "remove_feature_overlay_link_tapped"
        case .jetpackFullscreenOverlayButtonTapped:
            return "remove_feature_overlay_button_tapped"
        case .jetpackFullscreenOverlayDismissed:
            return "remove_feature_overlay_dismissed"
        case .jetpackSiteCreationOverlayDisplayed:
            return "remove_site_creation_overlay_displayed"
        case .jetpackSiteCreationOverlayButtonTapped:
            return "remove_site_creation_overlay_button_tapped"
        case .jetpackSiteCreationOverlayDismissed:
            return "remove_site_creation_overlay_dismissed"
        case .jetpackBrandingMenuCardDisplayed:
            return "remove_feature_card_displayed"
        case .jetpackBrandingMenuCardTapped:
            return "remove_feature_card_tapped"
        case .jetpackBrandingMenuCardLinkTapped:
            return "remove_feature_card_link_tapped"
        case .jetpackBrandingMenuCardHidden:
            return "remove_feature_card_hide_tapped"
        case .jetpackBrandingMenuCardRemindLater:
            return "remove_feature_card_remind_later_tapped"
        case .jetpackBrandingMenuCardContextualMenuAccessed:
            return "remove_feature_card_menu_accessed"
        case .jetpackFeatureIncorrectlyAccessed:
            return "jetpack_feature_incorrectly_accessed"

        // Jetpack plugin overlay modal
        case .jetpackInstallPluginModalViewed:
            return "jp_install_full_plugin_onboarding_modal_viewed"
        case .jetpackInstallPluginModalDismissed:
            return "jp_install_full_plugin_onboarding_modal_dismissed"
        case .jetpackInstallPluginModalInstallTapped:
            return "jp_install_full_plugin_onboarding_modal_install_tapped"
        case .wordPressInstallPluginModalViewed:
            return "wp_individual_site_overlay_viewed"
        case .wordPressInstallPluginModalDismissed:
            return "wp_individual_site_overlay_dismissed"
        case .wordPressInstallPluginModalSwitchTapped:
            return "wp_individual_site_overlay_primary_tapped"

        // Jetpack full plugin installation for individual sites
        case .jetpackInstallFullPluginViewed:
            return "jp_install_full_plugin_flow_viewed"
        case .jetpackInstallFullPluginInstallTapped:
            return "jp_install_full_plugin_flow_install_tapped"
        case .jetpackInstallFullPluginCancelTapped:
            return "jp_install_full_plugin_flow_cancel_tapped"
        case .jetpackInstallFullPluginRetryTapped:
            return "jp_install_full_plugin_flow_retry_tapped"
        case .jetpackInstallFullPluginCompleted:
            return "jp_install_full_plugin_flow_success"
        case .jetpackInstallFullPluginDoneTapped:
            return "jp_install_full_plugin_flow_done_tapped"
        case .jetpackInstallFullPluginCardViewed:
            return "jp_install_full_plugin_card_viewed"
        case .jetpackInstallFullPluginCardTapped:
            return "jp_install_full_plugin_card_tapped"
        case .jetpackInstallFullPluginCardDismissed:
            return "jp_install_full_plugin_card_dismissed"

        // Blaze
        case .blazeEntryPointDisplayed:
            return "blaze_entry_point_displayed"
        case .blazeEntryPointTapped:
            return "blaze_entry_point_tapped"
        case .blazeContextualMenuAccessed:
            return "blaze_entry_point_menu_accessed"
        case .blazeCardHidden:
            return "blaze_entry_point_hide_tapped"
        case .blazeCardLearnMoreTapped:
            return "blaze_entry_point_learn_more_tapped"
        case .blazeOverlayDisplayed:
            return "blaze_overlay_displayed"
        case .blazeOverlayButtonTapped:
            return "blaze_overlay_button_tapped"
        case .blazeOverlayDismissed:
            return "blaze_overlay_dismissed"
        case .blazeFlowStarted:
            return "blaze_flow_started"
        case .blazeFlowCanceled:
            return "blaze_flow_canceled"
        case .blazeFlowCompleted:
            return "blaze_flow_completed"
        case .blazeFlowError:
            return "blaze_flow_error"
        case .blazeCampaignListOpened:
            return "blaze_campaign_list_opened"
        case .blazeCampaignDetailsOpened:
            return "blaze_campaign_details_opened"
        case .blazeCampaignDetailsError:
            return "blaze_campaign_details_error"
        case .blazeCampaignDetailsDismissed:
            return "blaze_campaign_details_dismissed"

        // Moved to Jetpack static screen
        case .removeStaticPosterDisplayed:
            return "remove_static_poster_displayed"
        case .removeStaticPosterButtonTapped:
            return "remove_static_poster_get_jetpack_tapped"
        case .removeStaticPosterLinkTapped:
            return "remove_static_poster_link_tapped"

        // Help & Support
        case .supportOpenMobileForumTapped:
            return "support_open_mobile_forum_tapped"
        case .supportMigrationFAQButtonTapped:
            return "support_migration_faq_tapped"
        case .supportMigrationFAQCardViewed:
            return "support_migration_faq_viewed"

        // Jetpack plugin connection to user's WP.com account
        case .jetpackPluginConnectUserAccountStarted:
            return "jetpack_plugin_connect_user_account_started"
        case .jetpackPluginConnectUserAccountFailed:
            return "jetpack_plugin_connect_user_account_failed"
        case .jetpackPluginConnectUserAccountCompleted:
            return "jetpack_plugin_connect_user_account_completed"

        // Domains Dashboard Card
        case .directDomainsPurchaseDashboardCardShown:
            return "direct_domains_purchase_dashboard_card_shown"
        case .directDomainsPurchaseDashboardCardHidden:
            return "direct_domains_purchase_dashboard_card_hidden"
        case .directDomainsPurchaseDashboardCardTapped:
            return "direct_domains_purchase_dashboard_card_tapped"

        // Jetpack Social - Twitter Deprecation Notice
        case .jetpackSocialTwitterNoticeLinkTapped:
            return "twitter_notice_link_tapped"

        case .jetpackSocialConnectionToggled:
            return "jetpack_social_auto_sharing_connection_toggled"
        case .jetpackSocialShareLimitDisplayed:
            return "jetpack_social_share_limit_displayed"
        case .jetpackSocialShareLimitDismissed:
            return "jetpack_social_share_limit_dismissed"
        case .jetpackSocialUpgradeLinkTapped:
            return "jetpack_social_upgrade_link_tapped"
        case .jetpackSocialNoConnectionCardDisplayed:
            return "jetpack_social_add_connection_cta_displayed"
        case .jetpackSocialNoConnectionCTATapped:
            return "jetpack_social_add_connection_tapped"
        case .jetpackSocialNoConnectionCardDismissed:
            return "jetpack_social_add_connection_dismissed"

        // Free to Paid Plans Dashboard Card
        case .freeToPaidPlansDashboardCardShown:
            return "free_to_paid_plan_dashboard_card_shown"
        case .freeToPaidPlansDashboardCardHidden:
            return "free_to_paid_plan_dashboard_card_hidden"
        case .freeToPaidPlansDashboardCardTapped:
            return "free_to_paid_plan_dashboard_card_tapped"
        case .freeToPaidPlansDashboardCardMenuTapped:
            return "free_to_paid_plan_dashboard_card_menu_tapped"

        } // END OF SWITCH
    }

    /**
     The default properties of the event

     # Example
     ```
     case .mediaEditorShown:
        return ["from": "ios"]
     ```
    */
    var defaultProperties: [AnyHashable: Any]? {
        switch self {
        case .mediaLibraryAddedPhotoViaTenor:
            return ["via": "tenor"]
        case .editorAddedPhotoViaTenor:
            return ["via": "tenor"]
        case .postListShareAction:
            return ["button": "share"]
        case .postListSetAsPostsPageAction:
            return ["button": "set_posts_page"]
        case .postListSetHomePageAction:
            return ["button": "set_homepage"]
        default:
            return nil
        }
    }
}

extension WPAnalytics {

    @objc static var subscriptionCount: Int = 0

    private static let WPAppAnalyticsKeySubscriptionCount: String = "subscription_count"

    /// Track a event
    ///
    /// This will call each registered tracker and fire the given event.
    /// - Parameter event: a `String` that represents the event name
    /// - Note: If an event has its default properties, it will be passed through
    static func track(_ event: WPAnalyticsEvent) {
        WPAnalytics.trackString(event.value, withProperties: event.defaultProperties ?? [:])
    }

    /// Track a event
    ///
    /// This will call each registered tracker and fire the given event
    /// - Parameter event: a `String` that represents the event name
    /// - Parameter properties: a `Hash` that represents the properties
    ///
    static func track(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any]) {
        var mergedProperties: [AnyHashable: Any] = event.defaultProperties ?? [:]
        mergedProperties.merge(properties) { (_, new) in new }

        WPAnalytics.trackString(event.value, withProperties: mergedProperties)
    }

    /// This will call each registered tracker and fire the given event.
    /// - Parameters:
    ///   - event: a `String` that represents the event name
    ///   - properties: a `Hash` that represents the properties
    ///   - blog: a `Blog` asssociated with the event
    static func track(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any], blog: Blog) {
        var props = properties
        props[WPAppAnalyticsKeyBlogID] = blog.dotComID
        props[WPAppAnalyticsKeySiteType] = blog.isWPForTeams() ? WPAppAnalyticsValueSiteTypeP2 : WPAppAnalyticsValueSiteTypeBlog
        WPAnalytics.track(event, properties: props)
    }

    /// Track a Reader event
    ///
    /// This will call each registered tracker and fire the given event
    /// - Parameter event: a `String` that represents the Reader event name
    /// - Parameter properties: a `Hash` that represents the properties
    ///
    static func trackReader(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any] = [:]) {
        var props = properties
        props[WPAppAnalyticsKeySubscriptionCount] = subscriptionCount
        WPAnalytics.track(event, properties: props)
    }

    /// Track a Reader stat
    ///
    /// This will call each registered tracker and fire the given event
    /// - Parameter event: a `String` that represents the Reader event name
    /// - Parameter properties: a `Hash` that represents the properties
    ///
    static func trackReader(_ stat: WPAnalyticsStat, properties: [AnyHashable: Any] = [:]) {
        var props = properties
        props[WPAppAnalyticsKeySubscriptionCount] = subscriptionCount
        WPAnalytics.track(stat, withProperties: props)
    }

    /// Track a event in Obj-C
    ///
    /// This will call each registered tracker and fire the given event
    /// - Parameter event: a `String` that represents the event name
    ///
    @objc static func trackEvent(_ event: WPAnalyticsEvent) {
        WPAnalytics.trackString(event.value)
    }

    /// Track a event in Obj-C
    ///
    /// This will call each registered tracker and fire the given event
    /// - Parameter event: a `WPAnalyticsEvent` that represents the event name
    /// - Parameter properties: a `Hash` that represents the properties
    ///
    @objc static func trackEvent(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any]) {
        track(event, properties: properties)
    }

    /// Track an event in Obj-C
    ///
    /// This will call each registered tracker and fire the given event.
    /// - Parameters:
    ///   - event: a `WPAnalyticsEvent` that represents the event name
    ///   - properties: a `Hash` that represents the properties
    ///   - blog: a `Blog` asssociated with the event
    @objc static func trackEvent(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any], blog: Blog) {
        track(event, properties: properties, blog: blog)
    }

    /// Track a Reader event in Obj-C
    ///
    /// This will call each registered tracker and fire the given event
    /// - Parameter event: a `String` that represents the Reader event name
    /// - Parameter properties: a `Hash` that represents the properties
    ///
    @objc static func trackReaderEvent(_ event: WPAnalyticsEvent, properties: [AnyHashable: Any]) {
        var props = properties
        props[WPAppAnalyticsKeySubscriptionCount] = subscriptionCount
        WPAnalytics.track(event, properties: props)
    }

    /// Track a Reader stat in Obj-C
    ///
    /// This will call each registered tracker and fire the given stat
    /// - Parameter stat: a `String` that represents the Reader stat name
    /// - Parameter properties: a `Hash` that represents the properties
    ///
    @objc static func trackReaderStat(_ stat: WPAnalyticsStat, properties: [AnyHashable: Any]) {
        var props = properties
        props[WPAppAnalyticsKeySubscriptionCount] = subscriptionCount
        WPAnalytics.track(stat, withProperties: props)
    }

    /// This will call each registered tracker and fire the given event.
    /// - Parameters:
    ///   - eventName: a `String` that represents the Block Editor event name
    ///   - properties: a `Hash` that represents the properties
    ///   - blog: a `Blog` asssociated with the event
    static func trackBlockEditorEvent(_ eventName: String, properties: [AnyHashable: Any], blog: Blog) {
        var event: WPAnalyticsEvent?
        switch eventName {
        case "editor_block_inserted": event = .gutenbergEditorBlockInserted
        case "editor_block_moved": event = .gutenbergEditorBlockMoved
        default: event = nil
        }

        if event == nil {
            print("🟡 Not Tracked: \"\(eventName)\" Block Editor event ignored as it was not found in the `trackBlockEditorEvent` conversion cases.")
        } else {
            WPAnalytics.track(event!, properties: properties, blog: blog)
        }
    }

    @objc static func trackSettingsChange(_ page: String, fieldName: String) {
        Self.trackSettingsChange(page, fieldName: fieldName, value: nil)
    }

    @objc static func trackSettingsChange(_ page: String, fieldName: String, value: Any?) {
        var properties: [AnyHashable: Any] = ["page": page, "field_name": fieldName]

        if let value = value {
            let additionalProperties: [AnyHashable: Any] = ["value": value]
            properties.merge(additionalProperties) { (_, new) in new }
        }

        WPAnalytics.track(.settingsDidChange, properties: properties)
    }
}
