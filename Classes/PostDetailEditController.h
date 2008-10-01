#import <UIKit/UIKit.h>
#import "PostDetailViewController.h"
#import "WPAddCategoryViewController.h"
#import "WPImagePickerController.h"

#define kSelectionsStatusContext ((void*)1000)
#define kSelectionsCategoriesContext ((void*)2000)

@class WPSegmentedSelectionTableViewController;

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
	WPImagePickerController *pickerController;
	
	WPSelectionTableViewController *selectionTableViewController;
   	WPSegmentedSelectionTableViewController *segmentedTableViewController;
	PostDetailViewController *postDetailViewController;
    WPNavigationLeftButtonView *leftView;
	BOOL isShowPhotoPickerActionSheet;
	BOOL isTextViewEditing;
    UITextField *infoText;
    UITextField *urlField;
	NSRange selectedLinkRange;
	NSMutableArray *bookMarksArray;
}

@property (nonatomic, assign)PostDetailViewController * postDetailViewController;
@property (nonatomic, retain) WPSelectionTableViewController *selectionTableViewController;
@property (nonatomic, retain) WPSegmentedSelectionTableViewController *segmentedTableViewController;
@property (nonatomic, retain) WPNavigationLeftButtonView *leftView;
@property (nonatomic, retain) UITextField *infoText;
@property (nonatomic, retain) UITextField *urlField;
@property (nonatomic, retain) NSMutableArray *bookMarksArray;
@property (nonatomic) NSRange selectedLinkRange;

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
-(void)showLinkView;


- (IBAction)showAddNewCategoryView:(id)sender;
- (IBAction)showCategoriesViewAction:(id)sender;
- (IBAction)showStatusViewAction:(id)sender;
- (NSString *)validateNewLinkInfo:(NSString *)urlText;

@end
