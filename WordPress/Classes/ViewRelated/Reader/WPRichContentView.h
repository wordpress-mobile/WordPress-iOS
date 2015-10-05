#import "WPContentView.h"
#import "WPRichTextView.h"

/**
 A WPContentView supporting rich text content.
 */
@interface WPRichContentView : WPContentView

@property (nonatomic, weak) id<WPContentViewDelegate, WPRichTextViewDelegate>delegate;

@end
