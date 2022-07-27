#import <UIKit/UIKit.h>

typedef void (^EditCommentCompletion)(BOOL hasNewContent, NSString *newContent);

@interface EditCommentViewController : UIViewController <UITextViewDelegate>
@property (nonatomic,           copy) EditCommentCompletion   onCompletion;
@property (nonatomic,           strong) NSString              *content;
@property (nonatomic,           assign) BOOL                  interfaceEnabled;
@property (readonly, nonatomic, weak) IBOutlet UITextView     *textView;
@property (readonly, nonatomic, weak) IBOutlet UILabel        *placeholderLabel;
@property (readonly, nonatomic, assign) CGRect keyboardFrame;

+ (instancetype)newEditViewController;

/// Triggered to indicate the content of the text view has changed
/// Automatically called when the user enters text into the `textView`
- (void)contentDidChange;

// Keyboard handlers
- (void)handleKeyboardDidShow:(NSNotification *)notification;
- (void)handleKeyboardWillHide:(NSNotification *)notification;
@end
