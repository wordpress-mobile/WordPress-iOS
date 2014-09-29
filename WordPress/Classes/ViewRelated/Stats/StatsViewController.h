#import <UIKit/UIKit.h>
#import "WPStatsViewController.h"

@class Blog;

@interface StatsViewController : WPStatsViewController

@property (nonatomic, weak) Blog *blog;
@property (nonatomic, copy) void (^dismissBlock)();

+ (void)removeTodayWidgetConfiguration;
+ (void)hideTodayWidgetIfNotConfigured;

@end
