#import <UIKit/UIKit.h>


@class EditCommentViewController;

@protocol EditCommentViewControllerDelegate <NSObject>
- (void)editCommentViewController:(EditCommentViewController *)sender didUpdateContent:(NSString *)newContent;
- (void)editCommentViewControllerFinished:(EditCommentViewController *)sender;
@end


@interface EditCommentViewController : UIViewController
@property (nonatomic,   weak) id<EditCommentViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString                              *content;
@property (nonatomic, assign) BOOL                                  interfaceEnabled;
@property (nonatomic, strong) id                                    userInfo;
+ (instancetype)newEditCommentViewController;
@end
