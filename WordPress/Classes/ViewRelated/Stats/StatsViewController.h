#import <UIKit/UIKit.h>
#import "WPStatsViewController.h"

@class Blog;

@interface StatsViewController : UIViewController

@property (nullable, nonatomic, weak) Blog *blog;
@property (nullable, nonatomic, copy) void (^dismissBlock)();

@end
