#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "PostMediaViewController.h"
#import "PostPreviewViewController.h"
#import "PostSettingsViewController.h"
#import "WordPressAppDelegate.h"
#import "WPProgressHUD.h"
#import "WPAddCategoryViewController.h"
#import "Post.h"
#import "UIDevice-hardware.h"
#import "WPKeyboardToolbar.h"

#define kSelectionsStatusContext ((void *)1000)
#define kSelectionsCategoriesContext ((void *)2000)

#define degreesToRadian(x) (M_PI * x / 180.0)

@class WPSegmentedSelectionTableViewController, PostSettingsViewController, PostPreviewViewController;

@interface EditPostViewController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,
UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPickerViewDelegate,UIPopoverControllerDelegate,WPKeyboardToolbarDelegate> {
    BOOL isShowPhotoPickerActionSheet;
    BOOL isTextViewEditing;
    BOOL dismiss;
    BOOL isEditing;
	BOOL editingDisabled;
    BOOL isNewCategory;
    BOOL editCustomFields;
	BOOL isLocalDraft;
    BOOL hasSaved, isVisible, isPublishing, isShowingKeyboard, isShowingLinkAlert, isExternalKeyboard;

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
    PostSettingsViewController *postSettingsController;
    PostMediaViewController *postMediaViewController;
	PostPreviewViewController *postPreviewViewController;
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
    WPKeyboardToolbar *editorToolbar;
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
@property (nonatomic, retain) UIButton *customFieldsEditButton;
@property (nonatomic, retain) CLLocation *initialLocation;
@property (nonatomic, retain) IBOutlet UIButton *locationButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *locationSpinner;
@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIView *contentView, *subView, *textViewContentView;;
@property (nonatomic, retain) IBOutlet UITextField *statusTextField, *titleTextField, *tagsTextField, *textViewPlaceHolderField;
@property (nonatomic, retain) IBOutlet UILabel *tagsLabel, *statusLabel, *categoriesLabel, *titleLabel;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *createCategoryBarButtonItem;
@property (nonatomic, retain) IBOutlet UIButton *hasLocation, *categoriesButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *photoButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *movieButton;
@property (nonatomic, retain) NSArray *statuses;
@property (nonatomic, retain) AbstractPost *apost;
@property (nonatomic, assign) Post *post;
@property (nonatomic, assign) EditPostMode editMode;
@property (nonatomic, assign) BOOL hasSaved, isVisible, isPublishing;
@property (readonly) BOOL hasChanges;
@property (readonly) CGRect normalTextFrame;
@property (nonatomic, retain) UIButton *undoButton, *redoButton;

- (id)initWithPost:(AbstractPost *)aPost;

// UI
- (void)refreshUIForCompose;
- (void)refreshUIForCurrentPost;
- (IBAction)endTextEnteringButtonAction:(id)sender;
- (void)endEditingAction:(id)sender;
- (void)refreshStatus;
- (void)positionTextView:(NSNotification *)keyboardInfo;
- (void)deviceDidRotate:(NSNotification *)notification;
- (void)resignTextView;
- (void)showLinkView;
- (void)disableInteraction;
- (void)savePost: (BOOL)upload;
- (void)dismissAlertViewKeyboard:(NSNotification *)notification;

// Media
- (void)insertMediaAbove:(NSNotification *)notification;
- (void)insertMediaBelow:(NSNotification *)notification;
- (void)removeMedia:(NSNotification *)notification;

- (IBAction)showAddNewCategoryView:(id)sender;

- (NSString *)validateNewLinkInfo:(NSString *)urlText;

- (BOOL)isAFreshlyCreatedDraft;
- (IBAction)switchToEdit;
- (IBAction)switchToSettings;
- (IBAction)switchToMedia;
- (IBAction)switchToPreview;
- (IBAction)addVideo:(id)sender;
- (IBAction)addPhoto:(id)sender;
- (IBAction)showCategories:(id)sender;
- (IBAction)touchTextView:(id)sender;
- (void)refreshButtons;
- (void)dismissEditView;

@end
