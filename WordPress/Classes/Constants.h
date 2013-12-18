//
//  Constants.h
//  WordPress
//
//  Created by Ganesh Ramachandran on 6/6/08.
//

// Blog archive file name

#define BLOG_ARCHIVE_NAME       WordPress_Blogs

// control dimensions
#define kStdButtonWidth         106.0
#define kStdButtonHeight        40.0

#define kTextFieldHeight        20.0
#define kTextFieldFontSize      18.0
#define kTextFieldFont          @"Arial"
#define kTextViewPlaceholder	@"Tap here to begin writing."
#define kAppStoreURL			@"http://itunes.apple.com/us/app/wordpress/id335703880?mt=8"
#define kNotificationAuthURL	@"https://wordpress.com/xmlrpc.php"

#define kMobileReaderDetailURL  @"https://en.wordpress.com/reader/mobile/v2/?template=details"
#define kMobileReaderFFURL      @"https://en.wordpress.com/reader/mobile/v2/?template=friendfinder"

#define kNotificationsURL       @"http://wordpress.com/?no-chrome#!/notifications/"


#define kAccessedAddressBookPreference   @"AddressBookAccessGranted"

#define kStatsEndpointURL		@"https://stats.wordpress.com/api/1.0/"
#define kJetPackURL             @"http://jetpack.me"







//R: 35, G: 112, B: 216 | #2370D8 | ΔX: 1378, ΔY: 29 | img

#define CGRectToString(rect) [NSString stringWithFormat:@"%f,%f:%fx%f", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height]
#define CGPointToString(point) [NSString stringWithFormat:@"%f,%f", point.x, point.y]

#define kBlogId                                 @"blogid"
#define kBlogHostName                           @"blog_host_name"
#define kCurrentBlogIndex                       @"CurrentBlogIndex"
#define kResizePhotoSetting                     @"ResizePhotoSetting"
#define kGeolocationSetting						@"GeolocationSetting"
#define kLocationSetting						@"LocationSetting"
#define kSupportsVideoPress						@"SupportsVideoPress"
#define kAsyncPostFlag                          @"async_post"
#define kVersionAlertShown                      @"VersionAlertShown"
#define kResizePhotoSettingHintLabel            @"Resizing will result in faster publishing \n but smaller photos. Resized photos \n will be no larger than 640 x 480."
#define kPasswordHintLabel                      @"Setting a password will require visitors to \n enter the above password to view this \n post and its comments."
#define kLocationOnSetting						@"LocationOnSetting"

#pragma mark Error Messages

#define kBlogExistsErrorMessage                 @"Blog '%@' already configured on this iPhone."

#define PictureObjectUploadedNotificationName @"PictureObjectUploadedNotificationName"
#define VideoSaved @"VideoSavedNotification"
#define VideoUploadChunk @"VideoUploadChunk"
#define kXML_RPC_ERROR_OCCURS @"kXML_RPC_ERROR_OCCURS"
#define kURL @"URL"
#define kMETHOD @"METHOD"
#define kMETHODARGS @"METHODARGS"
#define BlavatarLoaded @"BlavatarLoaded"
#define kCameraPlusImagesNotification @"CameraPlusImagesNotification"

#define kPostsDownloadCount @"postsDownloadCount"
#define kDraftsBlogIdStr @"localDrafts"
#define kDraftsHostName @"iPhone"

#define kDidDismissWPcomLoginNotification @"didDismissWPcomLogin"

#define kUnsupportedWordpressVersionTag 900
#define kRSDErrorTag 901
#define kCrashAlertTag 902
#define kNoXMLPrefix 903
#define kNotificationNewComment 1001
#define kNotificationNewSocial 1002

/**
 Notification type could be one of the following values:
 - pl : Post like
 - c  : New Comment
 - cl : Comment like
 - sb : Subscription to a blog
 - rb : reblog
 */
#define kNotificationTypeComment @"c"
#define kNotificationTypeCommentLike @"cl"
#define kNotificationTypePostLike @"pl"
#define kNotificationTypeFollowBlog @"sb"
#define kNotificationTypeReblog @"rb"
#define kNotificationTypeAchievement @"ac"

#define kSettingsMuteSoundsKey @"settings_mute_sounds"



typedef NS_ENUM(NSUInteger, EditPageMode) {
	kNewPage,
	kEditPage,
	kAutorecoverPage,
	kRefreshPage
};
static NSString *const kMobileReaderURL	= @"https://en.wordpress.com/reader/mobile/v2/?chrome=no";



