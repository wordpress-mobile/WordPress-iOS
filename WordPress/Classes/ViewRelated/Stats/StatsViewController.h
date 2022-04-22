
@class Blog;

@interface StatsViewController : UIViewController

@property (nonatomic, weak) Blog *blog;
@property (nonatomic, copy) void (^dismissBlock)(void);

+ (void)showForBlog:(nonnull Blog *)blog from:(nonnull UIViewController *)controller;

@end
