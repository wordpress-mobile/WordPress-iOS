#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <MapKit/MapKit.h>
#import "BlogDataManager.h"
#import "LocationController.h"
#import "PostMediaViewController.h"
#import "PostLocationViewController.h"
#import "WordPressAppDelegate.h"
#import "Post.h"
#import "AutosaveViewController.h"
#import "AutosaveManager.h"
#import "DraftManager.h"
#import "TransparentToolbar.h"

@class EditPostViewController, PostPreviewViewController, WPSelectionTableViewController, PostSettingsViewController, PostsViewController, CommentsViewController;
@class WPNavigationLeftButtonView;
@class CustomFieldsDetailController, WPPublishOnEditController;
@class CInvisibleToolbar;
@class FlippingViewController;

@interface PostViewController : UIViewController <UITabBarDelegate, UIActionSheetDelegate, UITabBarControllerDelegate> {
    IBOutlet UITabBarController *tabController;

	EditPostViewController *postDetailViewController;
    EditPostViewController *postDetailEditController;
    PostPreviewViewController *postPreviewController;
    PostSettingsViewController *postSettingsController;
    PostMediaViewController *mediaViewController;
    PostsViewController *postsListController;
    CommentsViewController *commentsViewController;
	Post *post;
	AutosaveManager *autosaveManager;
	DraftManager *draftManager;
    
    UIViewController *selectedViewController;
    WPNavigationLeftButtonView *leftView;
    CustomFieldsDetailController *customFieldsDetailController;

    BOOL hasChanges, hasSaved, isVisible, didConvertDraftToPublished, isShowingAutosaves;
    EditPostMode editMode;
    NSTimer *autoSaveTimer;
	NSURLConnection *connection;
	NSURLRequest *urlRequest;
	NSURLResponse *urlResponse;
	NSMutableData *payload;
	
	// iPad additions
	IBOutlet UIToolbar *toolbar;
	IBOutlet UIView *contentView;
	UIPopoverController *popoverController;
	UIPopoverController *photoPickerPopover;
	
	IBOutlet UIBarButtonItem *commentsButton;
	IBOutlet UIBarButtonItem *photosButton;
	IBOutlet UIBarButtonItem *settingsButton;
	IBOutlet UIButton *autosaveButton;
	IBOutlet UIToolbar *editToolbar;
	IBOutlet UIToolbar *previewToolbar;
	IBOutlet UIBarButtonItem *cancelEditButton;
	IBOutlet AutosaveViewController *autosaveView;
	FlippingViewController *editModalViewController;
	
	WordPressAppDelegate *appDelegate;
}

@property (nonatomic, retain) WPNavigationLeftButtonView *leftView;
@property (nonatomic, retain) EditPostViewController *postDetailViewController;
@property (nonatomic, retain) EditPostViewController *postDetailEditController;
@property (nonatomic, retain) PostPreviewViewController *postPreviewController;
@property (nonatomic, retain) PostSettingsViewController *postSettingsController;
@property (nonatomic, retain) PostMediaViewController *mediaViewController;
@property (nonatomic, retain) CommentsViewController *commentsViewController;
@property (nonatomic, retain) CustomFieldsDetailController *customFieldsDetailController;
@property (nonatomic, assign) PostsViewController *postsListController;
@property (nonatomic, assign) UIViewController *selectedViewController;
@property (nonatomic, assign) BOOL hasChanges, hasSaved, isVisible, didConvertDraftToPublished, isShowingAutosaves;
@property (nonatomic, assign) EditPostMode editMode;
@property (readonly) UITabBarController *tabController;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *commentsButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *photosButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *settingsButton;
@property (nonatomic, retain) IBOutlet UIToolbar *editToolbar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *cancelEditButton;
@property (nonatomic, retain) IBOutlet UIButton *autosaveButton;
@property (nonatomic, retain) FlippingViewController *editModalViewController;
@property (nonatomic, assign) UIBarButtonItem *leftBarButtonItemForEditPost;
@property (nonatomic, retain) Post *post;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSURLRequest *urlRequest;
@property (nonatomic, retain) NSURLResponse *urlResponse;
@property (nonatomic, retain) NSMutableData *payload;
@property (nonatomic, retain) WordPressAppDelegate *appDelegate;
@property (nonatomic, retain) IBOutlet AutosaveViewController *autosaveView;
@property (nonatomic, retain) AutosaveManager *autosaveManager;
@property (nonatomic, retain) DraftManager *draftManager;

- (IBAction)cancelView:(id)sender;
- (void)refreshUIForCompose;
- (void)refreshUIForCurrentPost;
- (void)updatePhotosBadge;
- (UINavigationItem *)navigationItemForEditPost;
- (IBAction)commentsAction:(id)sender;
- (IBAction)editAction:(id)sender;
- (void)publish:(id)sender;
- (IBAction)saveAsDraft;
- (void)saveAsDraft:(BOOL)andDiscard;
- (IBAction)picturesAction:(id)sender;
- (IBAction)settingsAction:(id)sender;
- (IBAction)locationAction:(id)sender;
- (IBAction)addPhotoAction:(id)sender;
- (IBAction)previewAction:(id)sender;
- (IBAction)mediaAction:(id)sender;
- (IBAction)previewEditAction:(id)sender;
- (IBAction)previewPublishAction:(id)sender;
- (IBAction)newPostAction:(id)sender;
- (void)dismissEditView;
- (void)verifyPublishSuccessful;
- (void)stop;
- (IBAction)toggleAutosaves:(id)sender;
- (void)showAutosaveButton;
- (void)hideAutosaveButton;
- (void)checkAutosaves;
- (void)restoreFromAutosave:(NSNotification *)notification;
- (void)showAutosaves;
- (void)hideAutosaves;
- (void)setMode:(EditPostMode)newMode;
- (void)refreshButtons;

@end
