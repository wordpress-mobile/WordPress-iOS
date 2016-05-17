#import <Foundation/Foundation.h>
#import "InteractivePostViewDelegate.h"

@class AbstractPost;

@protocol ConfigurablePostView <NSObject>

/// When called, the view should start representing the specified post object, and send any
/// interaction events to the delegate.
///
/// - Parameters:
///     - post: the post to visually represent.
///
- (void)configureWithPost:(nonnull AbstractPost*)post;

/// Same as `configure(delegate:post:)` but only for the purpose of layout.
///
/// - Parameters:
///     - post: the post to visually represent.
///     - layoutOnly: `true` if the configure call is meant for layout purposes only.
///             if set to `false`, this should behave exactly like `configure(delegate:post:)`.
///
- (void)configureWithPost:(nonnull AbstractPost*)post
            forLayoutOnly:(BOOL)layoutOnly;

@end
