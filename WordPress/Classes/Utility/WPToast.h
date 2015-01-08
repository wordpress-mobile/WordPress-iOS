#import <Foundation/Foundation.h>

@interface WPToast : NSObject

+ (void)showToastWithMessage:(NSString *)message andImage:(UIImage *)image;
+ (void)showToastWithMessage:(NSString *)message andImageNamed:(NSString *)imageName;

@end
