#import "BasePageListCell.h"

@implementation BasePageListCell

- (void)configureCell:(id<WPPostContentViewProvider>)contentProvider
{
    self.contentProvider = contentProvider;
}

#pragma mark - Action

- (IBAction)onAction:(UIButton *)sender
{
    if (self.onAction) {
        NSAssert(self.contentProvider != nil, @"Expected the content provider to be set here.");
        self.onAction(self, sender, self.contentProvider);
    }
}

@end
