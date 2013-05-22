//
//  WPMobileStats.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 5/14/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "WPMobileStats.h"
#import <Mixpanel/Mixpanel.h>
#import "WordPressComApiCredentials.h"
#import "WordPressComApi.h"

// General
NSString *const StatsAppOpened = @"Application Opened";

// Top Level Menu Items
NSString *const StatsEventSidebarClickedReader = @"Sidebar - Clicked Reader";
NSString *const StatsEventSidebarClickedNotifications = @"Sidebar - Clicked Notifications";
NSString *const StatsEventSidebarSiteClickedPosts = @"Sidebar - Site - Clicked Posts";
NSString *const StatsEventSidebarSiteClickedPages = @"Sidebar - Site - Clicked Pages";
NSString *const StatsEventSidebarSiteClickedComments = @"Sidebar - Site - Clicked Comments";
NSString *const StatsEventSidebarSiteClickedStats = @"Sidebar - Site - Clicked Stats";
NSString *const StatsEventSidebarSiteClickedViewSite = @"Sidebar - Site - Clicked View Site";
NSString *const StatsEventSidebarSiteClickedViewAdmin = @"Sidebar - Site - Clicked View Admin";
NSString *const StatsEventSidebarClickedSettings = @"Sidebar - Clicked Settings";
NSString *const StatsEventSidebarClickedQuickPhoto = @"Sidebar - Clicked Quick Photo";

// Reader
NSString *const StatsEventReaderOpened = @"Reader - Opened";
NSString *const StatsEventReaderClickedShowTopicSelector = @"Reader - Show Topic Selector";
NSString *const StatsEventReaderSelectedFreshlyPressedTopic = @"Reader - Selected Freshly Pressed Topic";
NSString *const StatsEventReaderSelectedTopic = @"Reader - Selected Topic";
NSString *const StatsEventReaderClickedArticleDetails = @"Reader - Clicked Article Details";

// Reader Detail
NSString *const StatsEventReaderDetailClickedNext = @"Reader Detail - Clicked Next Article";
NSString *const StatsEventReaderDetailClickedPrevious = @"Reader Detail - Clicked Previous Article";

// Web View Sharing
NSString *const StatsEventWebviewClickedShowLinkOptions = @"Clicked Show Link Options";
NSString *const StatsEventWebviewSharedArticleViaEmail = @"Shared Article via Email";
NSString *const StatsEventWebviewSharedArticleViaSMS = @"Shared Article via SMS";
NSString *const StatsEventWebviewSharedArticleViaTwitter = @"Shared Article via Twitter";
NSString *const StatsEventWebviewSharedArticleViaFacebook = @"Shared Article via Facebook";
NSString *const StatsEventWebviewSharedArticleViaWeibo = @"Shared Article via Weibo";
NSString *const StatsEventWebviewCopiedArticleDetails = @"Copied Article Details";
NSString *const StatsEventWebviewOpenedArticleInSafari = @"Opened Article in Safari";
NSString *const StatsEventWebviewSentArticleToPocket = @"Sent Article to Pocket";
NSString *const StatsEventWebviewSentArticleToInstapaper = @"Sent Article to Instapaper";

// Notifications
NSString *const StatsEventNotificationsOpened = @"Notifications - Opened";
NSString *const StatsEventNotificationsOpenedNotificationDetails = @"Notifications - Opened Notification Details";

// Notifications Detail
NSString *const StatsEventNotificationsDetailClickedReplyButton = @"Notifications Detail - Clicked Reply Button";
NSString *const StatsEventNotificationsDetailRepliedToComment = @"Notifications Detail - Replied to Comment";
NSString *const StatsEventNotificationsDetailApproveComment = @"Notifications Detail - Approve Comment";
NSString *const StatsEventNotificationsDetailUnapproveComment = @"Notifications Detail - Unapprove Comment";
NSString *const StatsEventNotificationsDetailTrashComment = @"Notifications Detail - Trash Comment";
NSString *const StatsEventNotificationsDetailUntrashComment = @"Notifications Detail - Untrash Comment";
NSString *const StatsEventNotificationsDetailFlagCommentAsSpam = @"Notifications Detail - Flag Comment as Spam";
NSString *const StatsEventNotificationsDetailUnflagCommentAsSpam = @"Notifications Detail - Unflagged Comment as Spam";
NSString *const StatsEventNotificationsDetailFollowBlog = @"Notifications Detail - Followed Blog";
NSString *const StatsEventNotificationsDetailUnfollowBlog = @"Notifications Detail - Unfollowed Blog";

