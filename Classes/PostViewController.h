#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "WPPhotosListProtocol.h"
#import "BlogDataManager.h"
#import "LocationController.h"
#import "PostLocationViewController.h"

//refactoring "mode"
#define newPost 0
#define editPost 1
#define autorecoverPost 2
#define refreshPost 3

@class EditPostViewController, PostPreviewViewController, WPSelectionTableViewController, PostSettingsViewController, PostsViewController, CommentsViewController;
@class WPPhotosListViewController;
@class MediaViewController;
@class WPNavigationLeftButtonView;
@class CustomFieldsDetailController, WPPublishOnEditController;
@class CInvisibleToolbar;
@class FlippingViewController;

@interface PostViewController : UIViewController <UITabBarDelegate, UIActionSheetDelegate, UITabBarControllerDelegate, WPPhotosListProtocol> {
    IBOutlet UITabBarController *tabController;
	//IBOutlet UITabBar *tabBar;
    IBOutlet UIView *photoEditingStatusView;
    UIBarButtonItem *saveButton;

	EditPostViewController *postDetailViewController;
    EditPostViewController *postDetailEditController;
    PostPreviewViewController *postPreviewController;
    PostSettingsViewController *postSettingsController;
    WPPhotosListViewController *photosListController;
	MediaViewController *mediaController;
    PostsViewController *postsListController;
    CommentsViewController *commentsViewController;
    
    UIViewController *selectedViewController;
    WPNavigationLeftButtonView *leftView;
    CustomFieldsDetailController *customFieldsDetailController;

    BOOL hasChanges, isVisible;
    int mode;   //0 new, 1 edit, 2 autorecovery, 3 refresh
    NSTimer *autoSaveTimer;
	
	// iPad additions
	IBOutlet UIToolbar *toolbar;
	IBOutlet UIView *contentView;
	UIPopoverController *popoverController;
	UIPopoverController *photoPickerPopover;
	
	IBOutlet UIBarButtonItem *commentsButton;
	IBOutlet UIBarButtonItem *photosButton;
	IBOutlet UIBarButtonItem *settingsButton;
	
	IBOutlet UIToolbar *editToolbar;
	IBOutlet UIToolbar *previewToolbar;
	IBOutlet UIBarButtonItem *cancelEditButton;
	FlippingViewController *editModalViewController;
}

@property (nonatomic, retain) WPNavigationLeftButtonView *leftView;
@property (nonatomic, retain) EditPostViewController *postDetailViewController;
@property (nonatomic, retain) EditPostViewController *postDetailEditController;
@property (nonatomic, retain) PostPreviewViewController *postPreviewController;
@property (nonatomic, retain) PostSettingsViewController *postSettingsController;
@property (nonatomic, retain) WPPhotosListViewController *photosListController;
@property (nonatomic, retain) MediaViewController *mediaController;
@property (nonatomic, retain) CommentsViewController *commentsViewController;
@property (nonatomic, retain) CustomFieldsDetailController *customFieldsDetailController;
@property (nonatomic, assign) PostsViewController *postsListController;
@property (nonatomic, assign) UIViewController *selectedViewController;
@property (nonatomic, readonly) UIBarButtonItem *saveButton;
@property (nonatomic) BOOL hasChanges, isVisible;
@property (nonatomic) int mode;
@property (readonly) UITabBarController *tabController;
@property (nonatomic, retain) IBOutlet UIToolbar *toolbar;
@property (nonatomic, retain) IBOutlet UIView *contentView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *commentsButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *photosButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *settingsButton;
@property (nonatomic, retain) IBOutlet UIToolbar *editToolbar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *cancelEditButton;
@property (nonatomic, retain) FlippingViewController *editModalViewController;
@property (nonatomic, assign) UIBarButtonItem *leftBarButtonItemForEditPost;
@property (nonatomic, assign) UIBarButtonItem *rightBarButtonItemForEditPost;

- (IBAction)cancelView:(id)sender;
- (void)refreshUIForCompose;
- (void)refreshUIForCurrentPost;
- (void)updatePhotosBadge;
- (UINavigationItem *)navigationItemForEditPost;
- (IBAction)commentsAction:(id)sender;
- (IBAction)editAction:(id)sender;
- (IBAction)picturesAction:(id)sender;
- (IBAction)settingsAction:(id)sender;
- (IBAction)locationAction:(id)sender;
- (IBAction)addPhotoAction:(id)sender;
- (IBAction)previewAction:(id)sender;
- (IBAction)previewEditAction:(id)sender;
- (IBAction)previewPublishAction:(id)sender;
- (IBAction)newPostAction:(id)sender;
- (void)dismissEditView;

@end
