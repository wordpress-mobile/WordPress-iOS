@import UIKit;

@class Blog;

@protocol ScenePresenter;

@interface BlogListViewController : UIViewController

@property (nonatomic, strong) Blog *selectedBlog;
@property (nonatomic, strong) id<ScenePresenter> meScenePresenter;
@property (nonatomic, copy) void (^blogSelected)(BlogListViewController* blogListViewController, Blog* blog);

- (id)initWithMeScenePresenter:(id<ScenePresenter>)meScenePresenter;
- (void)setSelectedBlog:(Blog *)selectedBlog animated:(BOOL)animated;

- (void)presentInterfaceForAddingNewSiteFrom:(UIView *)sourceView;

@end
