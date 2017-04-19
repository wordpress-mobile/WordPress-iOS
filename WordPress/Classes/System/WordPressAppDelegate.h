@class Reachability;
@class ReaderPostsViewController;
@class NotificationsViewController;
@class BlogListViewController;
@class NotificationsViewController;
@class AbstractPost;
@class Blog;
@class WPUserAgent;
@class WPAppAnalytics;
@class WPLogger;

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong, readonly) WPAppAnalytics *analytics;
@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong, readonly) WPLogger *logger;
@property (nonatomic, strong, readonly) Reachability *internetReachability;
@property (nonatomic, strong, readonly) Reachability *wpcomReachability;
@property (nonatomic, assign, readonly) BOOL connectionAvailable;
@property (nonatomic, strong, readonly) WPUserAgent *userAgent;

+ (WordPressAppDelegate *)sharedInstance;

///-----------
/// @name NUX
///-----------
- (void)showWelcomeScreenIfNeededAnimated:(BOOL)animated;
- (void)showWelcomeScreenAnimated:(BOOL)animated thenEditor:(BOOL)thenEditor;

@end
