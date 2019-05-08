#import <Foundation/Foundation.h>
#import "InteractivePostViewDelegate.h"
#import "PostActionSheetDelegate.h"

/// Protocol that any view offering post interaction can implement.
///
@protocol InteractivePostView <NSObject>

/// Sets the delegate that will handle all post interaction.
///
- (void)setInteractionDelegate:(nonnull id<InteractivePostViewDelegate>)delegate;
- (void)setActionSheetDelegate:(nonnull id<PostActionSheetDelegate>)delegate;

@end
