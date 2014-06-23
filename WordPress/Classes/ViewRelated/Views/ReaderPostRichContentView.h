#import "ReaderPostContentView.h"
#import "WPRichContentView.h"

@interface ReaderPostRichContentView : ReaderPostContentView

@property (nonatomic, weak) id<ReaderPostContentViewDelegate, WPRichContentViewDelegate> delegate;

@end
