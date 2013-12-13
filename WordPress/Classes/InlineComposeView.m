//
//  InlineComposeView.m
//  WordPress
//


#import "InlineComposeView.h"

const CGFloat InlineComposeViewMinHeight = 44.f;
const CGFloat InlineComposeViewMaxHeight = 88.f;

@interface InlineComposeView () <UITextViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) IBOutlet UIView *inputAccessoryView;
@property (nonatomic, weak) IBOutlet UITextView *toolbarTextView;
@property (nonatomic, weak) IBOutlet UILabel *placeholderLabel;
@property (nonatomic, weak) IBOutlet UIButton *sendButton;
@property (nonatomic, strong) UITextView *proxyTextView;
@property (nonatomic, strong) NSArray *bundle;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, weak) UIView *keyboardView;

@property CGFloat keyboardAnchor;

@end

@implementation InlineComposeView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _bundle = [[NSBundle mainBundle] loadNibNamed:@"InlineComposeView" owner:self options:nil];

        _proxyTextView = [[UITextView alloc] initWithFrame:CGRectZero];

        _proxyTextView.delegate = self;

        _proxyTextView.inputAccessoryView = self.inputAccessoryView;

        self.placeholderLabel.text = NSLocalizedString(@"Reply", @"Placeholder text for inline compose view");

        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanned:)];
        _panGesture.cancelsTouchesInView = NO;
        _panGesture.delegate = self;

        [self addSubview:_proxyTextView];

    }
    return self;
}

- (void)dealloc {
    self.bundle = nil;
    self.proxyTextView.delegate = nil;
    self.proxyTextView = nil;

    [self.panGesture.view removeGestureRecognizer:self.panGesture];
    self.panGesture.delegate = nil;
    self.panGesture = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updatePlaceholderAndSize {
    UITextView *textView = self.toolbarTextView;
    // show placeholder if text is empty
    BOOL empty = [textView.text isEqualToString:@""];
    self.placeholderLabel.hidden = !empty;
    self.sendButton.enabled = !empty;

    CGRect frame = self.inputAccessoryView.frame;

    // if there's no text, force it back to min height
    if (empty) {
        frame.size.height = InlineComposeViewMinHeight;
        self.inputAccessoryView.frame = frame;
        return;
    }

    // expand placeholder to max height
    CGSize textSize = self.toolbarTextView.contentSize;
    CGSize textFrameSize = self.toolbarTextView.frame.size;
    CGFloat delta = textSize.height - textFrameSize.height;

    // we don't need to change the height
    if (delta == 0) {
        return;
    }

    frame.size.height += delta;
    // keep the height within the constraints
    frame.size.height = MIN(frame.size.height, InlineComposeViewMaxHeight);
    frame.size.height = MAX(frame.size.height, InlineComposeViewMinHeight);

    self.inputAccessoryView.frame = frame;

    [self.toolbarTextView scrollRangeToVisible:self.toolbarTextView.selectedRange];

}

- (void)onPanned:(UIPanGestureRecognizer *)gesture {

    if (self.keyboardView.hidden) {
        return;
    }
    UIView *keyboardView = self.inputAccessoryView.superview;
    CGRect keyboardFrame = keyboardView.frame;
    CGFloat currentY = keyboardFrame.origin.y;
    CGPoint location = [gesture locationInView:self.inputAccessoryView];
    CGFloat deltaY = currentY - self.keyboardAnchor;
    CGPoint velocity = [gesture velocityInView:self];

    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.keyboardAnchor = keyboardFrame.origin.y;
            break;
        case UIGestureRecognizerStateChanged:

            if (location.y > 0) {
                // start moving the view
                keyboardFrame.origin.y += location.y;
                keyboardView.frame = keyboardFrame;
            } else if (location.y < 0 && currentY > self.keyboardAnchor){
                keyboardFrame.origin.y += location.y;
                keyboardFrame.origin.y = MAX(keyboardFrame.origin.y, self.keyboardAnchor);
                keyboardView.frame = keyboardFrame;
            }

            break;

        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            // if we're moving back up
            BOOL hide;
            if (velocity.y < 0 || deltaY < 44.f) {
                // revert the keyboard
                hide = NO;
                keyboardFrame.origin.y = self.keyboardAnchor;
            } else {
                hide = YES;
                keyboardFrame.origin.y = CGRectGetMaxY(self.window.frame);
            }

            if (hide) {
                [self.window removeGestureRecognizer:self.panGesture];
            }

            [UIView animateWithDuration:0.25f
                                  delay:0.f
                                options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                                        keyboardView.frame = keyboardFrame;
                                    }
                             completion:^(BOOL finished) {
                                    if (hide) {
                                        keyboardView.hidden = YES;
                                        [self resignFirstResponder];
                                        [self endEditing:YES];
                                    }
                                    }];

        }

        default:
            break;
    }
}

- (void)displayComposer {
    [self.proxyTextView becomeFirstResponder];
}

- (void)toggleComposer {
    if (self.isDisplayed) {
        [self dismissComposer];
    } else {
        [self displayComposer];
    }
}

