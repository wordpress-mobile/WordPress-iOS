#import "ReaderPostUnattributedTableViewCell.h"
#import "ReaderPostUnattributedContentView.h"

@implementation ReaderPostUnattributedTableViewCell

- (ReaderPostContentView *)newReaderPostContentView
{
    ReaderPostUnattributedContentView *view = [[ReaderPostUnattributedContentView alloc] init];
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.backgroundColor = [UIColor whiteColor];
    return view;
}

@end
