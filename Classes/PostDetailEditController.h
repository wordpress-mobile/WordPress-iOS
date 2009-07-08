#import <UIKit/UIKit.h>
#import "PostViewController.h"
#import "WPAddCategoryViewController.h"
#import "WPImagePickerController.h"
#import "CustomFieldsTableView.h"


#define kSelectionsStatusContext ((void*)1000)
#define kSelectionsCategoriesContext ((void*)2000)

@class WPSegmentedSelectionTableViewController;

@interface PostDetailEditController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,
	UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate> {
		
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
	IBOutlet UIButton *customFieldsEditButton;
	IBOutlet UITableView *tableViewForSelectingCustomFields;
	
	IBOutlet UIBarButtonItem *newCategoryBarButtonItem;
	
	UIImage *currentChoosenImage; 
	WPImagePickerController *pickerController;
	
	WPSelectionTableViewController *selectionTableViewController;
   	WPSegmentedSelectionTableViewController *segmentedTableViewController;
	PostViewController *postDetailViewController;
    WPNavigationLeftButtonView *leftView;
	CustomFieldsTableView *customFieldsTableView;
	BOOL isShowPhotoPickerActionSheet;
	BOOL isTextViewEditing;
	BOOL dismiss;
	BOOL isEditing;
	BOOL isNewCategory;
	BOOL editCustomFields;
	BOOL isCustomFieldsEnabledForThisPost;

    UITextField *infoText;
    UITextField *urlField;
	NSRange selectedLinkRange;
	NSMutableArray *bookMarksArray;
	UITextField *currentEditingTextField;
		
	//also for Custom Fields to move text view up and down appropriately
	NSUInteger originY;
}

@property (nonatomic, assign)PostViewController * postDetailViewController;
@property (nonatomic, retain) WPSelectionTableViewController *selectionTableViewController;
@property (nonatomic, retain) WPSegmentedSelectionTableViewController *segmentedTableViewController;
@property (nonatomic, retain) WPNavigationLeftButtonView *leftView;
@property (nonatomic, retain) CustomFieldsTableView *customFieldsTableView;
@property (nonatomic, retain) UITextField *infoText;
@property (nonatomic, retain) UITextField *urlField;
@property (nonatomic, retain) NSMutableArray *bookMarksArray;
@property (nonatomic) NSRange selectedLinkRange;
@property (nonatomic, assign) UITextField *currentEditingTextField;
@property (nonatomic, assign) BOOL isEditing;
@property (nonatomic, assign) BOOL editCustomFields;
@property (nonatomic, assign) BOOL isCustomFieldsEnabledForThisPost;
//@property (nonatomic, assign) NSUinteger originY;

@property (nonatomic, retain) UIButton *customFieldsEditButton;
//@property (nonatomic, retain) UITableView *selectCustomFields;


- (void)refreshUIForCompose;
- (void)refreshUIForCurrentPost;

- (void)setTextViewHeight:(float)height;


- (IBAction)showPhotoUploadScreen:(id)sender;
- (IBAction)endTextEnteringButtonAction:(id)sender;
- (void)pickPhotoFromCamera:(id)sender;
- (void)pickPhotoFromPhotoLibrary:(id)sender;
- (void)useImage:(UIImage*)theImage;
- (void)showPhotoPickerActionSheet;


- (void)endEditingAction:(id)sender;


//will be called when auto save method is called.
- (void)updateValuesToCurrentPost;
- (void)showLinkView;


- (IBAction)showAddNewCategoryView:(id)sender;
- (IBAction)showCategoriesViewAction:(id)sender;
- (IBAction)showStatusViewAction:(id)sender;
- (IBAction)showCustomFieldsTableView:(id)sender;
- (NSString *)validateNewLinkInfo:(NSString *)urlText;


// methods for dealing with custom fields
- (void) postionTextViewContentView;
- (BOOL) checkCustomFieldsMinusMetadata;

@end
