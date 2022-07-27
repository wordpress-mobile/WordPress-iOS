
@class Blog;

@interface StatsViewController : UIViewController

@property (nonatomic, weak, nullable) Blog *blog;
@property (nonatomic, copy, nullable) void (^dismissBlock)(void);

+ (void)showForBlog:(nonnull Blog *)blog from:(nonnull UIViewController *)controller;

@end
