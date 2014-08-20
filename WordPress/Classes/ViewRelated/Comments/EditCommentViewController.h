#import <UIKit/UIKit.h>
#import "Comment.h"

@class IOS7CorrectedTextView;
@class EditCommentViewController;


@protocol EditCommentViewControllerDelegate <NSObject>
- (void)editCommentViewController:(EditCommentViewController *)sender finishedWithUpdates:(BOOL)hasUpdates;
@end


@interface EditCommentViewController : UIViewController
@property (nonatomic,   weak) id<EditCommentViewControllerDelegate> delegate;
@property (nonatomic, strong) Comment                               *comment;
@end
