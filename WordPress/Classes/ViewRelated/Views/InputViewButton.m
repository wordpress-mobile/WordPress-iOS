#import "InputViewButton.h"

@implementation InputViewButton

@synthesize inputView = _inputView;

- (UIView *)inputView
{
    return _inputView;
}

- (void)setInputView:(UIView *)inputView
{
    if (_inputView != inputView) {
        _inputView = inputView;
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

@end
