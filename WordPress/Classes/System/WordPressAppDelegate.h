@class Reachability;
@class DDFileLogger;
@class ReaderPostsViewController;
@class NotificationsViewController;
@class BlogListViewController;
@class NotificationsViewController;
@class AbstractPost;
@class Simperium;
@class Blog;
@class WPUserAgent;

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong, readwrite) IBOutlet UIWindow              *window;
@property (nonatomic, strong,  readonly) Reachability                   *internetReachability;
@property (nonatomic, strong,  readonly) Reachability                   *wpcomReachability;
@property (nonatomic, strong,  readonly) DDFileLogger                   *fileLogger;
@property (nonatomic, strong,  readonly) Simperium                      *simperium;
@property (nonatomic, assign,  readonly) BOOL                           connectionAvailable;
@property (nonatomic, assign,  readonly) BOOL                           wpcomAvailable;
@property (nonatomic, strong,  readonly) WPUserAgent                    *userAgent;

+ (WordPressAppDelegate *)sharedWordPressApplicationDelegate;

///-----------
/// @name NUX
///-----------
- (void)showWelcomeScreenIfNeededAnimated:(BOOL)animated;
- (void)showWelcomeScreenAnimated:(BOOL)animated thenEditor:(BOOL)thenEditor;

@end
