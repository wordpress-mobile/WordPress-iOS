#import <UIKit/UIKit.h>
#import "WPCommentContentViewProvider.h"
#import "WPRichTextView.h"

@class CommentContentView;

@protocol CommentContentViewDelegate <NSObject, WPRichTextViewDelegate>
- (void)commentView:(CommentContentView *)commentView updatedAttachmentViewsForProvider:(id<WPCommentContentViewProvider>)contentProvider;
@optional
- (void)handleReplyTapped:(id<WPCommentContentViewProvider>)contentProvider;
- (void)toggleLikeStatus:(id<WPCommentContentViewProvider>)contentProvider;
@end

@interface CommentContentView : UIView

/**
 The object that acts as the delegate of the receiving content view.
 */
@property (nonatomic, weak) id<CommentContentViewDelegate> delegate;

/**
 The object specifying the content (text, images, etc.) to display.
 */
@property (nonatomic, weak) id<WPCommentContentViewProvider> contentProvider;

/**
 A Boolean value whether the like button should be present.
 */
@property (nonatomic) BOOL shouldEnableLoggedinFeatures;

/**
 A Boolean value whether the reply button should present.
 */
@property (nonatomic) BOOL shouldShowReply;

/**
 Resets the content view's appearance.
 */
- (void)reset;

/**
 Set's the image to display as the content view's attribution view's avatar.
 */
- (void)setAvatarImage:(UIImage *)image;

/**
 Specifies whether the author should be highlighted or not.  The default is 
 no highlight. A set highlight is removed when calling reset, or assigning a
 content provider. 
 */
- (void)highlightAuthor:(BOOL)highlight;


- (void)refreshMediaLayout;

- (void)preventPendingMediaLayout:(BOOL)prevent;

@end
