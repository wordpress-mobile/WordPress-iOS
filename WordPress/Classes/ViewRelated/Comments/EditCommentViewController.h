#import <UIKit/UIKit.h>



typedef void (^EditCommentCompletion)(BOOL hasNewContent, NSString *newContent);

@interface EditCommentViewController : UIViewController
@property (nonatomic,   copy) EditCommentCompletion onCompletion;
@property (nonatomic, strong) NSString              *content;
@property (nonatomic, assign) BOOL                  interfaceEnabled;
+ (instancetype)newEditViewController;
@end
