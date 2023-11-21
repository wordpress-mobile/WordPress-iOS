@import UIKit;

@class Blog;
@class BlogListConfiguration;

@protocol ScenePresenter;

NS_ASSUME_NONNULL_BEGIN

@interface BlogListViewController: UIViewController

@property (nullable, nonatomic, strong) Blog *selectedBlog;
@property (nonatomic, strong) BlogListConfiguration *configuration;
@property (nullable, nonatomic, strong) id<ScenePresenter> meScenePresenter;
@property (nullable, nonatomic, copy) void (^blogSelected)(BlogListViewController* blogListViewController, Blog* blog);

- (instancetype)initWithConfiguration:(BlogListConfiguration *)configuration
                     meScenePresenter:(nullable id<ScenePresenter>)meScenePresenter;
- (void)setSelectedBlog:(Blog *)selectedBlog animated:(BOOL)animated;
- (void)presentInterfaceForAddingNewSiteFrom:(UIView *)sourceView;
- (void)showLoading;
- (void)hideLoading;

@end

NS_ASSUME_NONNULL_END
