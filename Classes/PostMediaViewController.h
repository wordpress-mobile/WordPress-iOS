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
#import "WPImagePickerController.h"

typedef void (^ALAssetsLibraryAssetForURLResultBlock)(ALAsset *asset);
typedef void (^ALAssetsLibraryAccessFailureBlock)(NSError *error);

@class EditPostViewController;

static inline double radians(double degrees) {
    return degrees * M_PI / 180;
}

@interface PostMediaViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UIPopoverControllerDelegate, NSFetchedResultsControllerDelegate, UITextFieldDelegate> {
	EditPostViewController *postDetailViewController;
	UIImagePickerController *picker;
	UIViewController *pickerContainer;
	
	IBOutlet UITableView *table;
	IBOutlet UIBarButtonItem *addMediaButton;
	IBOutlet UIActivityIndicatorView *spinner;
	IBOutlet UILabel *messageLabel;
	IBOutlet UIToolbar *bottomToolbar;
	IBOutlet UIPopoverController *addPopover;
	
	BOOL hasPhotos, hasVideos, isAddingMedia, isShowingMediaPickerActionSheet, isShowingChangeOrientationActionSheet, isShowingCustomSizeAlert;
	BOOL isLibraryMedia, didChangeOrientationDuringRecord, isShowingResizeActionSheet, videoEnabled, isCheckingVideoCapability;
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
}

@property (nonatomic, retain) IBOutlet UITableView *table;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *addMediaButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, retain) IBOutlet UILabel *messageLabel;
@property (nonatomic, retain) IBOutlet UIToolbar *bottomToolbar;
@property (nonatomic, retain) IBOutlet IBOutlet UIPopoverController *addPopover;
@property (nonatomic, assign) BOOL hasPhotos, hasVideos, isAddingMedia, isShowingMediaPickerActionSheet, isShowingChangeOrientationActionSheet, isShowingCustomSizeAlert;
@property (nonatomic, assign) BOOL isLibraryMedia, didChangeOrientationDuringRecord, isShowingResizeActionSheet, videoEnabled, isCheckingVideoCapability;
@property (nonatomic, retain) NSString *postID, *blogURL, *videoPressCheckBlogURL, *uniqueID;
@property (nonatomic, retain) Media *currentUpload;
@property (nonatomic, retain) NSMutableArray *photos, *videos;
@property (nonatomic, assign) EditPostViewController *postDetailViewController;
@property (nonatomic, assign) MediaOrientation currentOrientation;
@property (nonatomic, retain) UIImage *currentImage;
@property (nonatomic, retain) NSDictionary *currentImageMetadata;
@property (nonatomic, retain) NSMutableDictionary *currentVideo;
@property (nonatomic, retain) UIImagePickerController *picker;
@property (nonatomic, retain) UIViewController *pickerContainer;
@property (readonly) NSFetchedResultsController *resultsController;
@property (nonatomic, retain) UIAlertView *customSizeAlert;

- (void)scaleAndRotateImage:(UIImage *)image;
- (IBAction)showVideoPickerActionSheet:(id)sender;
- (IBAction)showPhotoPickerActionSheet:(id)sender;
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
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
