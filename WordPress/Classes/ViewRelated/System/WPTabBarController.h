#import <UIKit/UIKit.h>

extern NSString * const kWPNewPostURLParamContentKey;
extern NSString * const kWPNewPostURLParamTagsKey;

typedef NS_ENUM(NSUInteger, WPTabType) {
    WPTabMySites,
    WPTabReader,
    WPTabNewPost,
    WPTabMe,
    WPTabNotifications
};

@class AbstractPost, Blog, BlogListViewController, MeViewController , NotificationsViewController, ReaderPostsViewController;

@interface WPTabBarController : UITabBarController

@property (nonatomic, strong, readonly) BlogListViewController *blogListViewController;
@property (nonatomic, strong, readonly) ReaderPostsViewController *readerPostsViewController;
@property (nonatomic, strong, readonly) NotificationsViewController *notificationsViewController;
@property (nonatomic, strong, readonly) MeViewController *meViewController;

+ (instancetype)sharedInstance;

- (NSString *)currentlySelectedScreen;
- (BOOL)isNavigatingMySitesTab;

- (void)showMySitesTab;
- (void)showReaderTab;
- (void)showPostTab;
- (void)showNotificationsTab;
- (void)switchMySitesTabToStatsViewForBlog:(Blog *)blog;
- (void)showPostTabWithOptions:(NSDictionary *)options;
- (void)switchTabToPostsListForPost:(AbstractPost *)post;
- (void)showNotificationsTabForNoteWithID:(NSString *)notificationID;

@end
