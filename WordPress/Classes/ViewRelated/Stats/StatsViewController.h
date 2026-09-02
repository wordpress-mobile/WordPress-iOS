#import <UIKit/UIKit.h>

@class Blog;

@interface StatsViewController : UIViewController

@property (nonatomic, strong, nullable) Blog *blog;
@property (nonatomic, copy, nullable) void (^dismissBlock)(void);

@end
