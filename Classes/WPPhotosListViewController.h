#import <UIKit/UIKit.h>
#import "WPPhotoViewController.h"
#import "PostDetailViewController.h"
#import "PageDetailsController.h"
#import "WPImageView.h"
#import "WPImagePickerController.h"

@interface WPPhotosListViewController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
	IBOutlet UITableView *tableView;
	IBOutlet UITextField *countField;
	
	UIImage *currentChoosenImage; 
	WPImagePickerController *pickerController;

	id <WPPhotosListProtocol>  delegate;
	PostDetailViewController *postDetailViewController;
	PageDetailsController *pageDetailsController;

	BOOL isShowPhotoPickerActionSheet;
}

@property (nonatomic, assign) PostDetailViewController *postDetailViewController;
@property (nonatomic, assign) PageDetailsController *pageDetailsController;
@property (nonatomic, assign) id <WPPhotosListProtocol>  delegate;

@property (nonatomic, retain) UITableView *tableView;

- (IBAction)addPhotoFromLibraryAction:(id)sender;
- (IBAction)addPhotoFromCameraAction:(id)sender;
- (IBAction)showPhotoUploadScreen:(id)sender;
- (void)refreshData;

- (void)pickPhotoFromCamera:(id)sender;
- (void)pickPhotoFromPhotoLibrary:(id)sender;
- (void)useImage:(UIImage*)theImage;
- (void)showPhotoPickerActionSheet;

@end
