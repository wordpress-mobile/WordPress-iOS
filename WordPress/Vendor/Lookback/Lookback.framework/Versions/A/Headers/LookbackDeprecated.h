#import <Foundation/Foundation.h>

#ifndef LOOKBACK_INTERNAL
#define LOOKBACK_DEPRECATED_ATTRIBUTE DEPRECATED_ATTRIBUTE
#else
#define LOOKBACK_DEPRECATED_ATTRIBUTE
#endif

/*!
	@header Lookback Deprecated API
	The use of these interfaces is discourages and will be removed in a future
	version of Lookback.
*/

#pragma mark Compatibility macros
/*!
	@group Compatibility macros
	For compatibility with old code using Lookback under the miscapitalized or
	misprefixed names.
 */
#define LookBack Lookback
#define GFAutomaticallyLogViewAppearance LookbackAutomaticallyLogViewAppearance
#define GFCameraEnabledSettingsKey LookbackCameraEnabledSettingsKey
#define GFAudioEnabledSettingsKey LookbackAudioEnabledSettingsKey
#define GFShowPreviewSettingsKey LookbackShowPreviewSettingsKey
#define GFStartedUploadingNotificationName LookbackStartedUploadingNotificationName
#define GFExperienceDestinationURLUserInfoKey LookbackExperienceDestinationURLUserInfoKey
#define GFExperienceStartedAtUserInfoKey LookbackExperienceStartedAtUserInfoKey

#pragma mark Deprecated settings - use LookbackRecordingOptions instead

/*! @see -[Lookback automaticallyRecordViewControllerNames]*/
LOOKBACK_DEPRECATED_ATTRIBUTE static NSString *const LookbackAutomaticallyLogViewAppearance = @"GFio.lookback.autologViews";

/*! @see -[Lookback framerateLimit]*/
LOOKBACK_DEPRECATED_ATTRIBUTE static NSString *const LookbackScreenRecorderFramerateLimitKey = @"com.thirdcog.lookback.screenrecorder.fpsLimit";


#pragma mark Settings

/*! @see -[LookbackRecordingOptions afterRecording] */
static NSString *const LookbackCameraEnabledSettingsKey = @"com.thirdcog.lookback.camera.enabled";

/*! @see -[LookbackRecordingOptions microphoneEnabled] */
static NSString *const LookbackAudioEnabledSettingsKey = @"com.thirdcog.lookback.audio.enabled";

/*! @see -[LookbackRecordingOptions showCameraPreviewWhileRecording] */
static NSString *const LookbackShowPreviewSettingsKey = @"com.thirdcog.lookback.preview.enabled";

/*! @see -[LookbackRecordingOptions timeout] */
static NSString *const LookbackRecordingTimeoutSettingsKey = @"io.lookback.recording.timeoutDuration";

/*! @see -[LookbackRecordingOptions afterRecording] */
static NSString *const LookbackAfterRecordingOptionSettingsKey = @"io.lookback.recording.afterTimeoutOption";
DEPRECATED_ATTRIBUTE static NSString *const LookbackRecordingAfterTimeoutOptionSettingsKey = @"io.lookback.recording.afterTimeoutOption";

/*! @see LookbackAfterRecordingOption */
DEPRECATED_ATTRIBUTE typedef NS_ENUM(NSInteger, LookbackAfterTimeoutOption) {
	LookbackAfterTimeoutReview = 0,
	LookbackAfterTimeoutUpload,
};

#pragma mark Deprecated Notifications - use LookbackRecordingOptions instead

static NSString *const LookbackStartedUploadingNotificationName = @"com.thirdcog.lookback.notification.startedUploading";
static NSString *const LookbackExperienceDestinationURLUserInfoKey = @"com.thirdcog.lookback.notification.startedUploading.destinationURL";
static NSString *const LookbackExperienceStartedAtUserInfoKey = @"com.thirdcog.lookback.notification.startedUploading.sessionStartedAt";

//  UserInfo contains LookbackExperienceDestinationURLUserInfoKey and LookbackExperienceNameUserInfoKey
static NSString *const LookbackFinishedUploadingNotificationName = @"io.lookback.notification.finishedUploading";
static NSString *const LookbackExperienceNameUserInfoKey = @"io.lookback.notification.name";

