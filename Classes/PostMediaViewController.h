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
#import "UIDevice-Hardware.h"
#import "UIImage+Resize.h"
#import "WordPressAppDelegate.h"
#import "MediaObjectViewController.h"

typedef void (^ALAssetsLibraryAssetForURLResultBlock)(ALAsset *asset);
typedef void (^ALAssetsLibraryAccessFailureBlock)(NSError *error);

@class EditPostViewController;

static inline double radians(double degrees) {
    return degrees * M_PI / 180;
}

@interface PostMediaViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UIPopoverControllerDelegate, NSFetchedResultsControllerDelegate, UITextFieldDelegate> {
	EditPostViewController *__weak postDetailViewController;
	UIImagePickerController *picker;
	
	IBOutlet UITableView *table;
	IBOutlet UIBarButtonItem *addMediaButton;
	IBOutlet UIActivityIndicatorView *spinner;
	IBOutlet UILabel *messageLabel;
	IBOutlet UIToolbar *bottomToolbar;
	IBOutlet UIPopoverController *addPopover;
	
	BOOL hasPhotos, hasVideos, isAddingMedia, isShowingMediaPickerActionSheet, isShowingChangeOrientationActionSheet, isShowingCustomSizeAlert;
	BOOL isLibraryMedia, didChangeOrientationDuringRecord, isShowingResizeActionSheet, videoEnabled, isCheckingVideoCapability, isPickingFeaturedImage;
	NSString *postID, *blogURL, *videoPressCheckBlogURL, *uniqueID;
    Media *currentUpload;
	
	NSMutableArray *photos, *videos;
	MediaOrientation currentOrientation;
    UIImage *currentImage;
	NSDictionary *currentImageMetadata;
	NSMutableDictionary *currentVideo;
    NSFetchedResultsController *resultsController;
	
	//used in customResizeField
	UIAlertView *customSizeAlert;
    UIActionSheet *currentActionSheet;
}

@property (nonatomic, strong) IBOutlet UITableView *table;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *addMediaButton;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) IBOutlet UILabel *messageLabel;
@property (nonatomic, strong) IBOutlet UIToolbar *bottomToolbar;
@property (nonatomic, strong) IBOutlet UIPopoverController *addPopover;
@property (nonatomic, assign) BOOL hasPhotos, hasVideos, isAddingMedia, isShowingMediaPickerActionSheet, isShowingChangeOrientationActionSheet, isShowingCustomSizeAlert;
@property (nonatomic, assign) BOOL isLibraryMedia, didChangeOrientationDuringRecord, isShowingResizeActionSheet, videoEnabled, isCheckingVideoCapability;
@property (nonatomic, strong) NSString *postID, *blogURL, *videoPressCheckBlogURL, *uniqueID;
@property (nonatomic, strong) Media *currentUpload;
@property (nonatomic, strong) NSMutableArray *photos, *videos;
@property (nonatomic, weak) EditPostViewController *postDetailViewController;
@property (nonatomic, assign) MediaOrientation currentOrientation;
@property (nonatomic, strong) UIImage *currentImage;
@property (nonatomic, strong) NSDictionary *currentImageMetadata;
@property (nonatomic, strong) NSMutableDictionary *currentVideo;
@property (nonatomic, strong) UIImagePickerController *picker;
@property (weak, readonly) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) UIAlertView *customSizeAlert;
@property (nonatomic, strong) UIActionSheet *currentActionSheet;

- (void)scaleAndRotateImage:(UIImage *)image;
- (IBAction)showVideoPickerActionSheet:(id)sender;
- (IBAction)showPhotoPickerActionSheet:(id)sender;
- (IBAction)showPhotoPickerActionSheet:(id)sender fromRect:(CGRect)rect isFeaturedImage:(BOOL)featuredImage;
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
