#import "WPTableViewCell.h"

@class Comment;

@protocol ReaderCommentCellDelegate <NSObject>
@optional
- (void)commentCell:(UITableViewCell *)cell replyToComment:(Comment *)comment;
- (void)commentCell:(UITableViewCell *)cell linkTapped:(NSURL *)url;
- (void)commentCell:(UITableViewCell *)cell likeComment:(Comment *)comment;
- (void)commentCell:(UITableViewCell *)cell unlikeComment:(Comment *)comment;
@end


@interface ReaderCommentCell : WPTableViewCell

@property (nonatomic, weak) id<ReaderCommentCellDelegate> delegate;
@property (nonatomic) BOOL needsExtraPadding;
@property (nonatomic) BOOL isFirstNestedComment;

- (void)configureCell:(Comment *)comment;
- (void)setAvatarImage:(UIImage *)avatarImage;

@end
