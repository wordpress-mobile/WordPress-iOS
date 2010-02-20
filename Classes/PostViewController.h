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

@class EditPostViewController, PostPreviewViewController, WPSelectionTableViewController, PostSettingsViewController, WPPhotosListViewController, PostsViewController, CommentsViewController;
@class WPNavigationLeftButtonView;
@class CustomFieldsDetailController, WPPublishOnEditController;

@interface PostViewController : UIViewController <UITabBarDelegate, UIActionSheetDelegate, UITabBarControllerDelegate, WPPhotosListProtocol> {
    IBOutlet UITabBarController *tabController;
	//IBOutlet UITabBar *tabBar;
    IBOutlet UIView *photoEditingStatusView;
    UIBarButtonItem *saveButton;

    EditPostViewController *postDetailEditController;
    PostPreviewViewController *postPreviewController;
    PostSettingsViewController *postSettingsController;
    WPPhotosListViewController *photosListController;
    PostsViewController *postsListController;
    CommentsViewController *commentsViewController;
    
    UIViewController *selectedViewController;
    WPNavigationLeftButtonView *leftView;
    CustomFieldsDetailController *customFieldsDetailController;

    BOOL hasChanges, isVisible;
    int mode;   //0 new, 1 edit, 2 autorecovery, 3 refresh
    NSTimer *autoSaveTimer;
}

@property (nonatomic, retain)   WPNavigationLeftButtonView *leftView;
@property (nonatomic, retain)   EditPostViewController *postDetailEditController;
@property (nonatomic, retain)   PostPreviewViewController *postPreviewController;
@property (nonatomic, retain)   PostSettingsViewController *postSettingsController;
@property (nonatomic, retain)   WPPhotosListViewController *photosListController;
@property (nonatomic, retain)   CommentsViewController *commentsViewController;
@property (nonatomic, retain)   CustomFieldsDetailController *customFieldsDetailController;
@property (nonatomic, assign)   PostsViewController *postsListController;
@property (nonatomic, assign)   UIViewController *selectedViewController;
@property (nonatomic, readonly) UIBarButtonItem *saveButton;
@property (nonatomic)   BOOL hasChanges, isVisible;
@property (nonatomic)   int mode;
@property (readonly) UITabBarController *tabController;
//@property (readonly) UITabBar *tabBar;

- (IBAction)cancelView:(id)sender;
- (void)refreshUIForCompose;
- (void)refreshUIForCurrentPost;
- (void)updatePhotosBadge;

@end
