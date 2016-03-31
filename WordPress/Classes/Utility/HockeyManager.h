#import <Foundation/Foundation.h>

@interface HockeyManager : NSObject

- (BOOL)handleOpenURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options;

/**
 Configures the Hockey SDK if available. You should keep a reference to this as it becomes the Hockey manager delegate.
 */
- (void)configure;

@end
