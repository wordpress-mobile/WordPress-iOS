#import <UIKit/UIKit.h>

extern NSString * const WPNewPostURLParamContentKey;
extern NSString * const WPNewPostURLParamTagsKey;

typedef NS_ENUM(NSUInteger, WPTabType) {
    WPTabMySites,
    WPTabReader,
    WPTabNewPost,
    WPTabMe,
    WPTabNotifications
};

@class AbstractPost;
@class Blog;
@class BlogListViewController;
@class MeViewController;
@class NotificationsViewController;
@class ReaderViewController;

@interface WPTabBarController : UITabBarController

@property (nonatomic, strong, readonly) BlogListViewController *blogListViewController;
@property (nonatomic, strong, readonly) ReaderViewController *readerViewController;
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
- (void)updateNotificationBadgeVisibility;

@end
