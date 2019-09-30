#import <Foundation/Foundation.h>

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

@end
