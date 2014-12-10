@class Reachability;
@class DDFileLogger;
@class ReaderPostsViewController;
@class NotificationsViewController;
@class BlogListViewController;
@class NotificationsViewController;
@class AbstractPost;
@class Simperium;
@class Blog;

// Tab index constants
extern NSInteger const kMySitesTabIndex;
extern NSInteger const kReaderTabIndex;
extern NSInteger const kNewPostTabIndex;
extern NSInteger const kMeTabIndex;
extern NSInteger const kNotificationsTabIndex;

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong, readwrite) IBOutlet UIWindow              *window;
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

///-----------
/// @name NUX
///-----------
- (void)showWelcomeScreenIfNeededAnimated:(BOOL)animated;
- (void)showWelcomeScreenAnimated:(BOOL)animated thenEditor:(BOOL)thenEditor;

@end
