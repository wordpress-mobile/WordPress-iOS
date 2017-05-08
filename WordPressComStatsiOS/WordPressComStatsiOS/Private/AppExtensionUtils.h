#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 This class provides methods that are safe to call on extension or regular apps, depending of the use.
 */
@interface AppExtensionUtils : NSObject

+ (void)openURL:(NSURL *)url fromController:(UIViewController *)viewController;

+ (void)setNetworkActivityIndicatorVisible:(BOOL)active fromController:(UIViewController *)viewController;

@end
