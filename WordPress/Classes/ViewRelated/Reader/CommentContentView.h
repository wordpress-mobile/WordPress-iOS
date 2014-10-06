#import <UIKit/UIKit.h>
#import "WPContentViewProvider.h"

@protocol CommentContentViewDelegate <NSObject>
@optional
- (void)handleLinkTapped:(NSURL *)url;
- (void)handleReplyTapped:(id<WPContentViewProvider>)contentProvider;
- (void)handleLikeTapped:(id<WPContentViewProvider>)contentProvider;
- (void)handleUnlikeTapped:(id<WPContentViewProvider>)contentProvider;
@end

@interface CommentContentView : UIView

/**
 The object that acts as the delegate of the receiving content view.
 */
@property (nonatomic, weak) id<CommentContentViewDelegate> delegate;

/**
 The object specifying the content (text, images, etc.) to display.
 */
@property (nonatomic, weak) id<WPContentViewProvider> contentProvider;

/**
 Number of likes for the comment. It will set the numberOfLikes label.
 */
@property (nonatomic, assign) NSInteger likeCount;

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

@end
