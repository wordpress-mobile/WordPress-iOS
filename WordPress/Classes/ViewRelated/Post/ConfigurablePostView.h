#import <Foundation/Foundation.h>
#import "PostCardTableViewCellDelegate.h"

@class AbstractPost;

@protocol ConfigurablePostView <NSObject>

/// When called, the view should start representing the specified post object, and send any
/// interaction events to the delegate.
///
/// - Parameters:
///     - post: the post to visually represent.
///     - delegate: the delegate that will receive any interaction events.
///
- (void)configureWithPost:(nonnull AbstractPost*)post
             withDelegate:(nonnull id<PostCardTableViewCellDelegate>)delegate;

/// Same as `configure(delegate:post:)` but only for the purpose of layout.
///
/// - Parameters:
///     - post: the post to visually represent.
///     - delegate: the delegate that will receive any interaction events.
///     - layoutOnly: `true` if the configure call is meant for layout purposes only.
///             if set to `false`, this should behave exactly like `configure(delegate:post:)`.
///
- (void)configureWithPost:(nonnull AbstractPost*)post
             withDelegate:(nonnull id<PostCardTableViewCellDelegate>)delegate
            forLayoutOnly:(BOOL)layoutOnly;

@end
