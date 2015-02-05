#import <UIKit/UIKit.h>
#import "WPStatsViewController.h"

@class Blog;

@interface StatsViewController : UIViewController

@property (nonatomic, weak) Blog *blog;
@property (nonatomic, copy) void (^dismissBlock)();

@end
