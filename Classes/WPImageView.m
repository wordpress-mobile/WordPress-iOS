#import "WPImageView.h"

@implementation WPImageView

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [delegate performSelector:operation withObject:self];
}

- (void)setDelegate:(id)aDelegate operation:(SEL)anOperation {
    delegate = aDelegate;
    operation = anOperation;
}

@end
