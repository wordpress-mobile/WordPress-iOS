#define kLabelTag				4096


#import <UIKit/UIKit.h>
#import "PostDetailViewController.h"
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
	
	IBOutlet UIBarButtonItem *newCategoryBarButtonItem;
	//IBOutlet UITableView *selectCustomFields;
	
	UIImage *currentChoosenImage; 
	WPImagePickerController *pickerController;
	
	WPSelectionTableViewController *selectionTableViewController;
   	WPSegmentedSelectionTableViewController *segmentedTableViewController;
	PostDetailViewController *postDetailViewController;
    WPNavigationLeftButtonView *leftView;
	CustomFieldsTableView *customFieldsTableView;
	BOOL isShowPhotoPickerActionSheet;
	BOOL isTextViewEditing;
	BOOL dismiss;
	BOOL isEditing;
	BOOL isNewCategory;
	BOOL editCustomFields;

    UITextField *infoText;
    UITextField *urlField;
	NSRange selectedLinkRange;
	NSMutableArray *bookMarksArray;
	UITextField *currentEditingTextField;
}

@property (nonatomic, assign)PostDetailViewController * postDetailViewController;
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

//will this work I wonder? shouldn't have to do this...
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

//will be called when auto save method is called.
- (void)updateValuesToCurrentPost;
-(void)showLinkView;


- (IBAction)showAddNewCategoryView:(id)sender;
- (IBAction)showCategoriesViewAction:(id)sender;
- (IBAction)showStatusViewAction:(id)sender;
- (IBAction)showCustomFieldsTableView:(id)sender;
- (NSString *)validateNewLinkInfo:(NSString *)urlText;

@end
