#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "PostViewController.h"
#import "WPAddCategoryViewController.h"
#import "Post.h"

#define kSelectionsStatusContext ((void *)1000)
#define kSelectionsCategoriesContext ((void *)2000)

#define degreesToRadian(x) (M_PI * x / 180.0)

@class WPSegmentedSelectionTableViewController;

@interface EditPostViewController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,
UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPickerViewDelegate,UIPopoverControllerDelegate> {
    BOOL isShowPhotoPickerActionSheet;
    BOOL isTextViewEditing;
    BOOL dismiss;
    BOOL isEditing;
	BOOL editingDisabled;
    BOOL isNewCategory;
    BOOL editCustomFields;
    BOOL isCustomFieldsEnabledForThisPost;
	BOOL isLocalDraft;
	
	CGRect normalTextFrame;
	
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
    IBOutlet UIButton *customFieldsEditButton, *autosaveButton;
	IBOutlet UIButton *locationButton;
	IBOutlet UIActivityIndicatorView *locationSpinner;
    IBOutlet UIBarButtonItem *newCategoryBarButtonItem;
	
    WPSelectionTableViewController *selectionTableViewController;
    WPSegmentedSelectionTableViewController *segmentedTableViewController;
    PostViewController *postDetailViewController;
    WPNavigationLeftButtonView *leftView;
	LocationController *locationController;
	
    UIImage *currentChoosenImage;
    UITextField *infoText;
    UITextField *urlField;
    NSRange selectedLinkRange;
    NSMutableArray *bookMarksArray;
    UITextField *currentEditingTextField;
    NSUInteger originY;
	NSUInteger textViewHeightForRotation;
	CLLocation *initialLocation;
	NSArray *statuses;
    NSMutableArray *selectedCategories;
}

@property (nonatomic, assign) PostViewController *postDetailViewController;
@property (nonatomic, retain) WPSelectionTableViewController *selectionTableViewController;
@property (nonatomic, retain) WPSegmentedSelectionTableViewController *segmentedTableViewController;
@property (nonatomic, retain) WPNavigationLeftButtonView *leftView;
@property (nonatomic, retain) UITextField *infoText;
@property (nonatomic, retain) UITextField *urlField;
@property (nonatomic, retain) NSMutableArray *bookMarksArray;
@property (nonatomic) NSRange selectedLinkRange;
@property (nonatomic, assign) UITextField *currentEditingTextField;
@property (nonatomic, assign) BOOL isEditing, editingDisabled, editCustomFields, isCustomFieldsEnabledForThisPost;
@property (nonatomic, assign) BOOL isLocalDraft;
@property (nonatomic, assign) CGRect normalTextFrame;
@property (nonatomic, retain) UIButton *customFieldsEditButton, *autosaveButton;
@property (nonatomic, retain) CLLocation *initialLocation;
@property (nonatomic, retain) IBOutlet UIButton *locationButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *locationSpinner;
@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UIView *contentView, *subView, *textViewContentView;;
@property (nonatomic, retain) IBOutlet UITextField *statusTextField, *categoriesTextField, *titleTextField, *tagsTextField, *textViewPlaceHolderField;
@property (nonatomic, retain) IBOutlet UILabel *tagsLabel, *statusLabel, *categoriesLabel, *titleLabel;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *newCategoryBarButtonItem;
@property (nonatomic, retain) NSArray *statuses;
@property (nonatomic, retain) NSMutableArray *selectedCategories;

// UI
- (void)refreshUIForCompose;
- (void)refreshUIForCurrentPost;
- (void)refreshCurrentPostForUI;
- (IBAction)endTextEnteringButtonAction:(id)sender;
- (void)endEditingAction:(id)sender;
- (void)refreshCategory;
- (void)syncStatuses;
- (void)refreshStatus;
- (void)syncCategoriesAndStatuses;
- (void)positionTextView:(NSDictionary *)keyboardInfo;
- (void)deviceDidRotate:(NSNotification *)notification;
- (void)resignTextView;

// Media
- (void)insertMediaAbove:(NSNotification *)notification;
- (void)insertMediaBelow:(NSNotification *)notification;
- (void)removeMedia:(NSNotification *)notification;

// Autosave
- (void)updateValuesToCurrentPost;
- (void)showLinkView;
- (void)disableInteraction;
- (void)preserveUnsavedPost;
- (void)clearUnsavedPost;
- (void)restoreUnsavedPost;
- (void)showAutosaveButton;
- (void)hideAutosaveButton;
- (IBAction)showAutosaves:(id)sender;

// Categories
- (void)syncCategories;
- (IBAction)showAddNewCategoryView:(id)sender;
- (IBAction)showCategoriesViewAction:(id)sender;
- (IBAction)showStatusViewAction:(id)sender;
- (NSString *)validateNewLinkInfo:(NSString *)urlText;
- (BOOL)checkCustomFieldsMinusMetadata;
- (NSString *)selectedCategoriesText;

// Location
- (IBAction)showLocationMapView:(id)sender;
- (BOOL)isPostPublished;
- (BOOL)isPostGeotagged;
- (CLLocation *)getPostLocation;


@end
