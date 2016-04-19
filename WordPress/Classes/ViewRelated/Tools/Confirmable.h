#import <Foundation/Foundation.h>

@protocol Confirmable <NSObject>

- (void)cancel;
- (void)confirm;

@end

