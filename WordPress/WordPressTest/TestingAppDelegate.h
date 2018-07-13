#import <UIKit/UIKit.h>

@interface TestingAppDelegate : NSObject<UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, assign, readwrite) BOOL  connectionAvailable;
@end
