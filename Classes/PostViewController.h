#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <MapKit/MapKit.h>
#import "BlogDataManager.h"
#import "LocationController.h"
#import "PostMediaViewController.h"
#import "PostLocationViewController.h"
#import "WordPressAppDelegate.h"
#import "Post.h"
#import "TransparentToolbar.h"
#import "WPProgressHUD.h"

@class EditPostViewController, PostPreviewViewController, WPSelectionTableViewController, PostSettingsViewController, PostsViewController, CommentsViewController;
@class WPNavigationLeftButtonView, WPPublishOnEditController, CInvisibleToolbar, FlippingViewController;

@interface PostViewController : UIViewController <UITabBarDelegate, UIActionSheetDelegate, UITabBarControllerDelegate> {
	WordPressAppDelegate *appDelegate;

    IBOutlet EditPostViewController *postDetailEditController;
    PostPreviewViewController *postPreviewController;
    PostSettingsViewController *postSettingsController;
    PostMediaViewController *mediaViewController;
    CommentsViewController *commentsViewController;
    
    UIViewController *selectedViewController;
	WPProgressHUD *spinner;

    BOOL hasChanges, hasSaved, isVisible, isPublishing, isShowingKeyboard;
    EditPostMode editMode;
	NSURLConnection *connection;
	NSURLRequest *urlRequest;
	NSURLResponse *urlResponse;
	NSMutableData *payload;
	
	// iPad additions
	UIPopoverController *popoverController;
	UIPopoverController *photoPickerPopover;
	
    IBOutlet UIToolbar *toolbar;
	IBOutlet UIView *contentView;
	IBOutlet UIBarButtonItem *writeButton;
	IBOutlet UIBarButtonItem *settingsButton;
	IBOutlet UIBarButtonItem *previewButton;
	IBOutlet UIBarButtonItem *attachmentButton;
	IBOutlet UIBarButtonItem *photoButton;
	IBOutlet UIBarButtonItem *movieButton;
    IBOutlet UIImageView *tabPointer;
    
    UIView *currentView;
}

@property (nonatomic, assign) UIViewController *selectedViewController;
@property (nonatomic, assign) BOOL hasChanges, hasSaved, isVisible, isPublishing;
@property (nonatomic, assign) BOOL isShowingKeyboard;
@property (nonatomic, assign) EditPostMode editMode;
@property (readonly) UITabBarController *tabController;
@property (nonatomic, retain) AbstractPost *apost;
@property (nonatomic, assign) Post *post;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSURLRequest *urlRequest;
@property (nonatomic, retain) NSURLResponse *urlResponse;
@property (nonatomic, retain) NSMutableData *payload;
@property (nonatomic, retain) WordPressAppDelegate *appDelegate;
@property (nonatomic, retain) WPProgressHUD *spinner;

- (id)initWithPost:(AbstractPost *)aPost;
- (IBAction)cancelView:(id)sender;
- (void)refreshUIForCompose;
- (void)refreshUIForCurrentPost;
- (void)updatePhotosBadge;
- (UINavigationItem *)navigationItemForEditPost;
- (IBAction)editAction:(id)sender;
- (void)publish:(id)sender;
- (IBAction)locationAction:(id)sender;
- (void)dismissEditView;
- (void)verifyPublishSuccessful;
- (void)stop;
- (void)setMode:(EditPostMode)newMode;
- (void)refreshButtons;
- (void)showError;
- (IBAction)switchToEdit;
- (IBAction)switchToSettings;
- (IBAction)switchToPreview;
@end