// Posts
NSString *const StatsEventPostsOpened = @"Posts - Opened";
NSString *const StatsEventPostsClickedPostDetail = @"Posts - Clicked Post Detail";
NSString *const StatsEventPostsClickedNewPost = @"Posts - Clicked New Post";

// Post Detail
NSString *const StatsEventPostDetailClickedSettings = @"Clicked Settings";
NSString *const StatsEventPostDetailClickedEdit = @"Clicked Edit";
NSString *const StatsEventPostDetailClickedMedia = @"Clicked Media";
NSString *const StatsEventPostDetailClickedPreview = @"Clicked Preview";
NSString *const StatsEventPostDetailClickedAddVideo = @"Clicked Add Video";
NSString *const StatsEventPostDetailClickedAddPhoto = @"Clicked Add Photo";
NSString *const StatsEventPostDetailClickedShowCategories = @"Clicked Show Categories";
NSString *const StatsEventPostDetailClickedKeyboardToolbarBoldButton = @"Clicked Keyboard Toolbar Bold Button";
NSString *const StatsEventPostDetailClickedKeyboardToolbarItalicButton = @"Clicked Keyboard Toolbar Italics Button";
NSString *const StatsEventPostDetailClickedKeyboardToolbarLinkButton = @"Clicked Keyboard Toolbar Link Button";
NSString *const StatsEventPostDetailClickedKeyboardToolbarBlockquoteButton = @"Clicked Keyboard Toolbar Blockquote Button";
NSString *const StatsEventPostDetailClickedKeyboardToolbarDelButton = @"Clicked Keyboard Toolbar Del Button";
NSString *const StatsEventPostDetailClickedKeyboardToolbarOrderedListButton = @"Clicked Keyboard Toolbar Ordered List Button";
NSString *const StatsEventPostDetailClickedKeyboardToolbarUnorderedListButton = @"Clicked Keyboard Toolbar Unordered List Button";
NSString *const StatsEventPostDetailClickedKeyboardToolbarListItemButton = @"Clicked Keyboard Toolbar List Item Button";
NSString *const StatsEventPostDetailClickedKeyboardToolbarCodeButton = @"Clicked Keyboard Toolbar Code Button";
NSString *const StatsEventPostDetailClickedKeyboardToolbarMoreButton = @"Clicked Keyboard Toolbar More Button";
NSString *const StatsEventPostDetailAddedPhoto = @"Added Photo";
NSString *const StatsEventPostDetailRemovedPhoto = @"Removed Photo";
NSString *const StatsEventPostDetailClickedSchedule = @"Clicked Schedule Button";
NSString *const StatsEventPostDetailClickedSave = @"Clicked Save Button";
NSString *const StatsEventPostDetailClickedUpdate = @"Clicked Update Button";
NSString *const StatsEventPostDetailClickedPublish = @"Clicked Publish Button";

// Post Detail - Settings
NSString *const StatsEventPostDetailSettingsClickedStatus = @"Settings - Clicked Status";
NSString *const StatsEventPostDetailSettingsClickedVisibility = @"Settings - Clicked Visibility";
NSString *const StatsEventPostDetailSettingsClickedScheduleFor = @"Settings - Clicked Schedule For";
NSString *const StatsEventPostDetailSettingsClickedPostFormat = @"Settings - Clicked Post Format";
NSString *const StatsEventPostDetailSettingsClickedSetFeaturedImage = @"Settings - Clicked Set Featured Image";
NSString *const StatsEventPostDetailSettingsClickedRemoveFeaturedImage = @"Settings - Clicked Remove Featured Image";
NSString *const StatsEventPostDetailSettingsClickedAddLocation = @"Settings - Clicked Add Location";
NSString *const StatsEventPostDetailSettingsClickedUpdateLocation = @"Settings - Clicked Update Location";
NSString *const StatsEventPostDetailSettingsClickedRemoveLocation = @"Settings - Clicked Remove Location";

