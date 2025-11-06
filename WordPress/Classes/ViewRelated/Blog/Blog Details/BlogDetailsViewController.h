#import <UIKit/UIKit.h>

@class Blog;
@class BlogDetailHeaderView;
@class IntrinsicTableView;
@class MeViewController;
@class ApplicationPasswordAuthenticationInfo;
@class BlogDetailsTableViewModel;
@protocol BlogDetailHeader;

@protocol ScenePresenter;

@protocol BlogDetailsPresentationDelegate
- (void)presentBlogDetailsViewController:(UIViewController * __nonnull)viewController;
@end

@interface BlogDetailsViewController : UIViewController <UIViewControllerTransitioningDelegate, UIAdaptivePresentationControllerDelegate>

@property (nonatomic, strong, nonnull) Blog * blog;
@property (nonatomic, strong, readwrite) UITableView * _Nonnull tableView;
@property (nonatomic, strong, readonly) BlogDetailsTableViewModel *tableViewModel;
@property (nonatomic) BOOL isScrollEnabled;
@property (nonatomic, weak, nullable) id<BlogDetailsPresentationDelegate> presentationDelegate;

/// A new display mode for the displaying it as part of the site menu.
@property (nonatomic) BOOL isSidebarModeEnabled;

@property (nonatomic, weak) UIViewController *presentedSiteSettingsViewController;

- (id _Nonnull)init;
- (void)reloadTableViewPreservingSelection;
- (void)configureTableViewData;

- (void)switchToBlog:(nonnull Blog *)blog;
- (void)showInitialDetailsForBlog;
- (void)updateTableView:(nullable void(^)(void))completion;
- (void)preloadMetadata;
- (void)pulledToRefreshWith:(nonnull UIRefreshControl *)refreshControl onCompletion:(nullable void(^)(void))completion;

- (void)showRemoveSiteAlert;

@end
