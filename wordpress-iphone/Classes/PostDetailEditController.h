#import <UIKit/UIKit.h>
#import "PostDetailViewController.h"
#import "WPAddCategoryViewController.h"

#define kSelectionsStatusContext ((void*)1000)
#define kSelectionsCategoriesContext ((void*)2000)

@interface PostDetailEditController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
	IBOutlet UITextView *textView;
	IBOutlet UITextField *titleTextField;
	IBOutlet UITextField *tagsTextField;

	IBOutlet UIView *contentView;
	IBOutlet UIView *subView;
	IBOutlet UITextField *statusTextField;
	IBOutlet UITextField *categoriesTextField;
	IBOutlet UILabel *tagsLabel;
	IBOutlet UILabel *statusLabel;
	IBOutlet UILabel *categoriesLabel;
	IBOutlet UILabel *titleLabel;
	IBOutlet UIView *textViewContentView;
	IBOutlet UITextField *textViewPlaceHolderField;
	
	IBOutlet UIBarButtonItem *newCategoryBarButtonItem;

	UIImage *currentChoosenImage; 
	UIImagePickerController *pickerController;

	WPSelectionTableViewController *selectionTableViewController;
	PostDetailViewController *postDetailViewController;

	BOOL isShowPhotoPickerActionSheet;
	BOOL isTextViewEditing;
}

@property (nonatomic, assign)PostDetailViewController * postDetailViewController;
@property (nonatomic, retain) WPSelectionTableViewController *selectionTableViewController;

- (void)refreshUIForCompose;
- (void)refreshUIForCurrentPost;

- (IBAction)showPhotoUploadScreen:(id)sender;
- (IBAction)endTextEnteringButtonAction:(id)sender;
- (void)pickPhotoFromCamera:(id)sender;
- (void)pickPhotoFromPhotoLibrary:(id)sender;
- (void)useImage:(UIImage*)theImage;
- (void)showPhotoPickerActionSheet;


- (void)endEditingAction:(id)sender;

//will be called when auto save method is called.
- (void)updateValuesToCurrentPost;

- (IBAction)showAddNewCategoryView:(id)sender;
- (IBAction)showCategoriesViewAction:(id)sender;
- (IBAction)showStatusViewAction:(id)sender;

@end
