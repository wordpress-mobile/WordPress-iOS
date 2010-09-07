//
//  PostMediaViewController.h
//  WordPress
//
//  Created by Chris Boyd on 8/26/10.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "UIDevice-Hardware.h"
#import "UIImage+Resize.h"
#import "WordPressAppDelegate.h"
#import "BlogDataManager.h"
#import "MediaManager.h"
#import "WPMediaUploader.h"

@class PostViewController;

static inline double radians(double degrees) {
    return degrees * M_PI / 180;
}

@interface PostMediaViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate> {
	WordPressAppDelegate *appDelegate;
	PostViewController *postDetailViewController;
	MediaManager *mediaManager;
	WPMediaUploader *mediaUploader;
	
	IBOutlet UITableView *table;
	IBOutlet UIBarButtonItem *addMediaButton;
	IBOutlet UIActivityIndicatorView *spinner;
	IBOutlet UILabel *messageLabel;
	IBOutlet UISegmentedControl *mediaTypeControl;
	
	BOOL hasPhotos, hasVideos, isAddingMedia, isShowingMediaPickerActionSheet, isShowingChangeOrientationActionSheet;
	BOOL isLibraryMedia, didChangeOrientationDuringRecord, isShowingResizeActionSheet, videoEnabled, isCheckingVideoCapability;
	NSString *postID, *blogURL, *uploadID, *videoPressCheckBlogURL;
	
	NSMutableArray *photos, *videos;
	UIDeviceOrientation currentOrientation;
    UIImage *currentImage;
	UIImagePickerController *picker;
	NSMutableDictionary *currentVideo;
}

@property (nonatomic, retain) IBOutlet UITableView *table;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *addMediaButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, retain) IBOutlet UILabel *messageLabel;
@property (nonatomic, retain) IBOutlet UISegmentedControl *mediaTypeControl;
@property (nonatomic, assign) BOOL hasPhotos, hasVideos, isAddingMedia, isShowingMediaPickerActionSheet, isShowingChangeOrientationActionSheet;
@property (nonatomic, assign) BOOL isLibraryMedia, didChangeOrientationDuringRecord, isShowingResizeActionSheet, videoEnabled, isCheckingVideoCapability;
@property (nonatomic, retain) NSString *postID, *blogURL, *uploadID, *videoPressCheckBlogURL;
@property (nonatomic, retain) NSMutableArray *photos, *videos;
@property (nonatomic, assign) WordPressAppDelegate *appDelegate;
@property (nonatomic, assign) PostViewController *postDetailViewController;
@property (nonatomic, retain) MediaManager *mediaManager;
@property (nonatomic, retain) WPMediaUploader *mediaUploader;
@property (nonatomic, assign) UIDeviceOrientation currentOrientation;
@property (nonatomic, retain) UIImage *currentImage;
@property (nonatomic, retain) UIImagePickerController *picker;
@property (nonatomic, retain) NSMutableDictionary *currentVideo;

- (IBAction)refreshMedia;
- (void)scaleAndRotateImage:(UIImage *)image;
- (IBAction)showPhotoPickerActionSheet;
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
- (void)pickPhotoFromCamera:(id)sender;
- (void)pickVideoFromCamera:(id)sender;
- (MediaOrientation)interpretOrientation:(UIDeviceOrientation)theOrientation;
- (void)deviceDidRotate:(NSNotification *)notification;
- (void)showResizeActionSheet;
- (UIImage *)resizeImage:(UIImage *)original toSize:(MediaResize)resize;
- (void)pickPhotoFromPhotoLibrary:(id)sender;
- (void)showOrientationChangedActionSheet;
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)processRecordedVideo;
- (void)processLibraryVideo;
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(NSString *)contextInfo;
- (UIImage *)fixImageOrientation:(UIImage *)img;
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;
- (void)useImage:(UIImage *)theImage;
- (void)useVideo:(NSData *)video withThumbnail:(UIImage *)thumbnail;
- (void)mediaDidUploadSuccessfully:(NSNotification *)notification;
- (void)mediaUploadFailed:(NSNotification *)notification;
- (void)removemediaUploader:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
- (BOOL)supportsVideo;
- (UIImage *)generateThumbnailFromImage:(UIImage *)theImage andSize:(CGSize)targetSize;
- (void)uploadMedia:(NSData *)bits withFilename:(NSString *)filename andMediaType:(MediaType)mediaType;
- (void)updateMediaCount;
- (NSString *)getUUID;
- (void)checkVideoEnabled;

@end