// Pages
NSString *const StatsEventPagesOpened = @"Pages - Opened";
NSString *const StatsEventPagesClickedPageDetail = @"Pages - Clicked Page Detail";
NSString *const StatsEventPagesClickedNewPage = @"Pages - Clicked New Page";

// Comments
NSString *const StatsEventCommentsApproved = @"Comments - Approved Comments";
NSString *const StatsEventCommentsUnapproved = @"Comments - Unapproved Comments";
NSString *const StatsEventCommentsFlagAsSpam = @"Comments - Flagged Comments as Spam";
NSString *const StatsEventCommentsDeleted = @"Comments - Deleted Comments";
NSString *const StatsEventCommentsReplied = @"Comments - Clicked Reply to Comment";
NSString *const StatsEventCommentsViewCommentDetails = @"Comments - View Comment Details";

// Comment Detail
NSString *const StatsEventCommentDetailApprove = @"Comment Detail - Approve Comment";
NSString *const StatsEventCommentDetailUnapprove = @"Comment Detail - Unapprove Comment";
NSString *const StatsEventCommentDetailDelete = @"Comment Detail - Delete Comment";
NSString *const StatsEventCommentDetailFlagAsSpam = @"Comment Detail - Flag Comment as Spam";
NSString *const StatsEventCommentDetailEditComment = @"Comment Detail - Edit Comment";
NSString *const StatsEventCommentDetailClickedReplyToComment = @"Comment Detail - Clicked Reply to Comment";
NSString *const StatsEventCommentDetailRepliedToComment = @"Comment Detail - Replied to Comment";
NSString *const StatsEventCommentDetailClickedShowPreviousComment = @"Comment Detail - Clicked Show Previous Comment";
NSString *const StatsEventCommentDetailClickedShowNextComment = @"Comment Detail - Clicked Show Next Comment";

// Settings
NSString *const StatsEventSettingsRemovedBlog = @"Settings - Remove Blog";
NSString *const StatsEventSettingsClickedEditBlog = @"Settings - Clicked Edit Blog";
NSString *const StatsEventSettingsClickedAddBlog = @"Settings - Clicked Add Blog";
NSString *const StatsEventSettingsSignedOutOfDotCom = @"Settings - Signed Out of Wordpress.com";
NSString *const StatsEventSettingsClickedSignIntoDotCom = @"Settings - Clicked Sign Into Wordpress.com";
NSString *const StatsEventSettingsClickedSignOutOfDotCom = @"Settings - Clicked Sign Out of Wordpress.com";
NSString *const StatsEventSettingsMediaClickedImageResize = @"Settings - Media - Clicked Image Resize";
NSString *const StatsEventSettingsMediaClickedVideoQuality = @"Settings - Media - Clicked Video Quality";
NSString *const StatsEventSettingsMediaClickedVideoContent = @"Settings - Media - Clicked Video Content";
NSString *const StatsEventSettingsClickedManageNotifications = @"Settings - Clicked Manage Notifications";
NSString *const StatsEventSettingsEnabledSounds = @"Settings - Enabled Sounds";
NSString *const StatsEventSettingsDisabledSounds = @"Settings - Disabled Sounds";
NSString *const StatsEventSettingsClickedAbout = @"Settings - Clicked About";

