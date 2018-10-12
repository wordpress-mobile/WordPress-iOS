#import "BasePageListCell.h"
#import "AbstractPost.h"

@implementation BasePageListCell

- (void)configureCell:(AbstractPost *)post
{
    [self configureCell:post forSearch:NO];
}

- (void)configureCell:(AbstractPost *)post forSearch:(BOOL)isSearching
{
    self.post = post;
}

#pragma mark - Action

- (IBAction)onAction:(UIButton *)sender
{
    if (self.onAction) {
        NSAssert(self.post != nil, @"Expected the post to be set here.");
        self.onAction(self, sender, self.post);
    }
}

@end
