#import <UIKit/UIKit.h>
#import "WPPhotoViewController.h"
#import "PostDetailViewController.h"
#import "WPImageView.h"

@interface WPPhotosListViewController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
	IBOutlet UITableView *tableView;
	IBOutlet UITextField *countField;
	
	UIImage *currentChoosenImage; 
	UIImagePickerController *pickerController;

	PostDetailViewController *postDetailViewController;

	BOOL isShowPhotoPickerActionSheet;
}

@property (nonatomic, assign) PostDetailViewController *postDetailViewController;
@property (nonatomic, assign) UITableView *tableView;

- (IBAction)addPhotoFromLibraryAction:(id)sender;
- (IBAction)addPhotoFromCameraAction:(id)sender;
- (IBAction)showPhotoUploadScreen:(id)sender;
- (void)refreshData;

- (void)pickPhotoFromCamera:(id)sender;
- (void)pickPhotoFromPhotoLibrary:(id)sender;
- (void)useImage:(UIImage*)theImage;
- (void)showPhotoPickerActionSheet;

@end
