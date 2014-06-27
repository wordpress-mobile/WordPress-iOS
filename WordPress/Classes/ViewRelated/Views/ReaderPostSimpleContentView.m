#import "ReaderPostSimpleContentView.h"
#import "WPSimpleContentAttributionView.h"

@implementation ReaderPostSimpleContentView

- (void)configureConstraints
{
    [super configureConstraints];

    UIView *actionView = self.actionView;
    NSDictionary *views = NSDictionaryOfVariableBindings(actionView);

    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[actionView(0)]" options:0 metrics:nil views:views]];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize newSize = [super sizeThatFits:size];
    newSize.height -= self.actionView.intrinsicContentSize.height;

    return newSize;
}

- (void)configureActionView
{
    // Hide the actionview and remove its subviews.
    // This let's us clear its internal constraints allowing it to accept a 0 height.
    // This prevents this sub class from having to rebuild the parent class's constraints.
    self.actionView.hidden = YES;
    NSArray *arr = self.actionView.subviews;
    for (UIView *view in arr) {
        [view removeFromSuperview];
    }
}

- (void)updateActionButtons
{
    // noop
}


- (WPContentAttributionView *)viewForAttributionView
{
    WPSimpleContentAttributionView *attrView = [[WPSimpleContentAttributionView alloc] init];
    attrView.translatesAutoresizingMaskIntoConstraints = NO;
    return attrView;
}

@end
