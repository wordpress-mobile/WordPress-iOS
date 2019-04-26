@class AbstractPost;
@class Blog;
@class BlogListViewController;
@class NotificationsViewController;
@class WordPressAuthenticationManager;
@class HockeyManager;
@class NoticePresenter;
@class Reachability;
@class WPUserAgent;
@class WPAppAnalytics;
@class WPLogger;

@import CocoaLumberjack;

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong, readonly) WPLogger *logger;
@property (nonatomic, assign, readonly) BOOL runningInBackground;
@property (nonatomic, strong, readonly) WPUserAgent *userAgent;

@property (nonatomic, strong, readwrite) WPAppAnalytics                 *analytics;
@property (nonatomic, strong, readwrite) HockeyManager                  *hockey;
@property (nonatomic, strong, readwrite) Reachability                   *internetReachability;
@property (nonatomic, strong, readwrite) WordPressAuthenticationManager *authManager;
@property (nonatomic, assign, readwrite) BOOL                           connectionAvailable;

+ (WordPressAppDelegate *)sharedInstance;

///-----------
/// @name NUX
///-----------
- (void)showWelcomeScreenIfNeededAnimated:(BOOL)animated;
- (void)showWelcomeScreenAnimated:(BOOL)animated thenEditor:(BOOL)thenEditor;
- (void)customizeAppearanceForTextElements;

@end
