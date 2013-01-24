#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "PostMediaViewController.h"
#import "PostPreviewViewController.h"
#import "PostSettingsViewController.h"
#import "WordPressAppDelegate.h"
#import "WPProgressHUD.h"
#import "WPAddCategoryViewController.h"
#import "Post.h"
#import "WPKeyboardToolbar.h"

#define kSelectionsStatusContext ((void *)1000)
#define kSelectionsCategoriesContext ((void *)2000)

#define degreesToRadian(x) (M_PI * x / 180.0)

@class WPSegmentedSelectionTableViewController, PostSettingsViewController, PostPreviewViewController;

@interface EditPostViewController : UIViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,
UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIPickerViewDelegate,UIPopoverControllerDelegate,WPKeyboardToolbarDelegate> {
    BOOL isShowPhotoPickerActionSheet;
    BOOL isTextViewEditing;
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
    UIActionSheet *currentActionSheet;
	
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
    UITextField *__weak currentEditingTextField;
    NSUInteger originY;
	NSUInteger textViewHeightForRotation;
	CLLocation *initialLocation;
	NSArray *statuses;
        
    UIView *currentView;
    WPKeyboardToolbar *editorToolbar;
}

@property (nonatomic, strong) WPSelectionTableViewController *selectionTableViewController;
@property (nonatomic, strong) WPSegmentedSelectionTableViewController *segmentedTableViewController;
@property (nonatomic, strong) UITextField *infoText;
@property (nonatomic, strong) UITextField *urlField;
@property (nonatomic, strong) NSMutableArray *bookMarksArray;
@property (nonatomic) NSRange selectedLinkRange;
@property (nonatomic, weak) UITextField *currentEditingTextField;
@property (nonatomic, assign) BOOL isEditing, editingDisabled, editCustomFields;
@property (nonatomic, assign) BOOL isLocalDraft;
@property (nonatomic, strong) UIButton *customFieldsEditButton;
@property (nonatomic, strong) CLLocation *initialLocation;
@property (nonatomic, strong) IBOutlet UIButton *locationButton;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *locationSpinner;
@property (nonatomic, strong) IBOutlet UITextView *textView;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) IBOutlet UIView *contentView, *subView, *textViewContentView;;
@property (nonatomic, strong) IBOutlet UITextField *statusTextField, *titleTextField, *tagsTextField, *textViewPlaceHolderField;
@property (nonatomic, strong) IBOutlet UILabel *tagsLabel, *statusLabel, *categoriesLabel, *titleLabel;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *createCategoryBarButtonItem;
@property (nonatomic, strong) IBOutlet UIButton *hasLocation, *categoriesButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *photoButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *movieButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *settingsButton;
@property (nonatomic, strong) NSArray *statuses;
@property (nonatomic, strong) AbstractPost *apost;
@property (nonatomic, weak) Post *post;
@property (nonatomic, assign) EditPostMode editMode;
@property (nonatomic, assign) BOOL hasSaved, isVisible, isPublishing;
@property (readonly) BOOL hasChanges;
@property (readonly) CGRect normalTextFrame;
@property (nonatomic, strong) UIButton *undoButton, *redoButton;
@property (nonatomic, strong) UIActionSheet *currentActionSheet;
@property (nonatomic, strong) PostSettingsViewController *postSettingsViewController;
@property (nonatomic, strong) PostMediaViewController *postMediaViewController;

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
- (void)textFieldDidChange: (id)sender;
- (NSInteger)pointerPositionForAttachmentsTab;
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
- (NSString *)editorTitle;

- (BOOL)canAutosaveRemotely;
- (BOOL)autosaveRemoteWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;


@end
