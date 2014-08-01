@class Reachability;
@class DDFileLogger;
@class ReaderPostsViewController;
@class BlogListViewController;
@class NotificationsViewController;
@class AbstractPost;
@class Simperium;
@class Blog;

// Tab index constants
extern NSInteger const kReaderTabIndex;
extern NSInteger const kNotificationsTabIndex;
extern NSInteger const kMeTabIndex;

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong, readwrite) IBOutlet UIWindow              *window;
@property (nonatomic, strong,  readonly) UINavigationController         *navigationController;
@property (nonatomic, strong,  readonly) UITabBarController             *tabBarController;
@property (nonatomic, strong,  readonly) ReaderPostsViewController      *readerPostsViewController;
@property (nonatomic, strong,  readonly) BlogListViewController         *blogListViewController;
@property (nonatomic, strong,  readonly) NotificationsViewController    *notificationsViewController;
@property (nonatomic, strong,  readonly) Reachability                   *internetReachability;
@property (nonatomic, strong,  readonly) Reachability                   *wpcomReachability;
@property (nonatomic, strong,  readonly) DDFileLogger                   *fileLogger;
@property (nonatomic, strong,  readonly) Simperium                      *simperium;
@property (nonatomic, assign,  readonly) BOOL                           connectionAvailable;
@property (nonatomic, assign,  readonly) BOOL                           wpcomAvailable;

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
- (void)showTabForIndex:(NSInteger)tabIndex;
- (void)showPostTab;
- (void)switchTabToPostsListForPost:(AbstractPost *)post;
- (BOOL)isNavigatingMeTab;

///-----------
/// @name NUX
///-----------
- (void)showWelcomeScreenIfNeededAnimated:(BOOL)animated;

@end
