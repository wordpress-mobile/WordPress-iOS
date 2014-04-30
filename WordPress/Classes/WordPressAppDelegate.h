@class Reachability;
@class DDFileLogger;
@class ReaderPostsViewController;
@class BlogListViewController;
@class AbstractPost;
@class Blog;

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) UITabBarController *tabBarController;
@property (nonatomic, strong) ReaderPostsViewController *readerPostsViewController;
@property (nonatomic, strong) BlogListViewController *blogListViewController;
@property (strong, nonatomic, readonly) DDFileLogger *fileLogger;
@property (nonatomic, strong) Reachability *internetReachability, *wpcomReachability;
@property (nonatomic, assign) BOOL connectionAvailable, wpcomAvailable;

+ (WordPressAppDelegate *)sharedWordPressApplicationDelegate;

///---------------------------
/// @name User agent switching
///---------------------------
- (void)useDefaultUserAgent;
- (void)useAppUserAgent;
- (NSString *)applicationUserAgent;

///-----------------------
/// @name Tab bar controls
///-----------------------
- (void)showNotificationsTab;
- (void)showBlogListTab;
- (void)showReaderTab;
- (void)showMeTab;
- (void)showPostTab;
- (void)switchTabToPostsListForPost:(AbstractPost *)post;
- (BOOL)isNavigatingMeTab;

///-----------
/// @name NUX
///-----------
- (void)showWelcomeScreenIfNeededAnimated:(BOOL)animated;

@end