// Manage Notifications
NSString *const StatsEventManageNotificationsTurnOn = @"Manage Notifications - Turn On Notifications";
NSString *const StatsEventManageNotificationsTurnOff = @"Manage Notifications - Turn Off Notifications";
NSString *const StatsEventManageNotificationsTurnOffForOneHour = @"Manage Notifications - Turn Off Notifications For One Hour";
NSString *const StatsEventManageNotificationsTurnOffUntil8AM = @"Manage Notifications - Turn Off Notifications Until 8AM";
NSString *const StatsEventManageNotificationsEnabledFollowNotifications = @"Manage Notifications - Enable Follow Notifications";
NSString *const StatsEventManageNotificationsDisabledFollowNotifications = @"Manage Notifications - Disabled Follow Notifications";
NSString *const StatsEventManageNotificationsEnabledAchievementsNotifications = @"Manage Notifications - Enable Achievements Notifications";
NSString *const StatsEventManageNotificationsDisabledAchievementsNotifications = @"Manage Notifications - Disabled Achievements Notifications";
NSString *const StatsEventManageNotificationsEnabledCommentNotifications = @"Manage Notifications - Enable Comment Notifications";
NSString *const StatsEventManageNotificationsDisabledCommentNotifications = @"Manage Notifications - Disabled Comment Notifications";
NSString *const StatsEventManageNotificationsEnabledReblogNotifications = @"Manage Notifications - Enable Reblog Notifications";
NSString *const StatsEventManageNotificationsDisabledReblogNotifications = @"Manage Notifications - Disabled Reblog Notifications";
NSString *const StatsEventManageNotificationsEnabledLikeNotifications = @"Manage Notifications - Enable Like Notifications";
NSString *const StatsEventManageNotificationsDisabledLikeNotifications = @"Manage Notifications - Disabled Like Notifications";
NSString *const StatsEventManageNotificationsEnabledBlogNotifications = @"Manage Notifications - Enable Blog Notifications";
NSString *const StatsEventManageNotificationsDisabledBlogNotifications = @"Manage Notifications - Disabled Blog Notifications";

// Quick Photo
NSString *const StatsEventQuickPhotoOpened = @"Quick Photo - Opened";
NSString *const StatsEventQuickPhotoPosted = @"Quick Photo - Posted";

// Welcome View Controller
NSString *const StatsEventWelcomeViewControllerClickedAddSelfHostedBlog = @"Welcome View Controller - Add Self Hosted Blog";
NSString *const StatsEventWelcomeViewControllerClickedAddWordpressDotComBlog = @"Welcome View Controller - Add Wordpress.com Blog";
NSString *const StatsEventWelcomeViewControllerClickedCreateWordpressDotComBlog = @"Welcome View Controller - Create Wordpress.com Blog";

// NUX First Walkthrough 
NSString *const StatsEventNUXFirstWalkthroughOpened = @"NUX - First Walkthrough - Opened";
NSString *const StatsEventNUXFirstWalkthroughViewedPage2 = @"NUX - First Walkthrough - Viewed Page 2";
NSString *const StatsEventNUXFirstWalkthroughViewedPage3 = @"NUX - First Walkthrough - Viewed Page 3";
NSString *const StatsEventNUXFirstWalkthroughClickedSkipToCreateAccount = @"NUX - First Walkthrough - Skipped to Create Account";
NSString *const StatsEventNUXFirstWalkthroughClickedSkipToSignIn = @"NUX - First Walkthrough - Skipped to Sign In";
NSString *const StatsEventNUXFirstWalkthroughClickedInfo = @"NUX - First Walkthrough - Clicked Info";
NSString *const StatsEventNUXFirstWalkthroughClickedCreateAccount = @"NUX - First Walkthrough - Clicked Create Account";
NSString *const StatsEventNUXFirstWalkthroughSignedInWithoutUrl = @"NUX - First Walkthrough - Signed In Without URL";
NSString *const StatsEventNUXFirstWalkthroughSignedInWithUrl = @"NUX - First Walkthrough - Signed In With URL";
NSString *const StatsEventNUXFirstWalkthroughSignedInForDotCom = @"NUX - First Walkthrough - Signed In For WordPress.com";
NSString *const StatsEventNUXFirstWalkthroughSignedInForSelfHosted = @"NUX - First Walkthrough - Signed In For Self Hosted Site";
NSString *const StatsEventNUXFirstWalkthroughClickedNeededHelpOnError = @"NUX - First Walkthrough - Clicked Needed Help on Error";

