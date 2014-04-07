#import <Foundation/Foundation.h>

// General
extern NSString *const StatsEventAppOpened;
extern NSString *const StatsEventAppClosed;
extern NSString *const StatsEventAppOpenedDueToPushNotification;

// Top Level Menu Items
extern NSString *const StatsPropertySidebarClickedReader;
extern NSString *const StatsPropertySidebarClickedNotifications;
extern NSString *const StatsPropertySidebarSiteClickedPosts;
extern NSString *const StatsPropertySidebarSiteClickedPages;
extern NSString *const StatsPropertySidebarSiteClickedComments;
extern NSString *const StatsPropertySidebarSiteClickedStats;
extern NSString *const StatsPropertySidebarSiteClickedViewSite;
extern NSString *const StatsPropertySidebarSiteClickedViewAdmin;
extern NSString *const StatsPropertySidebarSiteClickedThemes;
extern NSString *const StatsPropertySidebarSiteClickedMediaLibrary;
extern NSString *const StatsPropertySidebarClickedSettings;
extern NSString *const StatsPropertySidebarClickedQuickPhoto;

// Reader
extern NSString *const StatsEventReaderOpened;
extern NSString *const StatsEventReaderHomePageRefresh;
extern NSString *const StatsEventReaderInfiniteScroll;
extern NSString *const StatsEventReaderSelectedFreshlyPressedTopic;
extern NSString *const StatsEventReaderSelectedCategory;
extern NSString *const StatsEventReaderOpenedArticleDetails;
extern NSString *const StatsEventReaderPublishedComment;
extern NSString *const StatsEventReaderReblogged;
extern NSString *const StatsEventReaderLikedPost;
extern NSString *const StatsEventReaderUnlikedPost;
extern NSString *const StatsPropertyReaderOpenedFromExternalURL;
extern NSString *const StatsPropertyReaderOpenedFromExternalURLCount;
extern NSString *const StatsEventReaderOpenedFromExternalSource;

// Reader Detail
extern NSString *const StatsPropertyReaderDetailClickedPrevious;
extern NSString *const StatsPropertyReaderDetailClickedNext;

// Web View Sharing
extern NSString *const StatsEventWebviewClickedShowLinkOptions;
extern NSString *const StatsEventWebviewSharedArticleViaEmail;
extern NSString *const StatsEventWebviewSharedArticleViaSMS;
extern NSString *const StatsEventWebviewSharedArticleViaTwitter;
extern NSString *const StatsEventWebviewSharedArticleViaFacebook;
extern NSString *const StatsEventWebviewSharedArticleViaWeibo;
extern NSString *const StatsEventWebviewCopiedArticleDetails;
extern NSString *const StatsEventWebviewOpenedArticleInSafari;
extern NSString *const StatsEventWebviewSentArticleToPocket;
extern NSString *const StatsEventWebviewSentArticleToInstapaper;
extern NSString *const StatsEventWebviewSentArticleToGooglePlus;

// Notifications
extern NSString *const StatsPropertyNotificationsOpened;
extern NSString *const StatsPropertyNotificationsOpenedDetails;
extern NSString *const StatsEventNotificationsClickedManageNotifications;

// Notifications Detail
extern NSString *const StatsEventNotificationsDetailClickedReplyButton;
extern NSString *const StatsEventNotificationsDetailRepliedToComment;
extern NSString *const StatsEventNotificationsDetailApproveComment;
extern NSString *const StatsEventNotificationsDetailUnapproveComment;
extern NSString *const StatsEventNotificationsDetailTrashComment;
extern NSString *const StatsEventNotificationsDetailUntrashComment;
extern NSString *const StatsEventNotificationsDetailFlagCommentAsSpam;
extern NSString *const StatsEventNotificationsDetailUnflagCommentAsSpam;
extern NSString *const StatsEventNotificationsDetailFollowBlog;
extern NSString *const StatsEventNotificationsDetailUnfollowBlog;

// Posts
extern NSString *const StatsPropertyPostsOpened;
extern NSString *const StatsEventPostsClickedNewPost;

