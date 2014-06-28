#import "ReaderPostContentView.h"
#import "WPRichTextView.h"

@interface ReaderPostRichContentView : ReaderPostContentView

@property (nonatomic, weak) id<ReaderPostContentViewDelegate, WPRichTextViewDelegate> delegate;

- (void)refreshMediaLayout;

@end
