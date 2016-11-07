#import <UIKit/UIKit.h>

@class Blog;
@class WPStatsService;

@interface StatsViewController : UIViewController

@property (nonatomic, weak) Blog *blog;
@property (nonatomic, copy) void (^dismissBlock)();
@property (nonatomic, weak) WPStatsService *statsService;

@end
