#import "WPContentView.h"

@class ReaderPost;
@class ReaderPostContentView;

/**
 The delegate of the`ReaderpostContentView` should adopt the `ReaderPostContentViewDelegate` protocol.
 Protocol methods allow the delegate to respond to user interactions.
 */
@protocol ReaderPostContentViewDelegate <WPContentViewDelegate>
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
 A version of `WPContentView` modified to show like, reblog, and comment 
 action buttons, and a `ReaderPostAttributionView`.
 */
@interface ReaderPostContentView : WPContentView

/**
 The object that acts as the delegate of the receiving content view.
 */
@property (nonatomic, weak) id<ReaderPostContentViewDelegate> delegate;

/**
 A Boolean value specifying whether the view should display the attribution menu.
 */
@property (nonatomic) BOOL shouldShowAttributionMenu;

/**
 A Boolean value specifying whether the view should display the attribution link button. 
 */
@property (nonatomic) BOOL shouldShowAttributionButton;

/**
 A Boolean value specifying whether the view should hide the reblog button.
 Determined by there being a visible WPCom blog
 */
@property (nonatomic) BOOL shouldHideReblogButton;

/**
 A Boolean value specifying whether the comments button must be hidden, no matter what the post properties are.
 */
@property (nonatomic) BOOL shouldHideComments;

/**
 A Boolean value whether the like button should be enabled or disabled.
 */
@property (nonatomic) BOOL shouldEnableLoggedinFeatures;

/**
 Configures the view to display the contents of the specified `ReaderPost`.
 This method automatically set the `contentProvider`
 */
- (void)configurePost:(ReaderPost *)post;

/**
 A Boolean value indicating whether the currently displayed content belongs to a private blog.
 */
- (BOOL)privateContent;


#pragma mark - Private Subclass Methods

- (void)buildActionButtons;

@end