// Post Detail
extern NSString *const StatsPropertyPostDetailClickedEdit;
extern NSString *const StatsPropertyPostDetailClickedSettings;
extern NSString *const StatsPropertyPostDetailClickedMedia;
extern NSString *const StatsPropertyPostDetailClickedPreview;
extern NSString *const StatsPropertyPostDetailClickedMediaOptions;
extern NSString *const StatsPropertyPostDetailClickedAddVideo;
extern NSString *const StatsPropertyPostDetailClickedAddPhoto;
extern NSString *const StatsPropertyPostDetailClickedShowCategories;
extern NSString *const StatsEventPostDetailClickedKeyboardToolbarBoldButton;
extern NSString *const StatsEventPostDetailClickedKeyboardToolbarItalicButton;
extern NSString *const StatsEventPostDetailClickedKeyboardToolbarUnderlineButton;
extern NSString *const StatsEventPostDetailClickedKeyboardToolbarLinkButton;
extern NSString *const StatsEventPostDetailClickedKeyboardToolbarBlockquoteButton;
extern NSString *const StatsEventPostDetailClickedKeyboardToolbarDelButton;
extern NSString *const StatsEventPostDetailClickedKeyboardToolbarMoreButton;
extern NSString *const StatsEventPostDetailAddedPhoto;
extern NSString *const StatsEventPostDetailRemovedPhoto;
extern NSString *const StatsEventPostDetailClickedSchedule;
extern NSString *const StatsEventPostDetailClickedSave;
extern NSString *const StatsEventPostDetailClickedUpdate;
extern NSString *const StatsEventPostDetailClickedPublish;
extern NSString *const StatsEventPostDetailOpenedEditor;
extern NSString *const StatsEventPostDetailClosedEditor;
extern NSString *const StatsPropertyPostDetailEditorOpenedBy;
extern NSString *const StatsPropertyPostDetailEditorOpenedOpenedByPostsView;
extern NSString *const StatsPropertyPostDetailEditorOpenedOpenedByTabBarButton;
extern NSString *const StatsPropertyPostDetailClickedBlogSelector;
extern NSString *const StatsPropertyPostDetailHasExternalKeyboard;
extern NSString *const StatsPropertyPostDetailWordCount;
extern NSString *const StatsPropertyPostDetailWordDiffCount;

// Post Detail - Settings
extern NSString *const StatsPropertyPostDetailSettingsClickedStatus;
extern NSString *const StatsPropertyPostDetailSettingsClickedVisibility;
extern NSString *const StatsPropertyPostDetailSettingsClickedScheduleFor;
extern NSString *const StatsPropertyPostDetailSettingsClickedPostFormat;
extern NSString *const StatsPropertyPostDetailSettingsClickedSetFeaturedImage;
extern NSString *const StatsPropertyPostDetailSettingsClickedRemoveFeaturedImage;
extern NSString *const StatsPropertyPostDetailSettingsClickedAddLocation;
extern NSString *const StatsPropertyPostDetailSettingsClickedUpdateLocation;
extern NSString *const StatsPropertyPostDetailSettingsClickedRemoveLocation;

// Pages
extern NSString *const StatsPropertyPagesOpened;
extern NSString *const StatsEventPagesClickedNewPage;

// Comments
extern NSString *const StatsEventCommentsViewCommentDetails;

// Comment Detail
extern NSString *const StatsEventCommentDetailApprove;
extern NSString *const StatsEventCommentDetailUnapprove;
extern NSString *const StatsEventCommentDetailDelete;
extern NSString *const StatsEventCommentDetailFlagAsSpam;
extern NSString *const StatsEventCommentDetailEditComment;
extern NSString *const StatsEventCommentDetailClickedReplyToComment;
extern NSString *const StatsEventCommentDetailRepliedToComment;


// Settings
extern NSString *const StatsEventSettingsRemovedBlog;
extern NSString *const StatsEventSettingsClickedEditBlog;
extern NSString *const StatsEventSettingsClickedAddBlog;
extern NSString *const StatsEventSettingsSignedOutOfDotCom;
extern NSString *const StatsEventSettingsClickedSignIntoDotCom;
extern NSString *const StatsEventSettingsClickedSignOutOfDotCom;
extern NSString *const StatsEventSettingsMediaClickedImageResize;
extern NSString *const StatsEventSettingsMediaClickedVideoQuality;
extern NSString *const StatsEventSettingsMediaClickedVideoContent;
extern NSString *const StatsEventSettingsClickedManageNotifications;
extern NSString *const StatsEventSettingsEnabledSounds;
extern NSString *const StatsEventSettingsDisabledSounds;
extern NSString *const StatsEventSettingsClickedAbout;

