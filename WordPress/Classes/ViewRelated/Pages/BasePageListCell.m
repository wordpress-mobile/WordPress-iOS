#import "BasePageListCell.h"

@implementation BasePageListCell

- (void)configureCell:(id<WPPostContentViewProvider>)contentProvider
{
    self.contentProvider = contentProvider;
}

@end
