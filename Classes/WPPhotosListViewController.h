#import <UIKit/UIKit.h>
#import "WPPhotoViewController.h"
#import "PostViewController.h"
#import "PageViewController.h"
#import "WPImageView.h"
#import "WPImagePickerController.h"

@interface WPPhotosListViewController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    IBOutlet UITableView *tableView;
    IBOutlet UITextField *countField;

    UIImage *currentChoosenImage;
    WPImagePickerController *pickerController;

    id<WPPhotosListProtocol> delegate;
    PostViewController *postDetailViewController;
    PageViewController *pageDetailsController;

    BOOL isShowPhotoPickerActionSheet;
}

@property (nonatomic, assign) PostViewController *postDetailViewController;
@property (nonatomic, assign) PageViewController *pageDetailsController;
@property (nonatomic, assign) id <WPPhotosListProtocol> delegate;

@property (nonatomic, retain) UITableView *tableView;

- (IBAction)addPhotoFromLibraryAction:(id)sender;
- (IBAction)addPhotoFromCameraAction:(id)sender;
- (IBAction)showPhotoUploadScreen:(id)sender;
- (void)refreshData;

- (void)pickPhotoFromCamera:(id)sender;
- (void)pickPhotoFromPhotoLibrary:(id)sender;
- (void)useImage:(UIImage *)theImage;
- (void)showPhotoPickerActionSheet;
- (UIImage *)scaleAndRotateImage:(UIImage *)image scaleFlag:(BOOL)aFlag;

@end