- (void)dismissComposer {
    [self resignFirstResponder];
    // resigning first responder doesn't always dismiss they keyboard, so force it
    [self endEditing:YES];
}

- (BOOL)isDisplayed {
    return self.isFirstResponder || self.proxyTextView.isFirstResponder || self.toolbarTextView.isFirstResponder;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - UIView

- (void)willMoveToWindow:(UIWindow *)newWindow {

    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];

    if (!newWindow) {
        return;
    }

    [nc removeObserver:self];

    [nc addObserver:self
           selector:@selector(keyboardWillShow:)
               name:UIKeyboardWillShowNotification
             object:nil];

    [nc addObserver:self
           selector:@selector(keyboardDidShow:)
               name:UIKeyboardDidShowNotification
             object:nil];

    [nc addObserver:self
           selector:@selector(keyboardWillHide:)
               name:UIKeyboardWillHideNotification
             object:nil];

    [nc addObserver:self
           selector:@selector(keyboardDidHide:)
               name:UIKeyboardDidHideNotification
             object:nil];

}

#pragma mark - IBAction

- (IBAction)onSendReply:(id)sender {
    [self.delegate composeView:self didSendText:self.toolbarTextView.text];
}

#pragma mark - Accessors

- (void)setAttributedText:(NSAttributedString *)attributedText {
    self.toolbarTextView.attributedText = attributedText;
    [self updatePlaceholderAndSize];
}

- (NSAttributedString *)attributedText {
    return self.toolbarTextView.attributedText;
}

- (void)setText:(NSString *)text {
    self.toolbarTextView.text = text;
    [self updatePlaceholderAndSize];
}

- (NSString *)text {
    return self.toolbarTextView.text;
}

- (void)setPlaceholder:(NSString *)placeholder {
    self.placeholderLabel.text = placeholder;
}

- (NSString *)placeholder {
    return self.placeholderLabel.text;
}

#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder {
    return [self.proxyTextView canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder {
    return [self.proxyTextView becomeFirstResponder];
}

- (BOOL)resignFirstResponder {
    return [self.proxyTextView resignFirstResponder];
}

- (BOOL)canResignFirstResponder {
    return [self.proxyTextView canResignFirstResponder];
}

#pragma mark - UIKeyboardWillShowNotification

- (void)keyboardWillShow:(NSNotification *)notification {
    self.keyboardView.hidden = NO;
}

#pragma mark UIKeyboardDidShowNotification

- (void)keyboardDidShow:(NSNotification *)notification {
    self.keyboardView = self.inputAccessoryView.superview;
    [self.window addGestureRecognizer:self.panGesture];
}

#pragma mark UIKeyboardWillHideNotification

- (void)keyboardWillHide:(NSNotification *)notification {

    [self.window removeGestureRecognizer:self.panGesture];

}

#pragma mark UIKeyboardDidHideNotification

- (void)keyboardDidHide:(NSNotification *)notification {
    self.keyboardView.hidden = NO;
}

#pragma mark - UITextViewDelegate
// Forwards all delegate methods to our delegate if the textview is the toolbar text view

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if (textView == self.toolbarTextView && [self.delegate respondsToSelector:@selector(textViewShouldBeginEditing:)]) {
        return [self.delegate textViewShouldBeginEditing:textView];
    }
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    // Focus the input field in the toolbar when we begin editing from the proxy
    if (textView == self.proxyTextView) {
        if(self.toolbarTextView.editable)
            [self.toolbarTextView becomeFirstResponder];
        self.toolbarTextView.editable = YES;
    }

    // forward UITextViewDelegate methods of the toolbar textview to our delegate
    if ([self.delegate respondsToSelector:@selector(textViewDidBeginEditing:)]) {
        [self.delegate textViewDidBeginEditing:textView];
    }
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if (textView != self.toolbarTextView) return YES;

    if ([self.delegate respondsToSelector:@selector(textViewShouldEndEditing:)]) {
        return [self.delegate textViewShouldEndEditing:textView];
    }
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView != self.toolbarTextView) return;

    if ([self.delegate respondsToSelector:@selector(textViewDidEndEditing:)]) {
        [self.delegate textViewDidEndEditing:textView];
    }

}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (textView != self.toolbarTextView) return YES;

    if ([self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
        return [self.delegate textView:textView shouldChangeTextInRange:range replacementText:text];
    }

    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    // ignore any changes to the proxy textview, it's not used for text entry
    if (textView == self.proxyTextView)
        return;

    // forward UITextFieldDelegate methods to our delegate
    if ([self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
        [self.delegate textViewDidChange:textView];
    }

    [self updatePlaceholderAndSize];
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    if (textView != self.toolbarTextView) return;

    if ([self.delegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
        [self.delegate textViewDidChangeSelection:textView];
    }
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange {

    if (self.toolbarTextView != textView) return YES;

    if ([self.delegate respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:)]) {
        return [self.delegate textView:textView shouldInteractWithTextAttachment:textAttachment inRange:characterRange];
    }

    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if (self.toolbarTextView != textView) return YES;

    if ([self.delegate respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:)]) {
        return [self.delegate textView:textView shouldInteractWithURL:URL inRange:characterRange];
    }

    return YES;
}


@end
