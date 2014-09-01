#import "InlineComposeView.h"
#import "WPStyleGuide.h"

const CGFloat InlineComposeViewMinHeight = 44.f;
const CGFloat InlineComposeViewMaxHeight = 88.f;

@interface InlineComposeView () <UITextViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *inputAccessoryView;
@property (nonatomic, weak) IBOutlet UITextView *toolbarTextView;
@property (nonatomic, weak) IBOutlet UILabel *placeholderLabel;
@property (nonatomic, weak) IBOutlet UIButton *sendButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (nonatomic, strong) UITextView *proxyTextView;
@property (nonatomic, strong) NSArray *bundle;

@end

@implementation InlineComposeView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _enabled = YES;

        // Initialization code
        _bundle = [[NSBundle mainBundle] loadNibNamed:@"InlineComposeView" owner:self options:nil];

        _proxyTextView = [[UITextView alloc] initWithFrame:CGRectZero];
        _proxyTextView.delegate = self;
        _proxyTextView.inputAccessoryView = self.inputAccessoryView;

        // Ensure scroll-to-top gesture is disabled so it still works in parent views
        _proxyTextView.scrollsToTop = NO;
        _toolbarTextView.scrollsToTop = NO;

        self.placeholderLabel.text = NSLocalizedString(@"Write a reply…", @"Placeholder text for inline compose view");
        [self.sendButton setTitle:NSLocalizedString(@"Reply", @"") forState:UIControlStateNormal];

        [self addSubview:_proxyTextView];

        self.sendButton.tintColor = [WPStyleGuide wordPressBlue];
    }
    return self;
}

- (void)dealloc
{
    self.proxyTextView.delegate = nil;
    self.proxyTextView = nil;

    self.bundle = nil;
}

