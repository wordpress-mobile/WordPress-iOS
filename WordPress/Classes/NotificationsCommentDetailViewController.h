#import <UIKit/UIKit.h>

@class IOS7CorrectedTextView, Note;

@interface NotificationsCommentDetailViewController : UIViewController <UITextViewDelegate>

- (id)initWithNote:(Note *)note;

@end
