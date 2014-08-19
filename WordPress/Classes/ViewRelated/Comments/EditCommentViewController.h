#import <UIKit/UIKit.h>
#import "Comment.h"



@class IOS7CorrectedTextView;
@class EditCommentViewController;

@protocol EditCommentViewControllerDelegate <NSObject>
- (void)editCommentViewController:(EditCommentViewController *)sender didUpdateComment:(Comment *)comment;
- (void)editCommentViewControllerWasDismissed:(EditCommentViewController *)sender;
@end


@interface EditCommentViewController : UIViewController

@property (nonatomic,   weak) id<EditCommentViewControllerDelegate> delegate;
@property (nonatomic, strong) Comment                               *comment;

@end
