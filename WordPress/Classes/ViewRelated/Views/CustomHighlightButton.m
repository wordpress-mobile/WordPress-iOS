#import "CustomHighlightButton.h"

@implementation CustomHighlightButton

- (void)setHighlighted:(BOOL)highlighted
{
    [UIView animateWithDuration:0.2 animations:^(){
        self.imageView.alpha = highlighted ? 0.3 : 1.0;
    }];
}

@end
