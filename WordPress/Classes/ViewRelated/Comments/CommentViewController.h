#import <UIKit/UIKit.h>

@class Comment;
@class CommentsViewController;
@interface CommentViewController : UIViewController

@property (nonatomic, strong) Comment *comment;
@property (nonatomic, weak) CommentsViewController *commentsViewController;
@property BOOL wasLastCommentPending;

- (void)cancelView:(id)sender;
- (void)showComment:(Comment *)comment;

@end
