#import <UIKit/UIKit.h>
#import <WordPressComStatsiOS/WPStatsViewController.h>

@class Blog;

@interface StatsViewController : UIViewController

@property (nonatomic, weak) Blog *blog;
@property (nonatomic, copy) void (^dismissBlock)();
@property (nonatomic, weak) WPStatsService *statsService;

@end
