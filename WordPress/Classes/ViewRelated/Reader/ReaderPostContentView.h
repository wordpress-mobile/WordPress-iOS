#import "WPContentViewBase.h"

@class ReaderPost;
@class ReaderPostContentView;

/**
 The delegate of the`ReaderpostContentView` should adopt the `ReaderPostContentViewDelegate` protocol.
 Protocol methods allow the delegate to respond to user interactions.
 */
@protocol ReaderPostContentViewDelegate <WPContentViewBaseDelegate>
@optional

/**
 Tells the delegate that the user has tapped the like button.
 
 @param postView The post view informing the delegate of the event.
 @param sender A reference to the receiving `UIControl`.
 */
- (void)postView:(ReaderPostContentView *)postView didReceiveLikeAction:(id)sender;

/**
 Tells the delegate that the user has tapped the reblog button.

 @param postView The post view informing the delegate of the event.
 @param sender A reference to the receiving `UIControl`.
 */
- (void)postView:(ReaderPostContentView *)postView didReceiveReblogAction:(id)sender;

/**
 Tells the delegate that the user has tapped the comment button.

 @param postView The post view informing the delegate of the event.
 @param sender A reference to the receiving `UIControl`.
 */
- (void)postView:(ReaderPostContentView *)postView didReceiveCommentAction:(id)sender;

@end


/**
 A version of `WPContentViewBase` modified to show like, reblog, and comment 
 action buttons, and a `ReaderPostAttributionView`.
 */
@interface ReaderPostContentView : WPContentViewBase

/**
 The object that acts as the delegate of the receiving content view.
 */
@property (nonatomic, weak) id<ReaderPostContentViewDelegate> delegate;

/**
 A Boolean value specifying whether the view should display any action buttons.
 */
@property (nonatomic) BOOL shouldShowActions;

/**
 Configures the view to display the contents of the specified `ReaderPost`.
 This method automatically set the `contentProvider`
 */
- (void)configurePost:(ReaderPost *)post;

@end
