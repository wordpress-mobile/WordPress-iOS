#import <UIKit/UIKit.h>

@class PostDetailEditController, WPPostDetailPreviewController, WPSelectionTableViewController, WPPostSettingsController, WPPhotosListViewController, PostsListController;
@class WPNavigationLeftButtonView;
@interface PostDetailViewController : UIViewController <UITabBarDelegate, UIActionSheetDelegate, UITabBarControllerDelegate> {
	IBOutlet UITabBarController *tabController;
	UIBarButtonItem *saveButton;
	
	PostDetailEditController *postDetailEditController;
	WPPostDetailPreviewController *postPreviewController;
	WPPostSettingsController *postSettingsController;
	WPPhotosListViewController *photosListController;
	PostsListController *postsListController;
   	WPNavigationLeftButtonView *leftView;
	
	BOOL hasChanges;
	int mode;	//0 new, 1 edit, 2 autorecovery, 3 refresh
	
	NSTimer *autoSaveTimer;
}

@property (nonatomic, retain)	WPNavigationLeftButtonView *leftView;
@property (nonatomic, retain)	PostDetailEditController *postDetailEditController;
@property (nonatomic, retain)	WPPostDetailPreviewController *postPreviewController;
@property (nonatomic, retain)	WPPostSettingsController *postSettingsController;
@property (nonatomic, retain)	WPPhotosListViewController *photosListController;

@property (nonatomic, assign)	PostsListController *postsListController;

@property (nonatomic, readonly) UIBarButtonItem * saveButton;


@property (nonatomic)	BOOL hasChanges;
@property (nonatomic)	int mode;

@property (readonly) UITabBarController *tabController;

- (void)refreshUIForCompose;
- (void)refreshUIForCurrentPost;
- (void)updatePhotosBadge;
- (void)addAsyncPostOperation:(SEL)anOperation withArg:(id)anArg;
@end
