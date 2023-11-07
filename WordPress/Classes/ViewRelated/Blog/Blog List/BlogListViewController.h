@import UIKit;

@class Blog;
@class BlogListConfiguration;

@protocol ScenePresenter;

@interface BlogListViewController : UIViewController

@property (nonatomic, strong) Blog *selectedBlog;
@property (nonatomic, strong) BlogListConfiguration *configuration;
@property (nonatomic, strong, nullable) id<ScenePresenter> meScenePresenter;
@property (nonatomic, copy) void (^blogSelected)(BlogListViewController* blogListViewController, Blog* blog);

- (id)initWithConfiguration:(BlogListConfiguration *)configuration
           meScenePresenter:(nullable id<ScenePresenter>)meScenePresenter;
- (void)setSelectedBlog:(Blog *)selectedBlog animated:(BOOL)animated;
- (void)presentInterfaceForAddingNewSiteFrom:(UIView *)sourceView;
- (void)showLoading;
- (void)hideLoading;

@end
