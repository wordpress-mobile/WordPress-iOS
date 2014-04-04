#import "ContentActionButton.h"

@implementation ContentActionButton

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.alpha = highlighted ? .5f : 1.f;
}

@end
