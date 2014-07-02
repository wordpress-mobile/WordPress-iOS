#import "ReaderPostContentView.h"
#import "WPRichTextView.h"

/**
 A version of ReaderPostContentView modified to display rich text and media,
 and the full body of the post.
 */
@interface ReaderPostRichContentView : ReaderPostContentView

@property (nonatomic, weak) id<ReaderPostContentViewDelegate, WPRichTextViewDelegate> delegate;

/**
 Tells the internal rich text view to relayout its media. Useful if media frames need to be adjusted
 due to changes in the rich text view's frame, e.g. an orientation change.
 */
- (void)refreshMediaLayout;

@end
