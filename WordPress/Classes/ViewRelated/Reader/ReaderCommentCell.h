#import "WPTableViewCell.h"

@protocol CommentContentViewDelegate;
@class Comment;

@interface ReaderCommentCell : WPTableViewCell

@property (nonatomic, weak) id<CommentContentViewDelegate> delegate;
@property (nonatomic) BOOL needsExtraPadding;
@property (nonatomic) BOOL isFirstNestedComment;
@property (nonatomic) BOOL hidesBorder;
@property (nonatomic) BOOL shouldEnableLoggedinFeatures;
@property (nonatomic) BOOL shouldShowReply;

- (void)configureCell:(Comment *)comment;
- (void)setAvatarImage:(UIImage *)avatarImage;
- (void)refreshMediaLayout;
- (void)preventPendingMediaLayout:(BOOL)prevent;

@end
