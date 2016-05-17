#import <Foundation/Foundation.h>
#import "InteractivePostViewDelegate.h"

@protocol InteractivePostView <NSObject>

- (void)setInteractionDelegate:(nonnull id<InteractivePostViewDelegate>)delegate;

@end
