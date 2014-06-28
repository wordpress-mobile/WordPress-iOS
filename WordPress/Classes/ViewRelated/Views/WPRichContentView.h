#import "WPContentViewBase.h"
#import "WPRichTextView.h"

/**
 A WPContentView supporting rich text content.
 */
@interface WPRichContentView : WPContentViewBase

@property (nonatomic, weak) id<WPContentViewBaseDelegate, WPRichTextViewDelegate>delegate;

@end
