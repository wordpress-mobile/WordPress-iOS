#import <UIKit/UIKit.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "WPPhotoViewController.h"
#import "PostViewController.h"
#import "PageViewController.h"
#import "WPImageView.h"
#import "WPImagePickerController.h"
#import "UIDevice-Hardware.h"

typedef enum {
kPortrait,
kLandscape
} VideoOrientation;

@interface WPPhotosListViewController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    IBOutlet UITableView *tableView;
    IBOutlet UILabel *messageLabel;
	IBOutlet UIActivityIndicatorView *spinner;
	IBOutlet UIBarButtonItem *addButton;
	IBOutlet UIToolbar *toolbar;
	VideoOrientation videoOrientation;

    UIImage *currentChoosenImage;
	NSDictionary *currentVideo;
    WPImagePickerController *pickerController;

    id<WPPhotosListProtocol> delegate;
    PostViewController *postDetailViewController;
    PageViewController *pageDetailsController;

    BOOL isShowingMediaPickerActionSheet, isShowingChangeOrientationActionSheet, didChangeOrientationDuringRecord;
	BOOL isAddingMedia, isLibraryMedia;
}

@property (nonatomic, assign) PostViewController *postDetailViewController;
@property (nonatomic, assign) PageViewController *pageDetailsController;
@property (nonatomic, assign) id <WPPhotosListProtocol> delegate;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *addButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, retain) IBOutlet UILabel *messageLabel;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, assign) VideoOrientation videoOrientation;
@property (nonatomic, retain) NSDictionary *currentVideo;
@property (nonatomic, assign) BOOL isShowingMediaPickerActionSheet, isShowingChangeOrientationActionSheet, didChangeOrientationDuringRecord;
@property (nonatomic, assign) BOOL isAddingMedia, isLibraryMedia;

- (IBAction)addPhotoFromLibraryAction:(id)sender;
- (IBAction)addPhotoFromCameraAction:(id)sender;
- (IBAction)showPhotoUploadScreen:(id)sender;
- (void)refreshData;
- (void)pickPhotoFromCamera:(id)sender;
- (void)pickVideoFromCamera:(id)sender;
- (void)pickPhotoFromPhotoLibrary:(id)sender;
- (void)useImage:(UIImage *)theImage;
- (void)useVideo:(NSData *)video withThumbnail:(NSString *)thumbnailURL andFilename:(NSString *)filename;
- (void)showPhotoPickerActionSheet;
- (UIImage *)scaleAndRotateImage:(UIImage *)image scaleFlag:(BOOL)aFlag;
- (BOOL)supportsVideo;
- (VideoOrientation)interpretOrientation:(UIDeviceOrientation)theOrientation;
- (void)deviceDidRotate:(NSNotification *)notification;
- (void)showOrientationChangedActionSheet;
- (void)processRecordedVideo;
- (void)processLibraryVideo;
- (void)updateMessageLabel:(NSString *)message;

@end
