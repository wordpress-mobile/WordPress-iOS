#import <UIKit/UIKit.h>

@class Blog;

@interface StatsViewController : UIViewController

@property (nonatomic, weak, nullable) Blog *blog;
@property (nonatomic, copy, nullable) void (^dismissBlock)(void);

@end
