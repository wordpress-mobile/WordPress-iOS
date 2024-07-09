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

    // Media
    case siteMediaShareTapped

    // Settings and Prepublishing Nudges
    case editorPostPublishTap
    case editorPostPublishDismissed
    case editorPostScheduledChanged
    case editorPostPendingReviewChanged
    case editorPostTitleChanged
    case editorPostVisibilityChanged
    case editorPostTagsChanged
    case editorPostAuthorChanged
    case editorPostPublishNowTapped
    case editorPostSaveDraftTapped
    case editorPostCategoryChanged
    case editorPostStatusChanged
    case editorPostFormatChanged
    case editorPostFeaturedImageChanged
    case editorPostStickyChanged
    case editorPostLocationChanged
    case editorPostSlugChanged
    case editorPostExcerptChanged
    case editorPostSiteChanged
    case editorPostLegacyMoreMenuShown

    // Resolve post version conflict
    case resolveConflictScreenShown
    case resolveConflictSaveTapped
    case resolveConflictCancelTapped

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
    case readerAnnouncementDismissed
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
    case readerArticleTextHighlighted
    case readerArticleTextCopied
    case readerCommentTextHighlighted
    case readerCommentTextCopied

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
    case domainsDashboardGetDomainTapped
    case domainsDashboardGetPlanTapped
    case domainsSearchSelectDomainTapped
    case domainsRegistrationFormViewed
    case domainsRegistrationFormSubmitted
    case domainsPurchaseWebviewViewed
    case domainsPurchaseSucceeded
    case domainTransferShown
    case domainTransferMoreTapped
    case domainTransferButtonTapped

    // Domain Management
    case meDomainsTapped
    case allDomainsDomainDetailsWebViewShown
    case domainsDashboardAllDomainsTapped
    case domainsDashboardDomainsSearchShown
    case domainsListShown
    case allDomainsFindDomainTapped
    case addDomainTapped
    case domainsSearchTransferDomainTapped
    case domainsSearchRowSelected
    case siteSwitcherSiteSelected
    case purchaseDomainScreenShown
    case purchaseDomainGetDomainTapped
    case purchaseDomainChooseSiteTapped
    case purchaseDomainCompleted
    case myDomainsSearchDomainTapped

    // My Site
    case mySitePullToRefresh

    // My Site: No sites view displayed
    case mySiteNoSitesViewDisplayed
    case mySiteNoSitesViewActionTapped
    case mySiteNoSitesViewHidden

    // My Site: Header Actions
    case mySiteHeaderMoreTapped
    case mySiteHeaderAddSiteTapped
    case mySiteHeaderShareSiteTapped
    case mySiteHeaderPersonalizeHomeTapped

    // Site Switcher
    case mySiteSiteSwitcherTapped
    case siteSwitcherDisplayed
    case siteSwitcherDismissed
    case siteSwitcherToggleEditTapped
    case siteSwitcherAddSiteTapped
    case siteSwitcherSearchPerformed
    case siteSwitcherToggleBlogVisible
    case siteSwitcherToggledPinTapped
    case siteSwitcherPinUpdated
    case siteSwitcherSiteTapped

    // Post List
    case postListItemSelected
    case postListShareAction
    case postListBlazeAction
    case postListCommentsAction
    case postListSetAsPostsPageAction
    case postListSetHomePageAction
    case postListSetAsRegularPageAction
    case postListSettingsAction
    case postListDeleteAction
    case postListRetryAction

    // Page List
    case pageListEditHomepageTapped
    case pageListEditHomepageInfoTapped

    // Posts (Techincal)
    case postRepositoryPostCreated
    case postRepositoryPostUpdated
    case postRepositoryPatchStarted
    case postRepositoryConflictEncountered

    // Reader: Filter Sheet
    case readerFilterSheetDisplayed
    case readerFilterSheetDismissed
    case readerFilterSheetItemSelected
    case readerFilterSheetCleared

    // Reader: Manage
    case readerManageViewDisplayed
    case readerManageViewDismissed

    // Reader: Navigation menu dropdown
    case readerDropdownOpened
    case readerDropdownItemTapped

    // Reader: Tags Feed
    case readerTagsFeedShown
    case readerTagsFeedMoreFromTagTapped
    case readerTagsFeedHeaderTapped

    // Reader: Floating Button Experiment
    case readerFloatingButtonShown
    case readerCreateSheetAnswerPromptTapped
    case readerCreateSheetPromptHelpTapped

    // App Settings
    case settingsDidChange

    // Account Close
    case accountCloseTapped
    case accountCloseCompleted

    // App Settings
    case appSettingsOptimizeImagesChanged
    case appSettingsMaxImageSizeChanged
    case appSettingsImageQualityChanged
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
    case notificationMenuTapped
    case notificationsInlineActionTapped

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

    // Bloganuary Nudges
    case bloganuaryNudgeCardLearnMoreTapped
    case bloganuaryNudgeModalShown
    case bloganuaryNudgeModalDismissed
    case bloganuaryNudgeModalActionTapped

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

    // Chatbot Support
    case supportChatbotStarted
    case supportChatbotWebViewError
    case supportChatbotTicketSuccess
    case supportChatbotTicketFailure
    case supportChatbotEnded

    // Jetpack plugin connection to user's WP.com account
    case jetpackPluginConnectUserAccountStarted
    case jetpackPluginConnectUserAccountFailed
    case jetpackPluginConnectUserAccountCompleted

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

    // SoTW 2023 Nudge
    case sotw2023NudgePostEventCardShown
    case sotw2023NudgePostEventCardCTATapped
    case sotw2023NudgePostEventCardHideTapped

    // Voice to Content (aka "Post from Audio")
    case voiceToContentSheetShown
    case voiceToContentButtonStartRecordingTapped
    case voiceToContentButtonDoneTapped
    case voiceToContentButtonUpgradeTapped
    case voiceToContentButtonCloseTapped
    case voiceToContentRecordingLimitReached

    // Widgets
    case widgetsLoadedOnApplicationOpened

    // Assertions & Errors
    case assertionFailure
    case postCoordinatorErrorEncountered

    // Site monitoring
    case siteMonitoringTabShown
    case siteMonitoringEntryDetailsShown

    // Reading preferences
    case readingPreferencesOpened
    case readingPreferencesFeedbackTapped
    case readingPreferencesItemTapped
    case readingPreferencesSaved
    case readingPreferencesClosed

    // Stats Subscribers
    case statsSubscribersViewMoreTapped
    case statsEmailsViewMoreTapped
    case statsSubscribersChartTapped

    // In-App Updates
    case inAppUpdateShown
    case inAppUpdateDismissed
    case inAppUpdateAccepted

    // REST API
    case unableToPerformURLAutodiscovery

    /// A String that represents the event
    var value: String {
        return switch self {

        case .createSheetShown: "create_sheet_shown"
        case .createSheetActionTapped: "create_sheet_action_tapped"
        case .createAnnouncementModalShown: "create_announcement_modal_shown"

        // Media Editor
        case .mediaEditorShown: "media_editor_shown"
        case .mediaEditorUsed: "media_editor_used"
        case .editorCreatedPage: "editor_page_created"

        // Tenor
        case .tenorAccessed: "tenor_accessed"
        case .tenorSearched: "tenor_searched"
        case .tenorUploaded: "tenor_uploaded"
        case .mediaLibraryAddedPhotoViaTenor: "media_library_photo_added"
        case .editorAddedPhotoViaTenor: "editor_photo_added"

        // Media
        case .siteMediaShareTapped: "site_media_shared_tapped"
        // Editor
        case .editorPostPublishTap: "editor_post_publish_tapped"
        case .editorPostPublishDismissed: "editor_post_publish_dismissed"
        case .editorPostScheduledChanged: "editor_post_scheduled_changed"
        case .editorPostPendingReviewChanged: "editor_post_pending_review_changed"
        case .editorPostTitleChanged: "editor_post_title_changed"
        case .editorPostVisibilityChanged: "editor_post_visibility_changed"
        case .editorPostTagsChanged: "editor_post_tags_changed"
        case .editorPostPublishNowTapped: "editor_post_publish_now_tapped"
        case .editorPostSaveDraftTapped: "editor_post_save_draft_tapped"
        case .editorPostCategoryChanged: "editor_post_category_changed"
        case .editorPostStatusChanged: "editor_post_status_changed"
        case .editorPostFormatChanged: "editor_post_format_changed"
        case .editorPostFeaturedImageChanged: "editor_post_featured_image_changed"
        case .editorPostStickyChanged: "editor_post_sticky_changed"
        case .editorPostAuthorChanged: "editor_post_author_changed"
        case .editorPostLocationChanged: "editor_post_location_changed"
        case .editorPostSlugChanged: "editor_post_slug_changed"
        case .editorPostExcerptChanged: "editor_post_excerpt_changed"
        case .editorPostSiteChanged: "editor_post_site_changed"
        case .editorPostLegacyMoreMenuShown: "editor_post_legacy_more_menu_shown"
        case .resolveConflictScreenShown: "resolve_conflict_screen_shown"
        case .resolveConflictSaveTapped: "resolve_conflict_save_tapped"
        case .resolveConflictCancelTapped: "resolve_conflict_cancel_tapped"
        case .appSettingsAppearanceChanged: "app_settings_appearance_changed"
        case .gutenbergUnsupportedBlockWebViewShown: "gutenberg_unsupported_block_webview_shown"
        case .gutenbergUnsupportedBlockWebViewClosed: "gutenberg_unsupported_block_webview_closed"
        case .gutenbergSuggestionSessionFinished: "suggestion_session_finished"
        case .gutenbergEditorSettingsFetched: "editor_settings_fetched"
        case .gutenbergEditorHelpShown: "editor_help_shown"
        case .gutenbergEditorBlockInserted: "editor_block_inserted"
        case .gutenbergEditorBlockMoved: "editor_block_moved"
        
        // Notifications permissions
        case .pushNotificationsPrimerSeen: "notifications_primer_seen"
        case .pushNotificationsPrimerAllowTapped: "notifications_primer_allow_tapped"
        case .pushNotificationsPrimerNoTapped: "notifications_primer_no_tapped"
        case .secondNotificationsAlertSeen: "notifications_second_alert_seen"
        case .secondNotificationsAlertAllowTapped: "notifications_second_alert_allow_tapped"
        case .secondNotificationsAlertNoTapped: "notifications_second_alert_no_tapped"
        
        // Reader
        case .selectInterestsShown: "select_interests_shown"
        case .selectInterestsPicked: "select_interests_picked"
        case .readerDiscoverShown: "reader_discover_shown"
        case .readerFollowingShown: "reader_following_shown"
        case .readerLikedShown: "reader_liked_shown"
        case .readerA8CShown: "reader_a8c_shown"
        case .readerP2Shown: "reader_p2_shown"
        case .readerSavedListShown: "reader_saved_list_shown"
        case .readerBlogPreviewed: "reader_blog_previewed"
        case .readerDiscoverPaginated: "reader_discover_paginated"
        case .readerPostCardTapped: "reader_post_card_tapped"
        case .readerPullToRefresh: "reader_pull_to_refresh"
        case .readerDiscoverTopicTapped: "reader_discover_topic_tapped"
        case .readerAnnouncementDismissed: "reader_announcement_card_dismissed"
        case .postCardMoreTapped: "post_card_more_tapped"
        case .followedBlogNotificationsReaderMenuOff: "followed_blog_notifications_reader_menu_off"
        case .followedBlogNotificationsReaderMenuOn: "followed_blog_notifications_reader_menu_on"
        case .readerArticleVisited: "reader_article_visited"
        case .itemSharedReader: "item_shared_reader"
        case .readerBlogBlocked: "reader_blog_blocked"
        case .readerAuthorBlocked: "reader_author_blocked"
        case .readerChipsMoreToggled: "reader_chips_more_toggled"
        case .readerToggleFollowConversation: "reader_toggle_follow_conversation"
        case .readerToggleCommentNotifications: "reader_toggle_comment_notifications"
        case .readerMoreToggleFollowConversation: "reader_more_toggle_follow_conversation"
        case .readerPostReported: "reader_post_reported"
        case .readerPostAuthorReported: "reader_post_author_reported"
        case .readerArticleDetailMoreTapped: "reader_article_detail_more_tapped"
        case .readerSharedItem: "reader_shared_item"
        case .readerSuggestedSiteVisited: "reader_suggested_site_visited"
        case .readerSuggestedSiteToggleFollow: "reader_suggested_site_toggle_follow"
        case .readerDiscoverContentPresented: "reader_discover_content_presented"
        case .readerPostMarkSeen: "reader_mark_as_seen"
        case .readerPostMarkUnseen: "reader_mark_as_unseen"
        case .readerRelatedPostFromOtherSiteClicked: "reader_related_post_from_other_site_clicked"
        case .readerRelatedPostFromSameSiteClicked: "reader_related_post_from_same_site_clicked"
        case .readerSearchHistoryCleared: "reader_search_history_cleared"
        case .readerArticleLinkTapped: "reader_article_link_tapped"
        case .readerArticleImageTapped: "reader_article_image_tapped"
        case .readerFollowConversationTooltipTapped: "reader_follow_conversation_tooltip_tapped"
        case .readerFollowConversationAnchorTapped: "reader_follow_conversation_anchor_tapped"
        case .readerArticleTextHighlighted: "reader_article_text_highlighted"
        case .readerArticleTextCopied: "reader_article_text_copied"
        case .readerCommentTextHighlighted: "reader_comment_text_highlighted"
        case .readerCommentTextCopied: "reader_comment_text_copied"

        // Stats - Empty Stats nudges
        case .statsPublicizeNudgeShown: "stats_publicize_nudge_shown"
        case .statsPublicizeNudgeTapped: "stats_publicize_nudge_tapped"
        case .statsPublicizeNudgeDismissed: "stats_publicize_nudge_dismissed"
        case .statsPublicizeNudgeCompleted: "stats_publicize_nudge_completed"
        case .statsBloggingRemindersNudgeShown: "stats_blogging_reminders_nudge_shown"
        case .statsBloggingRemindersNudgeTapped: "stats_blogging_reminders_nudge_tapped"
        case .statsBloggingRemindersNudgeDismissed: "stats_blogging_reminders_nudge_dismissed"
        case .statsBloggingRemindersNudgeCompleted: "stats_blogging_reminders_nudge_completed"
        case .statsReaderDiscoverNudgeShown: "stats_reader_discover_nudge_shown"
        case .statsReaderDiscoverNudgeTapped: "stats_reader_discover_nudge_tapped"
        case .statsReaderDiscoverNudgeDismissed: "stats_reader_discover_nudge_dismissed"
        case .statsReaderDiscoverNudgeCompleted: "stats_reader_discover_nudge_completed"
        case .statsLineChartTapped: "stats_line_chart_tapped"

        // Stats - Insights
        case .statsCustomizeInsightsShown: "stats_customize_insights_shown"
        case .statsInsightsManagementSaved: "stats_insights_management_saved"
        case .statsInsightsManagementDismissed: "stats_insights_management_dismissed"
        case .statsInsightsViewMore: "stats_insights_view_more"
        case .statsInsightsViewsVisitorsToggled: "stats_insights_views_visitors_toggled"
        case .statsInsightsViewsGrowAudienceDismissed: "stats_insights_views_grow_audience_dismissed"
        case .statsInsightsViewsGrowAudienceConfirmed: "stats_insights_views_grow_audience_confirmed"
        case .statsInsightsAnnouncementShown: "stats_insights_announcement_shown"
        case .statsInsightsAnnouncementConfirmed: "stats_insights_announcement_confirmed"
        case .statsInsightsAnnouncementDismissed: "stats_insights_announcement_dismissed"
        case .statsInsightsTotalLikesGuideTapped: "stats_insights_total_likes_guide_tapped"

        // What's New - Feature announcements
        case .featureAnnouncementShown: "feature_announcement_shown"
        case .featureAnnouncementButtonTapped: "feature_announcement_button_tapped"

        // Jetpack
        case .jetpackSettingsViewed: "jetpack_settings_viewed"
        case .jetpackManageConnectionViewed: "jetpack_manage_connection_viewed"
        case .jetpackDisconnectTapped: "jetpack_disconnect_tapped"
        case .jetpackDisconnectRequested: "jetpack_disconnect_requested"
        case .jetpackAllowlistedIpsViewed: "jetpack_allowlisted_ips_viewed"
        case .jetpackAllowlistedIpsChanged: "jetpack_allowlisted_ips_changed"
        case .activitylogFilterbarSelectType: "activitylog_filterbar_select_type"
        case .activitylogFilterbarResetType: "activitylog_filterbar_reset_type"
        case .activitylogFilterbarTypeButtonTapped: "activitylog_filterbar_type_button_tapped"
        case .activitylogFilterbarRangeButtonTapped: "activitylog_filterbar_range_button_tapped"
        case .activitylogFilterbarSelectRange: "activitylog_filterbar_select_range"
        case .activitylogFilterbarResetRange: "activitylog_filterbar_reset_range"
        case .backupListOpened: "jetpack_backup_list_opened"
        case .backupFilterbarRangeButtonTapped: "jetpack_backup_filterbar_range_button_tapped"
        case .backupFilterbarSelectRange: "jetpack_backup_filterbar_select_range"
        case .backupFilterbarResetRange: "jetpack_backup_filterbar_reset_range"
        case .restoreOpened: "jetpack_restore_opened"
        case .restoreConfirmed: "jetpack_restore_confirmed"
        case .restoreError: "jetpack_restore_error"
        case .restoreNotifiyMeButtonTapped: "jetpack_restore_notify_me_button_tapped"
        case .backupDownloadOpened: "jetpack_backup_download_opened"
        case .backupDownloadConfirmed: "jetpack_backup_download_confirmed"
        case .backupFileDownloadError: "jetpack_backup_file_download_error"
        case .backupNotifiyMeButtonTapped: "jetpack_backup_notify_me_button_tapped"
        case .backupFileDownloadTapped: "jetpack_backup_file_download_tapped"
        case .backupDownloadShareLinkTapped: "jetpack_backup_download_share_link_tapped"

        // Jetpack Scan
        case .jetpackScanAccessed: "jetpack_scan_accessed"
        case .jetpackScanHistoryAccessed: "jetpack_scan_history_accessed"
        case .jetpackScanHistoryFilter: "jetpack_scan_history_filter"
        case .jetpackScanThreatListItemTapped: "jetpack_scan_threat_list_item_tapped"
        case .jetpackScanRunTapped: "jetpack_scan_run_tapped"
        case .jetpackScanIgnoreThreatDialogOpen: "jetpack_scan_ignorethreat_dialogopen"
        case .jetpackScanThreatIgnoreTapped: "jetpack_scan_threat_ignore_tapped"
        case .jetpackScanFixThreatDialogOpen: "jetpack_scan_fixthreat_dialogopen"
        case .jetpackScanThreatFixTapped: "jetpack_scan_threat_fix_tapped"
        case .jetpackScanAllThreatsOpen: "jetpack_scan_allthreats_open"
        case .jetpackScanAllthreatsFixTapped: "jetpack_scan_allthreats_fix_tapped"
        case .jetpackScanError: "jetpack_scan_error"

        // Comments
        case .commentViewed: "comment_viewed"
        case .commentApproved: "comment_approved"
        case .commentUnApproved: "comment_unapproved"
        case .commentLiked: "comment_liked"
        case .commentUnliked: "comment_unliked"
        case .commentTrashed: "comment_trashed"
        case .commentSpammed: "comment_spammed"
        case .commentEditorOpened: "comment_editor_opened"
        case .commentEdited: "comment_edited"
        case .commentRepliedTo: "comment_replied_to"
        case .commentFilterChanged: "comment_filter_changed"
        case .commentSnackbarNext: "comment_snackbar_next"
        case .commentFullScreenEntered: "comment_fullscreen_entered"
        case .commentFullScreenExited: "comment_fullscreen_exited"

        // Invite Links
        case .inviteLinksGetStatus: "invite_links_get_status"
        case .inviteLinksGenerate: "invite_links_generate"
        case .inviteLinksShare: "invite_links_share"
        case .inviteLinksDisable: "invite_links_disable"

        // Page Layout and Site Design Picker
        case .categoryFilterSelected: "category_filter_selected"
        case .categoryFilterDeselected: "category_filter_deselected"

        // User Profile Sheet
        case .userProfileSheetShown: "user_profile_sheet_shown"
        case .userProfileSheetSiteShown: "user_profile_sheet_site_shown"

        // Blog preview by URL (that is, in a WebView)
        case .blogUrlPreviewed: "blog_url_previewed"

        // Likes list shown from Reader Post details
        case .likeListOpened: "like_list_opened"

        // When Likes list is scrolled
        case .likeListFetchedMore: "like_list_fetched_more"

        // When the recommend app button is tapped
        case .recommendAppEngaged: "recommend_app_engaged"

        // When the content fetching for the recommend app failed
        case .recommendAppContentFetchFailed: "recommend_app_content_fetch_failed"

        // Domains
        case .domainsDashboardViewed: "domains_dashboard_viewed"
        case .domainsDashboardAddDomainTapped: "domains_dashboard_add_domain_tapped"
        case .domainsDashboardGetDomainTapped: "domains_dashboard_get_domain_tapped"
        case .domainsDashboardGetPlanTapped: "domains_dashboard_get_plan_tapped"
        case .domainsSearchSelectDomainTapped: "domains_dashboard_select_domain_tapped"
        case .domainsRegistrationFormViewed: "domains_registration_form_viewed"
        case .domainsRegistrationFormSubmitted: "domains_registration_form_submitted"
        case .domainsPurchaseWebviewViewed: "domains_purchase_webview_viewed"
        case .domainsPurchaseSucceeded: "domains_purchase_domain_success"
        case .domainTransferShown: "dashboard_card_domain_transfer_shown"
        case .domainTransferMoreTapped: "dashboard_card_domain_transfer_more_menu_tapped"
        case .domainTransferButtonTapped: "dashboard_card_domain_transfer_button_tapped"

        // Domain Management
        case .meDomainsTapped: "me_all_domains_tapped"
        case .allDomainsDomainDetailsWebViewShown: "all_domains_domain_details_web_view_shown"
        case .domainsDashboardAllDomainsTapped: "domains_dashboard_all_domains_tapped"
        case .domainsDashboardDomainsSearchShown: "domains_dashboard_domains_search_shown"
        case .domainsListShown: "all_domains_list_shown"
        case .allDomainsFindDomainTapped: "domain_management_all_domains_find_domain_tapped"
        case .addDomainTapped: "all_domains_add_domain_tapped"
        case .domainsSearchTransferDomainTapped: "domains_dashboard_domains_search_transfer_domain_tapped"
        case .domainsSearchRowSelected: "domain_management_domains_search_row_selected"
        case .siteSwitcherSiteSelected: "site_switcher_site_selected"
        case .purchaseDomainScreenShown: "domain_management_purchase_domain_screen_shown"
        case .purchaseDomainGetDomainTapped: "domain_management_purchase_domain_get_domain_tapped"
        case .purchaseDomainChooseSiteTapped: "domain_management_purchase_domain_choose_site_tapped"
        case .purchaseDomainCompleted: "domain_management_purchase_domain_completed"
        case .myDomainsSearchDomainTapped: "domain_management_my_domains_search_domain_tapped"

        // My Site
        case .mySitePullToRefresh: "my_site_pull_to_refresh"

        // My Site No Sites View
        case .mySiteNoSitesViewDisplayed: "my_site_no_sites_view_displayed"
        case .mySiteNoSitesViewActionTapped: "my_site_no_sites_view_action_tapped"
        case .mySiteNoSitesViewHidden: "my_site_no_sites_view_hidden"

        // My Site Header Actions
        case .mySiteHeaderMoreTapped: "my_site_header_more_tapped"
        case .mySiteHeaderAddSiteTapped: "my_site_header_add_site_tapped"
        case .mySiteHeaderShareSiteTapped: "my_site_header_share_site_tapped"
        case .mySiteHeaderPersonalizeHomeTapped: "my_site_header_personalize_home_tapped"

        // Site Switcher
        case .mySiteSiteSwitcherTapped: "my_site_site_switcher_tapped"
        case .siteSwitcherDisplayed: "site_switcher_displayed"
        case .siteSwitcherDismissed: "site_switcher_dismissed"
        case .siteSwitcherToggleEditTapped: "site_switcher_toggle_edit_tapped"
        case .siteSwitcherAddSiteTapped: "site_switcher_add_site_tapped"
        case .siteSwitcherSearchPerformed: "site_switcher_search_performed"
        case .siteSwitcherToggleBlogVisible: "site_switcher_toggle_blog_visible"
        case .siteSwitcherToggledPinTapped: "site_switcher_toggled_pin_tapped"
        case .siteSwitcherPinUpdated: "site_switcher_pin_updated"
        case .siteSwitcherSiteTapped: "site_switcher_site_tapped"

        // Post List
        case .postListItemSelected: "post_list_item_selected"
        case .postListShareAction: "post_list_button_pressed"
        case .postListBlazeAction: "post_list_button_pressed"
        case .postListCommentsAction: "post_list_button_pressed"
        case .postListSetAsPostsPageAction: "post_list_button_pressed"
        case .postListSetHomePageAction: "post_list_button_pressed"
        case .postListSetAsRegularPageAction: "post_list_button_pressed"
        case .postListSettingsAction: "post_list_button_pressed"
        case .postListDeleteAction: "post_list_button_pressed"
        case .postListRetryAction: "post_list_button_pressed"

        // Page List
        case .pageListEditHomepageTapped: "page_list_edit_homepage_item_pressed"
        case .pageListEditHomepageInfoTapped: "page_list_edit_homepage_info_pressed"

        // Posts (Technical)
        case .postRepositoryPostCreated: "post_repository_post_created"
        case .postRepositoryPostUpdated: "post_repository_post_updated"
        case .postRepositoryPatchStarted: "post_repository_patch_started"
        case .postRepositoryConflictEncountered: "post_repository_conflict_encountered"

        // Reader: Filter Sheet
        case .readerFilterSheetDisplayed: "reader_filter_sheet_displayed"
        case .readerFilterSheetDismissed: "reader_filter_sheet_dismissed"
        case .readerFilterSheetItemSelected: "reader_filter_sheet_item_selected"
        case .readerFilterSheetCleared: "reader_filter_sheet_cleared"

        // Reader: Manage View
        case .readerManageViewDisplayed: "reader_manage_view_displayed"
        case .readerManageViewDismissed: "reader_manage_view_dismissed"

        // Reader: Navigation menu dropdown
        case .readerDropdownOpened: "reader_dropdown_menu_opened"
        case .readerDropdownItemTapped: "reader_dropdown_menu_item_tapped"

        case .readerTagsFeedShown: "reader_tags_feed_shown"
        case .readerTagsFeedMoreFromTagTapped: "reader_tags_feed_more_from_tag_tapped"
        case .readerTagsFeedHeaderTapped: "reader_tags_feed_header_tapped"

        // Reader: Floating Button Experiment
        case .readerFloatingButtonShown: "reader_create_fab_shown"
        case .readerCreateSheetAnswerPromptTapped: "my_site_create_sheet_answer_prompt_tapped"
        case .readerCreateSheetPromptHelpTapped: "my_site_create_sheet_prompt_help_tapped"

        // App Settings
        case .settingsDidChange: "settings_did_change"
        case .appSettingsClearMediaCacheTapped: "app_settings_clear_media_cache_tapped"
        case .appSettingsClearSpotlightIndexTapped: "app_settings_clear_spotlight_index_tapped"
        case .appSettingsClearSiriSuggestionsTapped: "app_settings_clear_siri_suggestions_tapped"
        case .appSettingsOpenDeviceSettingsTapped: "app_settings_open_device_settings_tapped"
        case .appSettingsOptimizeImagesChanged: "app_settings_optimize_images_changed"
        case .appSettingsMaxImageSizeChanged: "app_settings_max_image_size_changed"
        case .appSettingsImageQualityChanged: "app_settings_image_quality_changed"

        // Account Close
        case .accountCloseTapped: "account_close_tapped"
        case .accountCloseCompleted: "account_close_completed"

        // Notifications
        case .notificationsPreviousTapped: "notifications_previous_tapped"
        case .notificationsNextTapped: "notifications_next_tapped"
        case .notificationsMarkAllReadTapped: "notifications_mark_all_read_tapped"
        case .notificationMarkAsReadTapped: "notification_mark_as_read_tapped"
        case .notificationMarkAsUnreadTapped: "notification_mark_as_unread_tapped"
        case .notificationMenuTapped: "notification_menu_tapped"
        case .notificationsInlineActionTapped: "notifications_inline_action_tapped"

        // Sharing
        case .sharingButtonsEditSharingButtonsToggled: "sharing_buttons_edit_sharing_buttons_toggled"
        case .sharingButtonsEditMoreButtonToggled: "sharing_buttons_edit_more_button_toggled"
        case .sharingButtonsLabelChanged: "sharing_buttons_label_changed"

        // Comment Sharing
        case .readerArticleCommentShared: "reader_article_comment_shared"
        case .siteCommentsCommentShared: "site_comments_comment_shared"

        // People
        case .peopleFilterChanged: "people_management_filter_changed"
        case .peopleUserInvited: "people_management_user_invited"

        // Login: Epilogue
        case .loginEpilogueChooseSiteTapped: "login_epilogue_choose_site_tapped"
        case .loginEpilogueCreateNewSiteTapped: "login_epilogue_create_new_site_tapped"

        // WebKitView
        case .webKitViewDisplayed: "webkitview_displayed"
        case .webKitViewDismissed: "webkitview_dismissed"
        case .webKitViewOpenInSafariTapped: "webkitview_open_in_safari_tapped"
        case .webKitViewReloadTapped: "webkitview_reload_tapped"
        case .webKitViewShareTapped: "webkitview_share_tapped"
        case .webKitViewNavigatedBack: "webkitview_navigated_back"
        case .webKitViewNavigatedForward: "webkitview_navigated_forward"

        case .previewWebKitViewDeviceChanged: "preview_webkitview_device_changed"

        case .addSiteAlertDisplayed: "add_site_alert_displayed"

        // Change Username
        case .changeUsernameSearchPerformed: "change_username_search_performed"
        case .changeUsernameDisplayed: "change_username_displayed"
        case .changeUsernameDismissed: "change_username_dismissed"

        // My Site Dashboard
        case .dashboardCardShown: "my_site_dashboard_card_shown"
        case .dashboardCardItemTapped: "my_site_dashboard_card_item_tapped"
        case .dashboardCardContextualMenuAccessed: "my_site_dashboard_contextual_menu_accessed"
        case .dashboardCardHideTapped: "my_site_dashboard_card_hide_tapped"
        case .mySiteSiteMenuShown: "my_site_site_menu_shown"
        case .mySiteDashboardShown: "my_site_dashboard_shown"
        case .mySiteDefaultTabExperimentVariantAssigned: "my_site_default_tab_experiment_variant_assigned"

        // Quick Start
        case .quickStartStarted: "quick_start_started"
        case .quickStartTapped: "quick_start_tapped"

        // Site Intent Question
        case .enhancedSiteCreationIntentQuestionCanceled: "enhanced_site_creation_intent_question_canceled"
        case .enhancedSiteCreationIntentQuestionSkipped: "enhanced_site_creation_intent_question_skipped"
        case .enhancedSiteCreationIntentQuestionVerticalSelected: "enhanced_site_creation_intent_question_vertical_selected"
        case .enhancedSiteCreationIntentQuestionCustomVerticalSelected: "enhanced_site_creation_intent_question_custom_vertical_selected"
        case .enhancedSiteCreationIntentQuestionSearchFocused: "enhanced_site_creation_intent_question_search_focused"
        case .enhancedSiteCreationIntentQuestionViewed: "enhanced_site_creation_intent_question_viewed"
        case .enhancedSiteCreationIntentQuestionExperiment: "enhanced_site_creation_intent_question_experiment"

        // Onboarding Question Prompt
        case .onboardingQuestionsDisplayed: "onboarding_questions_displayed"
        case .onboardingQuestionsItemSelected: "onboarding_questions_item_selected"
        case .onboardingQuestionsSkipped: "onboarding_questions_skipped"

        // Onboarding Enable Notifications Prompt
        case .onboardingEnableNotificationsDisplayed: "onboarding_enable_notifications_displayed"
        case .onboardingEnableNotificationsSkipped: "onboarding_enable_notifications_skipped"
        case .onboardingEnableNotificationsEnableTapped: "onboarding_enable_notifications_enable_tapped"

        // Site Name
        case .enhancedSiteCreationSiteNameCanceled: "enhanced_site_creation_site_name_canceled"
        case .enhancedSiteCreationSiteNameSkipped: "enhanced_site_creation_site_name_skipped"
        case .enhancedSiteCreationSiteNameEntered: "enhanced_site_creation_site_name_entered"
        case .enhancedSiteCreationSiteNameViewed: "enhanced_site_creation_site_name_viewed"

        // QR Login
        case .qrLoginScannerDisplayed: "qrlogin_scanner_displayed"
        case .qrLoginScannerScannedCode: "qrlogin_scanner_scanned_code"
        case .qrLoginScannerDismissed: "qrlogin_scanned_dismissed"
        case .qrLoginVerifyCodeDisplayed: "qrlogin_verify_displayed"
        case .qrLoginVerifyCodeDismissed: "qrlogin_verify_dismissed"
        case .qrLoginVerifyCodeFailed: "qrlogin_verify_failed"
        case .qrLoginVerifyCodeApproved: "qrlogin_verify_approved"
        case .qrLoginVerifyCodeScanAgain: "qrlogin_verify_scan_again"
        case .qrLoginVerifyCodeCancelled: "qrlogin_verify_cancelled"
        case .qrLoginVerifyCodeTokenValidated: "qrlogin_verify_token_validated"
        case .qrLoginAuthenticated: "qrlogin_authenticated"
        case .qrLoginCameraPermissionDisplayed: "qrlogin_camera_permission_displayed"
        case .qrLoginCameraPermissionApproved: "qrlogin_camera_permission_approved"
        case .qrLoginCameraPermissionDenied: "qrlogin_camera_permission_denied"

        // Blogging Reminders Notification
        case .bloggingRemindersNotificationReceived: "blogging_reminders_notification_received"

        // Blogging Prompts
        case .promptsBottomSheetAnswerPrompt: "my_site_create_sheet_answer_prompt_tapped"
        case .promptsBottomSheetHelp: "my_site_create_sheet_prompt_help_tapped"
        case .promptsBottomSheetViewed: "blogging_prompts_create_sheet_card_viewed"
        case .promptsIntroductionModalViewed: "blogging_prompts_introduction_modal_viewed"
        case .promptsIntroductionModalDismissed: "blogging_prompts_introduction_modal_dismissed"
        case .promptsIntroductionModalTryItNow: "blogging_prompts_introduction_modal_try_it_now_tapped"
        case .promptsIntroductionModalRemindMe: "blogging_prompts_introduction_modal_remind_me_tapped"
        case .promptsIntroductionModalGotIt: "blogging_prompts_introduction_modal_got_it_tapped"
        case .promptsDashboardCardAnswerPrompt: "blogging_prompts_my_site_card_answer_prompt_tapped"
        case .promptsDashboardCardMenu: "blogging_prompts_my_site_card_menu_tapped"
        case .promptsDashboardCardMenuViewMore: "blogging_prompts_my_site_card_menu_view_more_prompts_tapped"
        case .promptsDashboardCardMenuSkip: "blogging_prompts_my_site_card_menu_skip_this_prompt_tapped"
        case .promptsDashboardCardMenuRemove: "blogging_prompts_my_site_card_menu_remove_from_dashboard_tapped"
        case .promptsDashboardCardMenuLearnMore: "blogging_prompts_my_site_card_menu_learn_more_tapped"
        case .promptsDashboardCardViewed: "blogging_prompts_my_site_card_viewed"
        case .promptsListViewed: "blogging_prompts_prompts_list_viewed"
        case .promptsReminderSettingsIncludeSwitch: "blogging_reminders_include_prompt_tapped"
        case .promptsReminderSettingsHelp: "blogging_reminders_include_prompt_help_tapped"
        case .promptsNotificationAnswerActionTapped: "blogging_reminders_notification_prompt_answer_tapped"
        case .promptsNotificationDismissActionTapped: "blogging_reminders_notification_prompt_dismiss_tapped"
        case .promptsNotificationTapped: "blogging_reminders_notification_prompt_tapped"
        case .promptsNotificationDismissed: "blogging_reminders_notification_prompt_dismissed"
        case .promptsOtherAnswersTapped: "blogging_prompts_my_site_card_view_answers_tapped"
        case .promptsSettingsShowPromptsTapped: "blogging_prompts_settings_show_prompts_tapped"

        // Bloganuary Nudges
        case .bloganuaryNudgeCardLearnMoreTapped: "bloganuary_nudge_my_site_card_learn_more_tapped"
        case .bloganuaryNudgeModalShown: "bloganuary_nudge_learn_more_modal_shown"
        case .bloganuaryNudgeModalDismissed: "bloganuary_nudge_learn_more_modal_dismissed"
        case .bloganuaryNudgeModalActionTapped: "bloganuary_nudge_learn_more_modal_action_tapped"

        // Jetpack branding
        case .jetpackPoweredBadgeTapped: "jetpack_powered_badge_tapped"
        case .jetpackPoweredBannerTapped: "jetpack_powered_banner_tapped"
        case .jetpackPoweredBottomSheetButtonTapped: "jetpack_powered_bottom_sheet_button_tapped"
        case .jetpackFullscreenOverlayDisplayed: "remove_feature_overlay_displayed"
        case .jetpackFullscreenOverlayLinkTapped: "remove_feature_overlay_link_tapped"
        case .jetpackFullscreenOverlayButtonTapped: "remove_feature_overlay_button_tapped"
        case .jetpackFullscreenOverlayDismissed: "remove_feature_overlay_dismissed"
        case .jetpackSiteCreationOverlayDisplayed: "remove_site_creation_overlay_displayed"
        case .jetpackSiteCreationOverlayButtonTapped: "remove_site_creation_overlay_button_tapped"
        case .jetpackSiteCreationOverlayDismissed: "remove_site_creation_overlay_dismissed"
        case .jetpackBrandingMenuCardDisplayed: "remove_feature_card_displayed"
        case .jetpackBrandingMenuCardTapped: "remove_feature_card_tapped"
        case .jetpackBrandingMenuCardLinkTapped: "remove_feature_card_link_tapped"
        case .jetpackBrandingMenuCardHidden: "remove_feature_card_hide_tapped"
        case .jetpackBrandingMenuCardRemindLater: "remove_feature_card_remind_later_tapped"
        case .jetpackBrandingMenuCardContextualMenuAccessed: "remove_feature_card_menu_accessed"
        case .jetpackFeatureIncorrectlyAccessed: "jetpack_feature_incorrectly_accessed"

        // Jetpack plugin overlay modal
        case .jetpackInstallPluginModalViewed: "jp_install_full_plugin_onboarding_modal_viewed"
        case .jetpackInstallPluginModalDismissed: "jp_install_full_plugin_onboarding_modal_dismissed"
        case .jetpackInstallPluginModalInstallTapped: "jp_install_full_plugin_onboarding_modal_install_tapped"
        case .wordPressInstallPluginModalViewed: "wp_individual_site_overlay_viewed"
        case .wordPressInstallPluginModalDismissed: "wp_individual_site_overlay_dismissed"
        case .wordPressInstallPluginModalSwitchTapped: "wp_individual_site_overlay_primary_tapped"

        // Jetpack full plugin installation for individual sites
        case .jetpackInstallFullPluginViewed: "jp_install_full_plugin_flow_viewed"
        case .jetpackInstallFullPluginInstallTapped: "jp_install_full_plugin_flow_install_tapped"
        case .jetpackInstallFullPluginCancelTapped: "jp_install_full_plugin_flow_cancel_tapped"
        case .jetpackInstallFullPluginRetryTapped: "jp_install_full_plugin_flow_retry_tapped"
        case .jetpackInstallFullPluginCompleted: "jp_install_full_plugin_flow_success"
        case .jetpackInstallFullPluginDoneTapped: "jp_install_full_plugin_flow_done_tapped"
        case .jetpackInstallFullPluginCardViewed: "jp_install_full_plugin_card_viewed"
        case .jetpackInstallFullPluginCardTapped: "jp_install_full_plugin_card_tapped"
        case .jetpackInstallFullPluginCardDismissed: "jp_install_full_plugin_card_dismissed"

        // Blaze
        case .blazeEntryPointDisplayed: "blaze_entry_point_displayed"
        case .blazeEntryPointTapped: "blaze_entry_point_tapped"
        case .blazeContextualMenuAccessed: "blaze_entry_point_menu_accessed"
        case .blazeCardHidden: "blaze_entry_point_hide_tapped"
        case .blazeCardLearnMoreTapped: "blaze_entry_point_learn_more_tapped"
        case .blazeOverlayDisplayed: "blaze_overlay_displayed"
        case .blazeOverlayButtonTapped: "blaze_overlay_button_tapped"
        case .blazeOverlayDismissed: "blaze_overlay_dismissed"
        case .blazeFlowStarted: "blaze_flow_started"
        case .blazeFlowCanceled: "blaze_flow_canceled"
        case .blazeFlowCompleted: "blaze_flow_completed"
        case .blazeFlowError: "blaze_flow_error"
        case .blazeCampaignListOpened: "blaze_campaign_list_opened"
        case .blazeCampaignDetailsOpened: "blaze_campaign_details_opened"
        case .blazeCampaignDetailsError: "blaze_campaign_details_error"
        case .blazeCampaignDetailsDismissed: "blaze_campaign_details_dismissed"

        // Moved to Jetpack static screen
        case .removeStaticPosterDisplayed: "remove_static_poster_displayed"
        case .removeStaticPosterButtonTapped: "remove_static_poster_get_jetpack_tapped"
        case .removeStaticPosterLinkTapped: "remove_static_poster_link_tapped"

        // Help & Support
        case .supportOpenMobileForumTapped: "support_open_mobile_forum_tapped"
        case .supportMigrationFAQButtonTapped: "support_migration_faq_tapped"
        case .supportMigrationFAQCardViewed: "support_migration_faq_viewed"

        // Chatbot Support
        case .supportChatbotStarted: "support_chatbot_started"
        case .supportChatbotWebViewError: "support_chatbot_webview_error"
        case .supportChatbotTicketSuccess: "support_chatbot_ticket_success"
        case .supportChatbotTicketFailure: "support_chatbot_ticket_failure"
        case .supportChatbotEnded: "support_chatbot_ended"

        // Jetpack plugin connection to user's WP.com account
        case .jetpackPluginConnectUserAccountStarted: "jetpack_plugin_connect_user_account_started"
        case .jetpackPluginConnectUserAccountFailed: "jetpack_plugin_connect_user_account_failed"
        case .jetpackPluginConnectUserAccountCompleted: "jetpack_plugin_connect_user_account_completed"

        // Jetpack Social - Twitter Deprecation Notice
        case .jetpackSocialTwitterNoticeLinkTapped: "twitter_notice_link_tapped"

        case .jetpackSocialConnectionToggled: "jetpack_social_auto_sharing_connection_toggled"
        case .jetpackSocialShareLimitDisplayed: "jetpack_social_share_limit_displayed"
        case .jetpackSocialShareLimitDismissed: "jetpack_social_share_limit_dismissed"
        case .jetpackSocialUpgradeLinkTapped: "jetpack_social_upgrade_link_tapped"
        case .jetpackSocialNoConnectionCardDisplayed: "jetpack_social_add_connection_cta_displayed"
        case .jetpackSocialNoConnectionCTATapped: "jetpack_social_add_connection_tapped"
        case .jetpackSocialNoConnectionCardDismissed: "jetpack_social_add_connection_dismissed"

        // Free to Paid Plans Dashboard Card
        case .freeToPaidPlansDashboardCardShown: "free_to_paid_plan_dashboard_card_shown"
        case .freeToPaidPlansDashboardCardHidden: "free_to_paid_plan_dashboard_card_hidden"
        case .freeToPaidPlansDashboardCardTapped: "free_to_paid_plan_dashboard_card_tapped"
        case .freeToPaidPlansDashboardCardMenuTapped: "free_to_paid_plan_dashboard_card_menu_tapped"

        // SoTW 2023 Nudge
        case .sotw2023NudgePostEventCardShown: "sotw_2023_nudge_post_event_card_shown"
        case .sotw2023NudgePostEventCardCTATapped: "sotw_2023_nudge_post_event_card_cta_tapped"
        case .sotw2023NudgePostEventCardHideTapped: "sotw_2023_nudge_post_event_card_hide_tapped"

        // Voice to Content (aka "Post from Audio")
        case .voiceToContentSheetShown: "voice_to_content_sheet_shown"
        case .voiceToContentButtonStartRecordingTapped: "voice_to_content_button_start_recording_tapped"
        case .voiceToContentButtonDoneTapped: "voice_to_content_button_done_tapped"
        case .voiceToContentButtonUpgradeTapped: "voice_to_content_button_upgrade_tapped"
        case .voiceToContentButtonCloseTapped: "voice_to_content_button_close_tapped"
        case .voiceToContentRecordingLimitReached: "voice_to_content_recording_limit_reached"

        // Widgets
        case .widgetsLoadedOnApplicationOpened: "widgets_loaded_on_application_opened"

        // Assertions & Errors
        case .assertionFailure: "assertion_failure"
        case .postCoordinatorErrorEncountered: "post_coordinator_error_encountered"

        // Site Monitoring
        case .siteMonitoringTabShown: "site_monitoring_tab_shown"
        case .siteMonitoringEntryDetailsShown: "site_monitoring_entry_details_shown"

        // Reading Preferences
        case .readingPreferencesOpened: "reader_reading_preferences_opened"
        case .readingPreferencesFeedbackTapped: "reader_reading_preferences_feedback_tapped"
        case .readingPreferencesItemTapped: "reader_reading_preferences_item_tapped"
        case .readingPreferencesSaved: "reader_reading_preferences_saved"
        case .readingPreferencesClosed: "reader_reading_preferences_closed"

        // Stats Subscribers
        case .statsSubscribersViewMoreTapped: "stats_subscribers_view_more_tapped"
        case .statsEmailsViewMoreTapped: "stats_emails_view_more_tapped"
        case .statsSubscribersChartTapped: "stats_subscribers_chart_tapped"

        // In-App Updates
        case .inAppUpdateShown: "in_app_update_shown"
        case .inAppUpdateDismissed: "in_app_update_dismissed"
        case .inAppUpdateAccepted: "in_app_update_accepted"

        // REST API
        case .unableToPerformURLAutodiscovery: "unable_to_perform_url_autodiscovery"

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
        case .postListBlazeAction:
            return ["button": "blaze"]
        case .postListCommentsAction:
            return ["button": "comments"]
        case .postListSetAsPostsPageAction:
            return ["button": "set_posts_page"]
        case .postListSetHomePageAction:
            return ["button": "set_homepage"]
        case .postListSetAsRegularPageAction:
            return ["button": "set_regular_page"]
        case .postListSettingsAction:
            return ["button": "settings"]
        case .postListDeleteAction:
            return ["button": "delete"]
        case .postListRetryAction:
            return ["button": "retry"]
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
