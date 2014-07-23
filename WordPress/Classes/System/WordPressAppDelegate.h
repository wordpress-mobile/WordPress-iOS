@class Reachability;
@class DDFileLogger;
@class ReaderPostsViewController;
@class BlogListViewController;
@class AbstractPost;
@class Simperium;
@class Blog;

// Tab index constants
extern NSInteger const kReaderTabIndex;
extern NSInteger const kNotificationsTabIndex;
extern NSInteger const kMeTabIndex;

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) UINavigationController *navigationController;
@property (nonatomic, strong) UITabBarController *tabBarController;
@property (nonatomic, strong) ReaderPostsViewController *readerPostsViewController;
@property (nonatomic, strong) BlogListViewController *blogListViewController;
@property (nonatomic, strong) Reachability *internetReachability;
@property (nonatomic, strong) Reachability *wpcomReachability;
@property (nonatomic, assign) BOOL connectionAvailable;
@property (nonatomic, assign) BOOL wpcomAvailable;
@property (nonatomic, strong, readonly) DDFileLogger *fileLogger;
@property (nonatomic, strong, readonly) Simperium *simperium;

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
- (void)showTabForIndex: (NSInteger)tabIndex;
- (void)showPostTab;
- (void)switchTabToPostsListForPost:(AbstractPost *)post;
- (BOOL)isNavigatingMeTab;

///-----------
/// @name NUX
///-----------
- (void)showWelcomeScreenIfNeededAnimated:(BOOL)animated;

@end
