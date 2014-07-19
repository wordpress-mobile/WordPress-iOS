#import "WPContentViewBase.h"

@class PostContentView;
@class Post;

/**
 The delegate of the`PostContentView` should adopt the `PostContentViewDelegate` protocol.
 Protocol methods allow the delegate to respond to user interactions.
 */
@protocol PostContentViewDelegate <WPContentViewBaseDelegate>
@optional

/**
 Tells the delegate that the user has tapped the edit button.

 @param postView The post view informing the delegate of the event.
 @param sender A reference to the receiving `UIControl`.
 */
- (void)postView:(PostContentView *)postView didReceiveEditAction:(id)sender;

/**
 Tells the delegate that the user has tapped the delete button.

 @param postView The post view informing the delegate of the event.
 @param sender A reference to the receiving `UIControl`.
 */
- (void)postView:(PostContentView *)postView didReceiveDeleteAction:(id)sender;

@end

/**
 A version of `WPContentViewBase` modified to show delete and edit
 action buttons, a full date, and a `PostAttributionView`.
 */
@interface PostContentView : WPContentViewBase

/**
 The object that acts as the delegate of the receiving content view.
 */
@property (nonatomic, weak) id<PostContentViewDelegate> delegate;

/**
 Configures the view to display the contents of the specified `Post`.
 This method automatically set the `contentProvider`
 */
- (void)configurePost:(Post *)post;

@end
