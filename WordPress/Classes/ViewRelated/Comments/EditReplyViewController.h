#import "EditCommentViewController.h"


@class EditReplyViewController;

@protocol EditReplyViewControllerDelegate <NSObject>
- (void)editReplyViewController:(EditReplyViewController *)sender didFinishWithContent:(NSString *)newContent;
- (void)editReplyViewControllerFinished:(EditReplyViewController *)sender;
@end


@interface EditReplyViewController : EditCommentViewController
@property (nonatomic,   weak) id<EditReplyViewControllerDelegate> replyDelegate;
@end
