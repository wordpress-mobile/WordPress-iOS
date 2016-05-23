#import <Foundation/Foundation.h>
#import "InteractivePostViewDelegate.h"

@class Post;

/// Protocol that any view representing a post can implement.
///
@protocol ConfigurablePostView <NSObject>

/// When called, the view should start representing the specified post object.
///
/// - Parameters:
///     - post: the post to visually represent.
///
- (void)configureWithPost:(nonnull Post*)post;

/// Same as `configureWithPost:` but only for the purpose of layout.
///
/// - Parameters:
///     - post: the post to visually represent.
///     - layoutOnly: `true` if the configure call is meant for layout purposes only.
///             if set to `false`, this should behave exactly like `configureWithPost:`.
///
- (void)configureWithPost:(nonnull Post*)post
            forLayoutOnly:(BOOL)layoutOnly;

@end
