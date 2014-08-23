#import <UIKit/UIKit.h>
#import "WPStatsViewController.h"

@class Blog;

@interface StatsViewController : WPStatsViewController

@property (nonatomic, weak) Blog *blog;

@end
