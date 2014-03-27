//
//  PostMediaViewController.h
//  WordPress
//
//  Created by Chris Boyd on 8/26/10.
//  Code is poetry.
//

#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "UIImage+Resize.h"
#import "WordPressAppDelegate.h"
#import "MediaObjectViewController.h"
#import "WPAlertView.h"


typedef void (^ALAssetsLibraryAssetForURLResultBlock)(ALAsset *asset);
typedef void (^ALAssetsLibraryAccessFailureBlock)(NSError *error);

@class EditPostViewController;

static inline double radians(double degrees) {
    return degrees * M_PI / 180;
}

@interface PostMediaViewController : UITableViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UIPopoverControllerDelegate, NSFetchedResultsControllerDelegate, UITextFieldDelegate> {
	BOOL isPickingFeaturedImage;
    NSFetchedResultsController *resultsController;
}

@property (nonatomic, strong) UIPopoverController *addPopover;
@property (nonatomic, assign) BOOL hasPhotos, hasVideos, isAddingMedia, isShowingMediaPickerActionSheet, isShowingChangeOrientationActionSheet, isShowingCustomSizeAlert;
@property (nonatomic, assign) BOOL isLibraryMedia, didChangeOrientationDuringRecord, isShowingResizeActionSheet, videoEnabled, isCheckingVideoCapability;
@property (nonatomic, strong) NSString *postID, *blogURL, *videoPressCheckBlogURL, *uniqueID;
@property (nonatomic, strong) Media *currentUpload;
@property (nonatomic, strong) NSMutableArray *photos, *videos;
@property (nonatomic, assign) MediaOrientation currentOrientation;
@property (nonatomic, strong) UIImage *currentImage;
@property (nonatomic, strong) NSDictionary *currentImageMetadata;
@property (nonatomic, strong) NSMutableDictionary *currentVideo;
@property (nonatomic, strong) UIImagePickerController *picker;
@property (weak, readonly) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) WPAlertView *customSizeAlert;
@property (nonatomic, strong) UIActionSheet *currentActionSheet;
@property (nonatomic, strong) NSString *statsPrefix;

- (id)initWithPost:(AbstractPost *)aPost;
- (void)scaleAndRotateImage:(UIImage *)image;
- (void)pickPhotoFromCamera:(id)sender;
- (void)pickVideoFromCamera:(id)sender;
- (MediaOrientation)interpretOrientation:(UIDeviceOrientation)theOrientation;
- (void)deviceDidRotate:(NSNotification *)notification;
- (void)showResizeActionSheet;
- (void)showCustomSizeAlert;
- (UIImage *)resizeImage:(UIImage *)original toSize:(MediaResize)resize;
- (UIImage *)resizeImage:(UIImage *)original width:(CGFloat)width height:(CGFloat)height;
- (void)pickPhotoFromPhotoLibrary:(id)sender;
- (void)showOrientationChangedActionSheet;
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
- (void)processRecordedVideo;
- (void)processLibraryVideo;
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(NSString *)contextInfo;
- (UIImage *)fixImageOrientation:(UIImage *)img;
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;
- (void)useImage:(UIImage *)theImage;
- (void)useVideo:(NSString *)videoURL;
- (void)mediaDidUploadSuccessfully:(NSNotification *)notification;
- (void)mediaUploadFailed:(NSNotification *)notification;
- (BOOL)isDeviceSupportVideoAndVideoPressEnabled;
- (BOOL)isDeviceSupportVideo;
- (UIImage *)generateThumbnailFromImage:(UIImage *)theImage andSize:(CGSize)targetSize;
- (void)checkVideoPressEnabled;
- (void)initObjects;
- (void)addNotifications;
- (void)removeNotifications;

@end