- (void)updatePlaceholderAndSize
{
    NSCharacterSet *whitespaceCharSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    UITextView *textView = self.toolbarTextView;
    // show placeholder if text is empty
    BOOL empty = [textView.text length] == 0;
    BOOL emptyOrOnlyWhitespace = [[textView.text stringByTrimmingCharactersInSet:whitespaceCharSet] length] == 0;
    self.placeholderLabel.hidden = !empty;
    self.sendButton.enabled = !emptyOrOnlyWhitespace;

    [self updateSendButtonSize];

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

- (void)updateSendButtonSize
{
    // Update the components' size and location after localized button label has been set.
    CGFloat sendButtonWidth = self.sendButton.frame.size.width;
    [self.sendButton sizeToFit];
    CGFloat sendButtonDelta = self.sendButton.frame.size.width - sendButtonWidth;

    CGRect frame = self.toolbarTextView.frame;
    frame.size.width -= sendButtonDelta;
    self.toolbarTextView.frame = frame;

    frame = self.placeholderLabel.frame;
    frame.size.width -= sendButtonDelta;
    self.placeholderLabel.frame = frame;

    frame = self.sendButton.frame;
    frame.origin.x -= sendButtonDelta;
    self.sendButton.frame = frame;
}

- (void)setButtonTitle:(NSString *)title
{
    if ([title length] > 0) {
        [self.sendButton setTitle:title forState:UIControlStateNormal];
    } else {
        [self.sendButton setTitle:NSLocalizedString(@"Reply", @"") forState:UIControlStateNormal];
    }
}

- (void)clearText
{
    self.text = @"";
}

- (void)displayComposer
{
    [self.proxyTextView becomeFirstResponder];
}

- (void)toggleComposer
{
    if (self.isDisplayed) {
        [self dismissComposer];
    } else {
        [self displayComposer];
    }
}

- (void)dismissComposer
{
    [self resignFirstResponder];
    // resigning first responder doesn't always dismiss they keyboard, so force it
    [self endEditing:YES];
}

- (BOOL)isDisplayed
{
    return self.isFirstResponder || self.proxyTextView.isFirstResponder || self.toolbarTextView.isFirstResponder;
}

#pragma mark - IBAction

- (IBAction)onSendReply:(id)sender
{
    [self.delegate composeView:self didSendText:self.toolbarTextView.text];
}

#pragma mark - Accessors

- (void)setEnabled:(BOOL)enabled
{
    if (enabled == _enabled) {
        return;
    }

    _enabled = enabled;

    self.toolbarTextView.editable = enabled;
    self.toolbarTextView.alpha = enabled ? 1.f : 0.5f;
    self.sendButton.hidden = !enabled;
    if (enabled) {
        [self.activityIndicatorView stopAnimating];
    } else {
        [self.activityIndicatorView startAnimating];
    }
    [self.proxyTextView becomeFirstResponder];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    self.toolbarTextView.attributedText = attributedText;
    [self updatePlaceholderAndSize];
}

- (NSAttributedString *)attributedText
{
    return self.toolbarTextView.attributedText;
}

- (void)setText:(NSString *)text
{
    self.toolbarTextView.text = text;
    [self updatePlaceholderAndSize];
}

- (NSString *)text
{
    return self.toolbarTextView.text;
}

- (void)setPlaceholder:(NSString *)placeholder
{
    self.placeholderLabel.text = placeholder;
}

- (NSString *)placeholder
{
    return self.placeholderLabel.text;
}

#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder
{
    return [self.proxyTextView canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder
{
    return [self.proxyTextView becomeFirstResponder];
}

- (BOOL)resignFirstResponder
{
    [super resignFirstResponder];
    return [self.proxyTextView resignFirstResponder];
}

- (BOOL)canResignFirstResponder
{
    return [self.proxyTextView canResignFirstResponder];
}

#pragma mark - UITextViewDelegate
// Forwards all delegate methods to our delegate if the textview is the toolbar text view

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if (textView == self.toolbarTextView && [self.delegate respondsToSelector:@selector(textViewShouldBeginEditing:)]) {
        return [self.delegate textViewShouldBeginEditing:textView];
    }
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    // Focus the input field in the toolbar when we begin editing from the proxy
    if (textView == self.proxyTextView) {
        if (self.toolbarTextView.editable){
            [self.toolbarTextView becomeFirstResponder];
        }
        self.toolbarTextView.editable = YES;
    }

    // forward UITextViewDelegate methods of the toolbar textview to our delegate
    [self updatePlaceholderAndSize];
    if ([self.delegate respondsToSelector:@selector(textViewDidBeginEditing:)]) {
        [self.delegate textViewDidBeginEditing:textView];
    }
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    if (textView != self.toolbarTextView){
        return YES;
    }

    if ([self.delegate respondsToSelector:@selector(textViewShouldEndEditing:)]) {
        return [self.delegate textViewShouldEndEditing:textView];
    }
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{

    if (textView != self.toolbarTextView){
        return;
    }

    if ([self.delegate respondsToSelector:@selector(textViewDidEndEditing:)]) {
        [self.delegate textViewDidEndEditing:textView];
    }

}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (textView != self.toolbarTextView){
        return YES;
    }

    if (self.shouldDeleteTagWithBackspace) {
        if ([self deleteTagInTextView:textView forTextChangeInRange:range replacementText:text]) {
            return NO;
        }
    }

    BOOL delegateImplementsAtMention = [self.mentionDelegate respondsToSelector:@selector(composeViewDidStartAtMention:)];

    if ([text isEqualToString:@"@"] && range.length == 0 && delegateImplementsAtMention) {
        [self.mentionDelegate composeViewDidStartAtMention:self];
        return YES;
    }

    if ([self.delegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
        return [self.delegate textView:textView shouldChangeTextInRange:range replacementText:text];
    }

    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    // ignore any changes to the proxy textview, it's not used for text entry
    if (textView == self.proxyTextView){
        return;
    }

    // forward UITextFieldDelegate methods to our delegate
    if ([self.delegate respondsToSelector:@selector(textViewDidChange:)]) {
        [self.delegate textViewDidChange:textView];
    }

    [self updatePlaceholderAndSize];
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    if (textView != self.toolbarTextView){
        return;
    }

    if ([self.delegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
        [self.delegate textViewDidChangeSelection:textView];
    }
}

- (BOOL)textView:(UITextView *)textView
        shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment
         inRange:(NSRange)characterRange
{
    if (self.toolbarTextView != textView){
        return YES;
    }

    if ([self.delegate respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:)]) {
        return [self.delegate textView:textView shouldInteractWithTextAttachment:textAttachment inRange:characterRange];
    }

    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
    if (self.toolbarTextView != textView){
        return YES;
    }

    if ([self.delegate respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:)]) {
        return [self.delegate textView:textView shouldInteractWithURL:URL inRange:characterRange];
    }

    return YES;
}

#pragma mark - Delete Tag with Backspace Helper

// returns the result of if a tag was deleted or not
- (BOOL)deleteTagInTextView:(UITextView *)textView forTextChangeInRange:(NSRange)range replacementText:(NSString *)text {
    // deleting or replacing text
    if (range.length > 0) {
        NSString *currentText = textView.text;

        // check if the first character of the text being edited (selected) is space (ex. "@someTag ")
        if ([[currentText substringWithRange:NSMakeRange(range.location, 1)] isEqualToString:@" "]) {
            return NO;
        }

        /**
         In order to find the beginning of the word currently being edited:
         Find the text before the edited part and reverse check for the first space character
         If there is no space character in the text, it means it is the first word
         Store the location of the first character position of the word
         */

        NSString *textBeforeEditedPart = [currentText substringToIndex:range.location];
        __block NSInteger firstCharacterPosition = 0;

        [textBeforeEditedPart enumerateSubstringsInRange:NSMakeRange(0, [textBeforeEditedPart length])
                                                 options:(NSStringEnumerationReverse | NSStringEnumerationByComposedCharacterSequences)
                                              usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                                  if ([substring isEqualToString:@" "]) {
                                                      firstCharacterPosition = substringRange.location + 1; // +1 is for the length of @" "
                                                      *stop = YES;
                                                  }
                                              }];

        // Check if the first character at the position we found is @ sign and if not return
        if (![[currentText substringWithRange:NSMakeRange(firstCharacterPosition, 1)] isEqualToString:@"@"]) {
            return NO;
        }

        /**
         If the user is deleting the tag from the middle, we want to make sure it deletes the whole word
         To do that, first find the end position after the @ signed word. Then, while calculating the new
         length of the range that will be changed, include the part after the cursor to the end of the word.
         */

        NSString *textAfterAtSign = [currentText substringFromIndex:firstCharacterPosition];
        __block NSInteger taggedWordEndPosition = firstCharacterPosition;

        [currentText enumerateSubstringsInRange:NSMakeRange(firstCharacterPosition, [textAfterAtSign length])
                                        options:NSStringEnumerationByComposedCharacterSequences
                                     usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                         taggedWordEndPosition = substringRange.location + substringRange.length;
                                         if ([substring isEqualToString:@" "]) {
                                             *stop = YES;
                                         }
                                     }];

        NSInteger newLength = MAX(range.location + range.length, taggedWordEndPosition) - firstCharacterPosition;
        textView.text = [currentText stringByReplacingCharactersInRange:NSMakeRange(firstCharacterPosition, newLength) withString:text];

        // Change the cursor position to where the user left it off since we are changing the text manually
        textView.selectedRange = NSMakeRange(firstCharacterPosition, 0);

        return YES;
    }
    return NO;
}

@end
