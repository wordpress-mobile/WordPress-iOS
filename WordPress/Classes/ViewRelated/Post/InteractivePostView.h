#import <Foundation/Foundation.h>

@protocol InteractivePostViewDelegate;

/// Protocol that any view offering post interaction can implement.
///
@protocol InteractivePostView <NSObject>

/// Sets the delegate that will handle all post interaction.
///
- (void)setInteractionDelegate:(nonnull id<InteractivePostViewDelegate>)delegate;

@end
