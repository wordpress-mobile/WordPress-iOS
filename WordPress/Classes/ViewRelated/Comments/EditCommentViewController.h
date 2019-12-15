#import <UIKit/UIKit.h>

typedef void (^EditCommentCompletion)(BOOL hasNewContent, NSString *newContent);

@interface EditCommentViewController : UIViewController <UITextViewDelegate>
@property (nonatomic,     copy) EditCommentCompletion onCompletion;
@property (nonatomic,   strong) NSString              *content;
@property (nonatomic,   assign) BOOL                  interfaceEnabled;

/// Returns the text that the user has entered in the textView
@property (readonly, nonatomic) NSString              *textViewText;

+ (instancetype)newEditViewController;

@end
