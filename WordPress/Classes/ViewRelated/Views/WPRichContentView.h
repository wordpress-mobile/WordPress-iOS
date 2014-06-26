#import "WPContentViewBase.h"
#import "WPRichTextView.h"

@interface WPRichContentView : WPContentViewBase

@property (nonatomic, weak) id<WPContentViewBaseDelegate, WPRichTextViewDelegate>delegate;

@end