// NUX Create Account
NSString *const StatsEventNUXCreateAccountOpened = @"NUX - Create Account - Opened";
NSString *const StatsEventNUXCreateAccountClickedCancel = @"NUX - Create Account - Clicked Cancel";
NSString *const StatsEventNUXCreateAccountClickedHelp = @"NUX - Create Account - Clicked Help";
NSString *const StatsEventNUXCreateAccountClickedPage1Next = @"NUX - Create Account - Clicked Page 1 Next";
NSString *const StatsEventNUXCreateAccountClickedPage2Next = @"NUX - Create Account - Clicked Page 2 Next";
NSString *const StatsEventNUXCreateAccountClickedPage2Previous = @"NUX - Create Account - Clicked Page 2 Previous";
NSString *const StatsEventNUXCreateAccountCreatedAccount = @"NUX - Create Account - Created Account";
NSString *const StatsEventNUXCreateAccountClickedPage3Previous = @"NUX - Create Account - Clicked Page 3 Previous";
NSString *const StatsEventNUXCreateAccountClickedViewLanguages = @"NUX - Create Account - Viewed Languages";
NSString *const StatsEventNUXCreateAccountChangedDefaultURL = @"NUX - Create Account - Changed Default URL";

// NUX Second Walkthrough
NSString *const StatsEventNUXSecondWalkthroughOpened = @"NUX - Second Walkthrough - Opened";
NSString *const StatsEventNUXSecondWalkthroughViewedPage2 = @"NUX - Second Walkthrough - Viewed Page 2";
NSString *const StatsEventNUXSecondWalkthroughViewedPage3 = @"NUX - Second Walkthrough - Viewed Page 3";
NSString *const StatsEventNUXSecondWalkthroughViewedPage4 = @"NUX - Second Walkthrough - Viewed Page 4";
NSString *const StatsEventNUXSecondWalkthroughClickedStartUsingApp = @"NUX - Second Walkthrough - Clicked Start Using App";
NSString *const StatsEventNUXSecondWalkthroughClickedStartUsingAppOnFinalPage = @"NUX - Second Walkthrough - Clicked Start Using App on Final Page";

// Ådd Blogs Screen
NSString *const StatsEventAddBlogsOpened = @"Add Blogs - Opened";
NSString *const StatsEventAddBlogsClickedSelectAll = @"Add Blogs - Clicked Select All";
NSString *const StatsEventAddBlogsClickedDeselectAll = @"Add Blogs - Clicked Deselect All";
NSString *const StatsEventAddBlogsClickedAddSelected = @"Add Blogs - Clicked Add Selected";

@implementation WPMobileStats

+ (void)initializeStats
{
    [Mixpanel sharedInstanceWithToken:[WordPressComApiCredentials mixpanelAPIToken]];
}

+ (void)trackEventForSelfHostedAndWPCom:(NSString *)event
{
    [[Mixpanel sharedInstance] track:event];
}

+ (void)trackEventForSelfHostedAndWPCom:(NSString *)event properties:(NSDictionary *)properties
{
    [[Mixpanel sharedInstance] track:event properties:properties];
}

+ (void)trackEventForWPCom:(NSString *)event
{
    if ([self connectedToWordPressDotCom]) {
        [[Mixpanel sharedInstance] track:event];
    }
}

+ (void)trackEventForWPCom:(NSString *)event properties:(NSDictionary *)properties
{
    if ([self connectedToWordPressDotCom]) {
        [[Mixpanel sharedInstance] track:event properties:properties];
    }
}

#pragma mark - Private Methods

+ (BOOL)connectedToWordPressDotCom
{
    return [[WordPressComApi sharedApi] hasCredentials];
}


@end
