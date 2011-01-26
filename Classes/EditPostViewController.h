#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "PostMediaViewController.h"
#import "PostSettingsViewController.h"
#import "PostLocationViewController.h"
#import "WordPressAppDelegate.h"
#import "WPProgressHUD.h"
#import "WPAddCategoryViewController.h"
#import "Post.h"

#define kSelectionsStatusContext ((void *)1000)
#define kSelectionsCategoriesContext ((void *)2000)

#define degreesToRadian(x) (M_PI * x / 180.0)

@class WPSegmentedSelectionTableViewController, PostSettingsViewController;

@interface EditPostViewController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,
UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPickerViewDelegate,UIPopoverControllerDelegate> {
    BOOL isShowPhotoPickerActionSheet;
    BOOL isTextViewEditing;
    BOOL dismiss;
    BOOL isEditing;
	BOOL editingDisabled;
    BOOL isNewCategory;
    BOOL editCustomFields;
	BOOL isLocalDraft;
    BOOL hasSaved, isVisible, isPublishing, isShowingKeyboard;
	
	CGRect normalTextFrame;
	
    IBOutlet UITextView *textView;
    IBOutlet UITextField *titleTextField;
    IBOutlet UITextField *tagsTextField;
    IBOutlet UIView *subView;
    IBOutlet UILabel *titleLabel;
    IBOutlet UITextField *textViewPlaceHolderField;
    IBOutlet UIToolbar *toolbar;
	IBOutlet UIView *contentView;
	IBOutlet UIView *editView;
	IBOutlet UIBarButtonItem *writeButton;
	IBOutlet UIBarButtonItem *settingsButton;
	IBOutlet UIBarButtonItem *previewButton;
	IBOutlet UIBarButtonItem *attachmentButton;
	IBOutlet UIBarButtonItem *photoButton;
	IBOutlet UIBarButtonItem *movieButton;
    IBOutlet UIImageView *tabPointer;
    
	
    WPSelectionTableViewController *selectionTableViewController;
    WPSegmentedSelectionTableViewController *segmentedTableViewController;
	LocationController *locationController;
    PostSettingsViewController *postSettingsController;
    WPProgressHUD *spinner;
	
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
        
    UIView *currentView;
}

@property (nonatomic, retain) WPSelectionTableViewController *selectionTableViewController;
@property (nonatomic, retain) WPSegmentedSelectionTableViewController *segmentedTableViewController;
@property (nonatomic, retain) UITextField *infoText;
@property (nonatomic, retain) UITextField *urlField;
@property (nonatomic, retain) NSMutableArray *bookMarksArray;
@property (nonatomic) NSRange selectedLinkRange;
@property (nonatomic, assign) UITextField *currentEditingTextField;
@property (nonatomic, assign) BOOL isEditing, editingDisabled, editCustomFields;
@property (nonatomic, assign) BOOL isLocalDraft;
@property (nonatomic, assign) CGRect normalTextFrame;
@property (nonatomic, retain) UIButton *customFieldsEditButton;
@property (nonatomic, retain) CLLocation *initialLocation;
@property (nonatomic, retain) IBOutlet UIButton *locationButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *locationSpinner;
@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIView *contentView, *subView, *textViewContentView;;
@property (nonatomic, retain) IBOutlet UITextField *statusTextField, *categoriesTextField, *titleTextField, *tagsTextField, *textViewPlaceHolderField;
@property (nonatomic, retain) IBOutlet UILabel *tagsLabel, *statusLabel, *categoriesLabel, *titleLabel;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *newCategoryBarButtonItem;
@property (nonatomic, retain) NSArray *statuses;
@property (nonatomic, retain) AbstractPost *apost;
@property (nonatomic, assign) Post *post;
@property (nonatomic, assign) EditPostMode editMode;
@property (nonatomic, assign) BOOL hasSaved, isVisible, isPublishing;
@property (readonly) BOOL hasChanges;

- (id)initWithPost:(AbstractPost *)aPost;

// UI
- (void)refreshUIForCompose;
- (void)refreshUIForCurrentPost;
- (IBAction)endTextEnteringButtonAction:(id)sender;
- (void)endEditingAction:(id)sender;
- (void)refreshStatus;
- (void)positionTextView:(NSDictionary *)keyboardInfo;
- (void)deviceDidRotate:(NSNotification *)notification;
- (void)resignTextView;
- (void)showLinkView;
- (void)disableInteraction;

// Media
- (void)insertMediaAbove:(NSNotification *)notification;
- (void)insertMediaBelow:(NSNotification *)notification;
- (void)removeMedia:(NSNotification *)notification;

// Categories
- (IBAction)showAddNewCategoryView:(id)sender;
- (IBAction)showCategoriesViewAction:(id)sender;
- (IBAction)showStatusViewAction:(id)sender;
- (NSString *)validateNewLinkInfo:(NSString *)urlText;
- (BOOL)checkCustomFieldsMinusMetadata;

// Location
- (IBAction)showLocationMapView:(id)sender;
- (BOOL)isPostPublished;
- (BOOL)isPostGeotagged;
- (CLLocation *)getPostLocation;

- (IBAction)switchToEdit;
- (IBAction)switchToSettings;
- (void)refreshButtons;
- (void)dismissEditView;

@end