// Manage Notifications
extern NSString *const StatsEventManageNotificationsTurnOn;
extern NSString *const StatsEventManageNotificationsTurnOff;
extern NSString *const StatsEventManageNotificationsTurnOffForOneHour;
extern NSString *const StatsEventManageNotificationsTurnOffUntil8AM;
extern NSString *const StatsEventManageNotificationsEnabledFollowNotifications;
extern NSString *const StatsEventManageNotificationsDisabledFollowNotifications;
extern NSString *const StatsEventManageNotificationsEnabledAchievementsNotifications;
extern NSString *const StatsEventManageNotificationsDisabledAchievementsNotifications;
extern NSString *const StatsEventManageNotificationsEnabledCommentNotifications;
extern NSString *const StatsEventManageNotificationsDisabledCommentNotifications;
extern NSString *const StatsEventManageNotificationsEnabledReblogNotifications;
extern NSString *const StatsEventManageNotificationsDisabledReblogNotifications;
extern NSString *const StatsEventManageNotificationsEnabledLikeNotifications;
extern NSString *const StatsEventManageNotificationsDisabledLikeNotifications;
extern NSString *const StatsEventManageNotificationsEnabledBlogNotifications;
extern NSString *const StatsEventManageNotificationsDisabledBlogNotifications;

// Quick Photo
extern NSString *const StatsEventQuickPhotoOpened;
extern NSString *const StatsEventQuickPhotoPosted;

// NUX Related
extern NSString *const StatsEventNUXFirstWalkthroughOpened;
extern NSString *const StatsEventNUXFirstWalkthroughClickedSkipToCreateAccount;
extern NSString *const StatsEventNUXFirstWalkthroughClickedInfo;
extern NSString *const StatsEventNUXFirstWalkthroughClickedCreateAccount;
extern NSString *const StatsEventNUXFirstWalkthroughClickedLostPassword;
extern NSString *const StatsEventNUXFirstWalkthroughSignedInWithoutUrl;
extern NSString *const StatsEventNUXFirstWalkthroughSignedInWithUrl;
extern NSString *const StatsEventNUXFirstWalkthroughSignedInForDotCom;
extern NSString *const StatsEventNUXFirstWalkthroughSignedInForSelfHosted;
extern NSString *const StatsEventNUXFirstWalkthroughClickedEnableXMLRPCServices;
extern NSString *const StatsEventNUXFirstWalkthroughClickedNeededHelpOnError;
extern NSString *const StatsEventNUXFirstWalkthroughUserSignedInToBlogWithJetpack;
extern NSString *const StatsEventNUXFirstWalkthroughUserConnectedToJetpack;
extern NSString *const StatsEventNUXFirstWalkthroughUserSkippedConnectingToJetpack;


// NUX Create Account
extern NSString *const StatsEventAccountCreationOpenedFromTabBar;
extern NSString *const StatsEventNUXCreateAccountOpened;
extern NSString *const StatsEventNUXCreateAccountClickedCancel;
extern NSString *const StatsEventNUXCreateAccountClickedHelp;
extern NSString *const StatsEventNUXCreateAccountClickedAccountPageNext;
extern NSString *const StatsEventNUXCreateAccountClickedSitePageNext;
extern NSString *const StatsEventNUXCreateAccountClickedSitePagePrevious;
extern NSString *const StatsEventNUXCreateAccountCreatedAccount;
extern NSString *const StatsEventNUXCreateAccountClickedReviewPagePrevious;
extern NSString *const StatsEventNUXCreateAccountClickedViewLanguages;
extern NSString *const StatsEventNUXCreateAccountChangedDefaultURL;

// Add Blogs
extern NSString *const StatsEventAddBlogsOpened;
extern NSString *const StatsEventAddBlogsClickedSelectAll;
extern NSString *const StatsEventAddBlogsClickedDeselectAll;
extern NSString *const StatsEventAddBlogsClickedAddSelected;

// Stats
extern NSString *const StatsEventStatsClickedOnWebVersion;

// Super Properties

// General
extern NSString *const StatsSuperPropertyNumberOfTimesOpenedReader;
extern NSString *const StatsSuperPropertyNumberOfTimesOpenedNotifications;
extern NSString *const StatsSuperPropertyNumberOfTimesOpenedStats;
extern NSString *const StatsSuperPropertyNumberOfTimesOpenedViewAdmin;

// Reader
extern NSString *const StatsSuperPropertyNumberOfItemsOpenedInReader;
extern NSString *const StatsSuperPropertyNumberOfItemsLikedInReader;
extern NSString *const StatsSuperPropertyNumberOfItemsUnlikedInReader;
extern NSString *const StatsSuperPropertyNumberOfItemsRebloggedInReader;

