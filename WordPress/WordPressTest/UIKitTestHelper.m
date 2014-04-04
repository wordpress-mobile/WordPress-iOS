#import "UIKitTestHelper.h"

@implementation UITextField (UIKitTestHelper)

- (void)typeText:(NSString *)text {
    if (!self.text) {
        self.text = @"";
    }
    NSString *currentText = self.text;
    if (!self.delegate) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidBeginEditingNotification object:self];
        self.text = [currentText stringByAppendingString:text];
        [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:self];
        return;
    }

    if ([self.delegate respondsToSelector:@selector(textFieldShouldBeginEditing:)] && ![self.delegate textFieldShouldBeginEditing:self]) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(textFieldDidBeginEditing:)]) {
        [self.delegate textFieldDidBeginEditing:self];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidBeginEditingNotification object:self];
    if (![self.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)] || [self.delegate textField:self shouldChangeCharactersInRange:NSMakeRange([currentText length], 0) replacementString:text]) {
        self.text = [currentText stringByAppendingString:text];
        [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self];
    }
    if ([self.delegate respondsToSelector:@selector(textFieldShouldEndEditing:)] && [self.delegate textFieldShouldEndEditing:self]) {
        if ([self.delegate respondsToSelector:@selector(textFieldDidEndEditing:)]) {
            [self.delegate textFieldDidEndEditing:self];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification object:self];
}

@end

@implementation UITextView (UIKitTestHelper)

- (void)typeText:(NSString *)text {
    if (!self.text) {
        self.text = @"";
    }
    NSString *currentText = self.text;
    if (!self.delegate) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidBeginEditingNotification object:self];
        self.text = [currentText stringByAppendingString:text];
        [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidEndEditingNotification object:self];
    }

    if ([self.delegate respondsToSelector:@selector(textViewShouldBeginEditing:)] && ![self.delegate textViewShouldBeginEditing:self]) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(textViewDidBeginEditing:)]) {
        [self.delegate textViewDidBeginEditing:self];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidBeginEditingNotification object:self];
    if (![self.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)] || [self.delegate textView:self shouldChangeTextInRange:NSMakeRange([currentText length], 0) replacementText:text]) {
        self.text = [currentText stringByAppendingString:text];
        if ([self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
            [self.delegate textViewDidChange:self];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self];
    }
    if ([self.delegate respondsToSelector:@selector(textViewShouldEndEditing:)] && [self.delegate textViewShouldEndEditing:self]) {
        if ([self.delegate respondsToSelector:@selector(textViewDidEndEditing:)]) {
            [self.delegate textViewDidEndEditing:self];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidEndEditingNotification object:self];
}

@end