// Sharing
extern NSString *const StatsSuperPropertyNumberOfItemsShared;
extern NSString *const StatsSuperPropertyNumberOfItemsSharedViaEmail;
extern NSString *const StatsSuperPropertyNumberOfItemsSharedViaSMS;
extern NSString *const StatsSuperPropertyNumberOfItemsSharedViaTwitter;
extern NSString *const StatsSuperPropertyNumberOfItemsSharedViaFacebook;
extern NSString *const StatsSuperPropertyNumberOfItemsSharedViaWeibo;
extern NSString *const StatsSuperPropertyNumberOfItemsSentToPocket;
extern NSString *const StatsSuperPropertyNumberOfItemsSentToInstapaper;
extern NSString *const StatsSuperPropertyNumberOfItemsSentToGooglePlus;

// Notifications
extern NSString *const StatsSuperPropertyNumberOfTimesOpenedNotificationDetails;
extern NSString *const StatsSuperPropertyNumberOfNotificationsResultingInActions;
extern NSString *const StatsSuperPropertyNumberOfNotificationsRepliedTo;
extern NSString *const StatsSuperPropertyNumberOfNotificationsApproved;
extern NSString *const StatsSuperPropertyNumberOfNotificationsUnapproved;
extern NSString *const StatsSuperPropertyNumberOfNotificationsTrashed;
extern NSString *const StatsSuperPropertyNumberOfNotificationsUntrashed;
extern NSString *const StatsSuperPropertyNumberOfNotificationsFlaggedAsSpam;
extern NSString *const StatsSuperPropertyNumberOfNotificationsUnflaggedAsSpam;
extern NSString *const StatsSuperPropertyNumberOfNotificationsResultingInAFollow;
extern NSString *const StatsSuperPropertyNumberOfNotificationsResultingInAnUnfollow;

// Posts
extern NSString *const StatsSuperPropertyNumberOfPostsPublished;
extern NSString *const StatsSuperPropertyNumberOfPostsUpdated;
extern NSString *const StatsSuperPropertyNumberOfPhotosAddedToPosts;
extern NSString *const StatsSuperPropertyNumberOfVideosAddedToPosts;
extern NSString *const StatsSuperPropertyNumberOfFeaturedImagesAssignedToPosts;
extern NSString *const StatsSuperPropertyNumberOfPostsWithPhotos;
extern NSString *const StatsSuperPropertyNumberOfPostsWithVideos;
extern NSString *const StatsSuperPropertyNumberOfPostsWithCategories;
extern NSString *const StatsSuperPropertyNumberOfPostsWithTags;



@interface WPMobileStats : NSObject

+ (void)initializeStats;

+ (void)pauseSession;

+ (void)recordAppOpenedForEvent:(NSString *)event;
+ (void)trackEventForSelfHostedAndWPCom:(NSString *)event;
+ (void)trackEventForSelfHostedAndWPCom:(NSString *)event properties:(NSDictionary *)properties;
+ (void)trackEventForSelfHostedAndWPComWithSavedProperties:(NSString *)event;
+ (void)trackEventForWPCom:(NSString *)event;
+ (void)trackEventForWPCom:(NSString *)event properties:(NSDictionary *)properties;
+ (void)trackEventForWPComWithSavedProperties:(NSString *)event;
+ (void)pingWPComStatsEndpoint:(NSString *)statName;

/*
    Mixpanel has both properties and super properties which should be used differently depending on the
    circumstance. A property in general can be attached to any event, so for example an event with
    the title "Opened from External Source" can have a property "external_source" which identifies the
    source of the event. Properties are useful to attach to events because they allow us to drill down
    into certain events with more detail. Super properties are different from properties in that super
    properties are attached to *every* event that gets sent up to Mixpanel. Things that you might
    use as super properties are perhaps certain things that you want to track across events that may
    help you determine certain patterns in the app. For example 'number_of_blogs' is a super property
    attached to every single event.
 */
+ (void)clearPropertiesForAllEvents;
+ (void)incrementProperty:(NSString *)property forEvent:(NSString *)event;
+ (void)setValue:(id)value forProperty:(NSString *)property forEvent:(NSString *)event;
+ (void)flagProperty:(NSString *)property forEvent:(NSString *)event;
+ (void)unflagProperty:(NSString *)property forEvent:(NSString *)event;


+ (void)flagSuperProperty:(NSString *)property;
+ (void)incrementSuperProperty:(NSString *)property;
+ (void)setValue:(id)value forSuperProperty:(NSString *)property;

+ (void)flagPeopleProperty:(NSString *)property;
+ (void)incrementPeopleProperty:(NSString *)property;
+ (void)setValue:(id)value forPeopleProperty:(NSString *)property;

+ (void)flagPeopleAndSuperProperty:(NSString *)property;
+ (void)incrementPeopleAndSuperProperty:(NSString *)property;
+ (void)setValue:(id)value forPeopleAndSuperProperty:(NSString *)property;

@end
