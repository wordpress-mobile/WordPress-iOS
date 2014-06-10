#import "WPEditorViewController.h"
#import "WPKeyboardToolbarBase.h"
#import "WPKeyboardToolbarDone.h"
#import <WordPress-iOS-Shared/WPStyleGuide.h>
#import <WordPress-iOS-Shared/WPTableViewCell.h>
#import <UIAlertView+Blocks/UIAlertView+Blocks.h>

CGFloat const EPVCTextfieldHeight = 44.0f;
CGFloat const EPVCOptionsHeight = 44.0f;
CGFloat const EPVCStandardOffset = 15.0;
CGFloat const EPVCTextViewOffset = 10.0;
CGFloat const EPVCTextViewBottomPadding = 50.0f;
CGFloat const EPVCTextViewTopPadding = 7.0f;

@interface WPEditorViewController ()<UITextFieldDelegate, UITextViewDelegate, WPKeyboardToolbarDelegate>
@property (nonatomic) CGPoint scrollOffsetRestorePoint;
@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) UIButton *optionsButton;
@property (nonatomic, strong) UILabel *tapToStartWritingLabel;
@property (nonatomic, strong) UITextField *titleTextField;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIView *optionsSeparatorView;
@property (nonatomic, strong) UIView *optionsView;
@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) WPKeyboardToolbarBase *editorToolbar;
@property (nonatomic, strong) WPKeyboardToolbarDone *titleToolbar;
@end

@implementation WPEditorViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // For the iPhone, let's let the overscroll background color be white to match the editor.
    if (IS_IPAD) {
        self.view.backgroundColor = [WPStyleGuide itsEverywhereGrey];
    }
    self.navigationController.navigationBar.translucent = NO;
    [self setupToolbar];
    [self setupTextView];
    [self setupOptionsView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // When restoring state, the navigationController is nil when the view loads,
    // so configure its appearance here instead.
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.toolbarHidden = NO;
    UIToolbar *toolbar = self.navigationController.toolbar;
    toolbar.barTintColor = [WPStyleGuide littleEddieGrey];
    toolbar.translucent = NO;
    toolbar.barStyle = UIBarStyleDefault;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    if(self.navigationController.navigationBarHidden) {
        [self.navigationController setNavigationBarHidden:NO animated:animated];
    }
    
    if (self.navigationController.toolbarHidden) {
        [self.navigationController setToolbarHidden:NO animated:animated];
    }
    
    for (UIView *view in self.navigationController.toolbar.subviews) {
        [view setExclusiveTouch:YES];
    }
    
    [_textView setContentOffset:CGPointMake(0, 0)];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    // Refresh the UI when the view appears or the options
    // button won't be visible when restoring state.
    [self refreshUI];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    [self.navigationController setToolbarHidden:YES animated:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
	[self stopEditing];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - Getters and Setters

- (NSString*)titleText
{
    return _titleTextField.text;
}

- (void) setTitleText:(NSString*)titleText
{
    [_titleTextField setText:titleText];
    [self refreshUI];
}

- (NSString*)bodyText
{
    return _textView.text;
}

- (void) setBodyText:(NSString*)bodyText
{
    [_textView setText:bodyText];
    [self refreshUI];
}

#pragma mark - View Setup

- (void)setupToolbar
{
    if ([self.toolbarItems count] > 0) {
        return;
    }
    
    UIBarButtonItem *previewButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-posts-editor-preview"]
                                                                      style:UIBarButtonItemStylePlain
                                                                     target:self
                                                                     action:@selector(didTouchPreview)];
    UIBarButtonItem *photoButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-posts-editor-media"]
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(didTouchMediaOptions)];
    
    previewButton.tintColor = [WPStyleGuide readGrey];
    photoButton.tintColor = [WPStyleGuide readGrey];

    previewButton.accessibilityLabel = NSLocalizedString(@"Preview post", nil);
    photoButton.accessibilityLabel = NSLocalizedString(@"Add media", nil);
    
    UIBarButtonItem *leftFixedSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                     target:nil
                                                                                     action:nil];
    UIBarButtonItem *rightFixedSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                      target:nil
                                                                                      action:nil];
    UIBarButtonItem *centerFlexSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                      target:nil
                                                                                      action:nil];
    
    leftFixedSpacer.width = -2.0f;
    rightFixedSpacer.width = -5.0f;
    
    self.toolbarItems = @[leftFixedSpacer, previewButton, centerFlexSpacer, photoButton, rightFixedSpacer];
}

- (void)setupTextView
{
    CGFloat x = 0.0f;
    CGFloat viewWidth = CGRectGetWidth(self.view.frame);
    CGFloat width = viewWidth;
    UIViewAutoresizing mask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    if (IS_IPAD) {
        width = WPTableViewFixedWidth;
        x = ceilf((viewWidth - width) / 2.0f);
        mask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    }
    CGRect frame = CGRectMake(x, 0.0f, width, CGRectGetHeight(self.view.frame) - EPVCOptionsHeight);

    // Height should never be smaller than what is required to display its text.
    if (!self.textView) {
        self.textView = [[UITextView alloc] initWithFrame:frame];
        self.textView.autoresizingMask = mask;
        self.textView.delegate = self;
        self.textView.typingAttributes = [WPStyleGuide regularTextAttributes];
        self.textView.font = [WPStyleGuide regularTextFont];
        self.textView.textColor = [WPStyleGuide darkAsNightGrey];
        self.textView.accessibilityLabel = NSLocalizedString(@"Content", @"Post content");
    }
    [self.view addSubview:self.textView];
    
    // Formatting bar for the textView's inputAccessoryView.
    if (self.editorToolbar == nil) {
        frame = CGRectMake(0.0f, 0.0f, viewWidth, WPKT_HEIGHT_PORTRAIT);
        self.editorToolbar = [[WPKeyboardToolbarBase alloc] initWithFrame:frame];
        self.editorToolbar.backgroundColor = [WPStyleGuide keyboardColor];
        self.editorToolbar.delegate = self;
        self.textView.inputAccessoryView = self.editorToolbar;
    }
    
    // Title TextField.
    if (!self.titleTextField) {
        CGFloat textWidth = CGRectGetWidth(self.textView.frame) - (2 * EPVCStandardOffset);
        frame = CGRectMake(EPVCStandardOffset, 0.0, textWidth, EPVCTextfieldHeight);
        self.titleTextField = [[UITextField alloc] initWithFrame:frame];
        self.titleTextField.delegate = self;
        self.titleTextField.font = [WPStyleGuide postTitleFont];
        self.titleTextField.textColor = [WPStyleGuide darkAsNightGrey];
        self.titleTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.titleTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:(NSLocalizedString(@"Enter title here", @"Label for the title of the post field. Should be the same as WP core.")) attributes:(@{NSForegroundColorAttributeName: [WPStyleGuide textFieldPlaceholderGrey]})];
        self.titleTextField.accessibilityLabel = NSLocalizedString(@"Title", @"Post title");
        self.titleTextField.returnKeyType = UIReturnKeyNext;
    }
    [self.textView addSubview:self.titleTextField];
    
    // InputAccessoryView for title textField.
    if (!self.titleToolbar) {
        frame = CGRectMake(0.0f, 0.0f, viewWidth, WPKT_HEIGHT_PORTRAIT);
        self.titleToolbar = [[WPKeyboardToolbarDone alloc] initWithFrame:frame];
        self.titleToolbar.backgroundColor = [WPStyleGuide keyboardColor];
        self.titleToolbar.delegate = self;
        self.titleTextField.inputAccessoryView = self.titleToolbar;
    }
    
    // One pixel separator bewteen title and content text fields.
    if (!self.separatorView) {
        CGFloat y = CGRectGetMaxY(self.titleTextField.frame);
        CGFloat separatorWidth = width - EPVCStandardOffset;
        frame = CGRectMake(EPVCStandardOffset, y, separatorWidth, 1.0);
        self.separatorView = [[UIView alloc] initWithFrame:frame];
        self.separatorView.backgroundColor = [WPStyleGuide readGrey];
        self.separatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    [self.textView addSubview:self.separatorView];
    
    // Update the textView's textContainerInsets so text does not overlap content.
    CGFloat left = EPVCTextViewOffset;
    CGFloat right = EPVCTextViewOffset;
    CGFloat top = CGRectGetMaxY(self.separatorView.frame) + EPVCTextViewTopPadding;
    CGFloat bottom = EPVCTextViewBottomPadding;
    self.textView.textContainerInset = UIEdgeInsetsMake(top, left, bottom, right);

    if (!self.tapToStartWritingLabel) {
        frame = CGRectZero;
        frame.origin.x = EPVCStandardOffset;
        frame.origin.y = self.textView.textContainerInset.top;
        frame.size.width = width - (EPVCStandardOffset * 2);
        frame.size.height = 26.0f;
        self.tapToStartWritingLabel = [[UILabel alloc] initWithFrame:frame];
        self.tapToStartWritingLabel.text = NSLocalizedString(@"Tap here to begin writing", @"Placeholder for the main body text. Should hint at tapping to enter text (not specifying body text).");
        self.tapToStartWritingLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.tapToStartWritingLabel.font = [WPStyleGuide regularTextFont];
        self.tapToStartWritingLabel.textColor = [WPStyleGuide textFieldPlaceholderGrey];
        self.tapToStartWritingLabel.isAccessibilityElement = NO;
    }
    [self.textView addSubview:self.tapToStartWritingLabel];
}

- (void)setupOptionsView
{
    CGFloat width = CGRectGetWidth(self.textView.frame);
    CGFloat x = CGRectGetMinX(self.textView.frame);
    CGFloat y = CGRectGetMaxY(self.textView.frame);
    
    CGRect frame;
    if (!self.optionsView) {
        frame = CGRectMake(x, y, width, EPVCOptionsHeight);
        self.optionsView = [[UIView alloc] initWithFrame:frame];
        self.optionsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        if (IS_IPAD) {
            self.optionsView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
        }
        self.optionsView.backgroundColor = [UIColor whiteColor];
    }
    [self.view addSubview:self.optionsView];
    
    // One pixel separator bewteen content and table view cells.
    if (!self.optionsSeparatorView) {
        CGFloat separatorWidth = width - EPVCStandardOffset;
        frame = CGRectMake(EPVCStandardOffset, 0.0f, separatorWidth, 1.0f);
        self.optionsSeparatorView = [[UIView alloc] initWithFrame:frame];
        self.optionsSeparatorView.backgroundColor = [WPStyleGuide readGrey];
        self.optionsSeparatorView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    [self.optionsView addSubview:self.optionsSeparatorView];
    
    if (!self.optionsButton) {
        NSString *optionsTitle = NSLocalizedString(@"Options", @"Title of the Post Settings tableview cell in the Post Editor. Tapping shows settings and options related to the post being edited.");
        frame = CGRectMake(0.0f, 1.0f, width, EPVCOptionsHeight - 1.0f);
        self.optionsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.optionsButton.frame = frame;
        self.optionsButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.optionsButton addTarget:self action:@selector(didTouchSettings)
                     forControlEvents:UIControlEventTouchUpInside];
        [self.optionsButton setBackgroundImage:[self imageWithColor:[WPStyleGuide readGrey]]
                                      forState:UIControlStateHighlighted];

        // Rather than using a UIImageView to fake a disclosure icon, just use a cell and future proof the UI.
        WPTableViewCell *cell = [[WPTableViewCell alloc] initWithFrame:self.optionsButton.bounds];
        // The cell uses its default frame and ignores what was passed during init, so set it again.
        cell.frame = self.optionsButton.bounds;
        cell.backgroundColor = [UIColor clearColor];
        cell.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        cell.textLabel.text = optionsTitle;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.userInteractionEnabled = NO;
        [WPStyleGuide configureTableViewCell:cell];
        
        [self.optionsButton addSubview:cell];
    }
    [self.optionsView addSubview:self.optionsButton];
}

- (void)positionTextView:(NSNotification *)notification
{
    NSDictionary *keyboardInfo = [notification userInfo];
    CGRect originalKeyboardFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrame = [self.view convertRect:[self.view.window convertRect:originalKeyboardFrame fromWindow:nil]
                                         fromView:nil];
    CGRect frame = self.textView.frame;
    
    if (self.isShowingKeyboard) {
        frame.size.height = CGRectGetMinY(keyboardFrame) - CGRectGetMinY(frame);
    } else {
        frame.size.height = CGRectGetHeight(self.view.frame) - EPVCOptionsHeight;
    }
    self.textView.frame = frame;
}

#pragma mark - Actions

- (void)didTouchSettings
{
    if ([_delegate respondsToSelector: @selector(editorDidPressSettings:)]) {
        [_delegate editorDidPressSettings:self];
    }
}

- (void)didTouchPreview
{
    if ([_delegate respondsToSelector: @selector(editorDidPressPreview:)]) {
        [_delegate editorDidPressPreview:self];
    }
}

- (void)didTouchMediaOptions
{
    if ([_delegate respondsToSelector: @selector(editorDidPressMedia:)]) {
        [_delegate editorDidPressMedia:self];
    }
}

#pragma mark - Editor and Misc Methods

- (void)stopEditing
{
    // With the titleTextField as a subview of textField, we need to resign and
    // end editing to prevent the textField from becomeing first responder.
    if ([self.titleTextField isFirstResponder]) {
        [self.titleTextField resignFirstResponder];
    }
    [self.view endEditing:YES];
}

- (void)refreshUI
{
    if(self.titleText != nil || self.titleText != 0) {
        self.title = self.titleText;
    }
    if(self.bodyText == nil || self.bodyText == 0) {
        _tapToStartWritingLabel.hidden = NO;
        _textView.text = @"";
    } else {
        _tapToStartWritingLabel.hidden = YES;
    }
}

- (void)showLinkView
{
    NSRange range = _textView.selectedRange;
    NSString *infoText = nil;
    if (range.length > 0) {
        infoText = [_textView.text substringWithRange:range];
    }
    self.scrollOffsetRestorePoint = self.textView.contentOffset;
    
    NSString *alertViewTitle = NSLocalizedString(@"Make a Link", @"Title of the Link Helper popup to aid in creating a Link in the Post Editor.");
    NSCharacterSet *charSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    alertViewTitle = [alertViewTitle stringByTrimmingCharactersInSet:charSet];
    
    NSString *insertButtonTitle = NSLocalizedString(@"Insert", @"Insert content (link, media) button");
    NSString *cancelButtonTitle = NSLocalizedString(@"Cancel", @"Cancel button");
    
    _alertView = [[UIAlertView alloc] initWithTitle:alertViewTitle
                                            message:nil
                                           delegate:nil
                                  cancelButtonTitle:cancelButtonTitle
                                  otherButtonTitles:insertButtonTitle, nil];
    _alertView.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    _alertView.tag = 99;
    
    UITextField *alt = [self.alertView textFieldAtIndex:1];
    alt.secureTextEntry = NO;
    alt.placeholder = NSLocalizedString(@"Text to be linked", @"Popup to aid in creating a Link in the Post Editor.");
    alt.autocapitalizationType = UITextAutocapitalizationTypeNone;
    alt.keyboardAppearance = UIKeyboardAppearanceAlert;
    alt.keyboardType = UIKeyboardTypeDefault;
    if (infoText) {
        alt.text = infoText;
    }
    
    UITextField *linkURL = [self.alertView textFieldAtIndex:0];
    linkURL.placeholder = NSLocalizedString(@"Link URL", @"Popup to aid in creating a Link in the Post Editor, URL field (where you can type or paste a URL that the text should link.");
    linkURL.autocapitalizationType = UITextAutocapitalizationTypeNone;
    linkURL.keyboardAppearance = UIKeyboardAppearanceAlert;
    linkURL.keyboardType = UIKeyboardTypeURL;
    linkURL.autocorrectionType = UITextAutocorrectionTypeNo;
    
    _alertView.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (alertView.tag == 99) {
            if (buttonIndex == 1) {
                // Insert link
                UITextField *urlField = [alertView textFieldAtIndex:0];
                UITextField *infoText = [alertView textFieldAtIndex:1];
                
                if ((urlField.text == nil) || ([urlField.text isEqualToString:@""])) {
                    return;
                }
                
                if ((infoText.text == nil) || ([infoText.text isEqualToString:@""])) {
                    infoText.text = urlField.text;
                }
                
                NSString *urlString = [self validateNewLinkInfo:[urlField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
                NSString *aTagText = [NSString stringWithFormat:@"<a href=\"%@\">%@</a>", urlString, infoText.text];
                NSRange range = _textView.selectedRange;
                NSString *oldText = _textView.text;
                NSRange oldRange = _textView.selectedRange;
                _textView.scrollEnabled = NO;
                _textView.text = [_textView.text stringByReplacingCharactersInRange:range withString:aTagText];
                _textView.scrollEnabled = YES;
                
                //reset selection back to nothing
                range.length = 0;
                range.location += [aTagText length]; // Place selection after the tag
                _textView.selectedRange = range;
                
                [[_textView.undoManager prepareWithInvocationTarget:self] restoreText:oldText withRange:oldRange];
                [_textView.undoManager setActionName:@"link"];
                [self textViewDidChange:_textView];
                [self refreshTextView];
                
            }
            
            // Don't dismiss the keyboard
            if([_textView resignFirstResponder]){
                [_textView becomeFirstResponder];
            }
        }
    };
    
    _alertView.shouldEnableFirstOtherButtonBlock = ^BOOL(UIAlertView *alertView) {
        if (alertView.tag == 99) {
            UITextField *textField = [alertView textFieldAtIndex:0];
            if ([textField.text length] == 0) {
                return NO;
            }
        }
        return YES;
    };

    [_alertView show];
}

// Appends http:// if protocol part is not there as part of urlText.
- (NSString *)validateNewLinkInfo:(NSString *)urlText
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[\\w]+:" options:0 error:&error];
    
    if ([regex numberOfMatchesInString:urlText options:0 range:NSMakeRange(0, [urlText length])] > 0) {
        return urlText;
    } else if([urlText hasPrefix:@"#"]) {
        // link to named anchor
        return urlText;
    } else {
        return [NSString stringWithFormat:@"http://%@", urlText];
    }
}

- (UIImage *)imageWithColor:(UIColor *)color
{
    return [self imageWithColor:color havingSize:CGSizeMake(1.0f, 1.0f)];
}

- (UIImage *)imageWithColor:(UIColor *)color havingSize:(CGSize)size
{
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - Formatting

- (void)restoreText:(NSString *)text withRange:(NSRange)range
{
    NSString *oldText = _textView.text;
    NSRange oldRange = _textView.selectedRange;
    _textView.scrollEnabled = NO;
    // iOS6 seems to have a bug where setting the text like so : textView.text = text;
    // will cause an infinate loop of undos.  A work around is to perform the selector
    // on the main thread.
    // textView.text = text;
    [_textView performSelectorOnMainThread:@selector(setText:) withObject:text waitUntilDone:NO];
    _textView.scrollEnabled = YES;
    _textView.selectedRange = range;
    [[_textView.undoManager prepareWithInvocationTarget:self] restoreText:oldText withRange:oldRange];
    [self textViewDidChange:_textView];
}

- (void)wrapSelectionWithTag:(NSString *)tag
{
    NSRange range = _textView.selectedRange;
    NSString *selection = [_textView.text substringWithRange:range];
    NSString *prefix, *suffix;
    if ([tag isEqualToString:@"more"]) {
        prefix = @"<!--more-->";
        suffix = @"\n";
    } else if ([tag isEqualToString:@"blockquote"]) {
        prefix = [NSString stringWithFormat:@"\n<%@>", tag];
        suffix = [NSString stringWithFormat:@"</%@>\n", tag];
    } else {
        prefix = [NSString stringWithFormat:@"<%@>", tag];
        suffix = [NSString stringWithFormat:@"</%@>", tag];
    }
    _textView.scrollEnabled = NO;
    NSString *replacement = [NSString stringWithFormat:@"%@%@%@",prefix,selection,suffix];
    _textView.text = [_textView.text stringByReplacingCharactersInRange:range
                                                             withString:replacement];
    [self textViewDidChange:_textView];
    _textView.scrollEnabled = YES;
    if (range.length == 0) {                // If nothing was selected
        range.location += [prefix length]; // Place selection between tags
    } else {
        range.location += range.length + [prefix length] + [suffix length]; // Place selection after tag
        range.length = 0;
    }
    _textView.selectedRange = range;
    
    [self refreshTextView];
}

// In some situations on iOS7, inserting text while `scrollEnabled = NO` results in
// the last line(s) of text on the text view not appearing. This is a workaround
// to get the UITextView to redraw after inserting text but without affecting the
// scrollOffset.
- (void)refreshTextView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _textView.scrollEnabled = NO;
        [_textView setNeedsDisplay];
        _textView.scrollEnabled = YES;
    });
}

#pragma mark - WPKeyboardToolbar Delegate

- (void)keyboardToolbarButtonItemPressed:(WPKeyboardToolbarButtonItem *)buttonItem
{
    if ([buttonItem.actionTag isEqualToString:@"link"]) {
        [self showLinkView];
    } else if ([buttonItem.actionTag isEqualToString:@"done"]) {
        [self stopEditing];
    } else {
        NSString *oldText = _textView.text;
        NSRange oldRange = _textView.selectedRange;
        [self wrapSelectionWithTag:buttonItem.actionTag];
        [[_textView.undoManager prepareWithInvocationTarget:self] restoreText:oldText withRange:oldRange];
        [_textView.undoManager setActionName:buttonItem.actionName];
    }
}

#pragma mark - TextView Delegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if ([_delegate respondsToSelector: @selector(editorShouldBeginEditing:)]) {
        return [_delegate editorShouldBeginEditing:self];
    }
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    _tapToStartWritingLabel.hidden = YES;
}

- (void)textViewDidChange:(UITextView *)aTextView
{
    if ([_delegate respondsToSelector: @selector(editorTextDidChange:)]) {
        [_delegate editorTextDidChange:self];
    }
}

- (void)textViewDidEndEditing:(UITextView *)aTextView
{
    if ([_textView.text isEqualToString:@""]) {
        _tapToStartWritingLabel.hidden = NO;
    }
}

#pragma mark - TextField delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if ([_delegate respondsToSelector: @selector(editorShouldBeginEditing:)]) {
        return [_delegate editorShouldBeginEditing:self];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == _titleTextField) {
        [self setTitle:[textField.text stringByReplacingCharactersInRange:range withString:string]];
        if ([_delegate respondsToSelector: @selector(editorTitleDidChange:)]) {
            [_delegate editorTitleDidChange:self];
        }
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [_textView becomeFirstResponder];
    return NO;
}

#pragma mark - Positioning & Rotation

- (BOOL)shouldHideToolbarsWhileTyping
{
    /*
     Never hide for the iPad.
     Always hide on the iPhone except for portrait + external keyboard
     */
    if (IS_IPAD) {
        return NO;
    }
    
    BOOL isLandscape = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation);
    if (!isLandscape && _isExternalKeyboard) {
        return NO;
    }
    
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    CGRect frame = _editorToolbar.frame;
    if (UIDeviceOrientationIsLandscape(interfaceOrientation)) {
        if (IS_IPAD) {
            frame.size.height = WPKT_HEIGHT_IPAD_LANDSCAPE;
        } else {
            frame.size.height = WPKT_HEIGHT_IPHONE_LANDSCAPE;
        }
        
    } else {
        if (IS_IPAD) {
            frame.size.height = WPKT_HEIGHT_IPAD_PORTRAIT;
        } else {
            frame.size.height = WPKT_HEIGHT_IPHONE_PORTRAIT;
        }
    }
    _editorToolbar.frame = frame;
    _titleToolbar.frame = frame; // Frames match, no need to re-calc.
}

#pragma mark - Keyboard management

- (void)keyboardWillShow:(NSNotification *)notification
{
	_isShowingKeyboard = YES;
    
    if ([self shouldHideToolbarsWhileTyping]) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        [self.navigationController setToolbarHidden:YES animated:NO];
    }
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    if ([self.textView isFirstResponder]) {
        if (!CGPointEqualToPoint(CGPointZero, self.scrollOffsetRestorePoint)) {
            self.textView.contentOffset = self.scrollOffsetRestorePoint;
            self.scrollOffsetRestorePoint = CGPointZero;
        }
    }
    [self positionTextView:notification];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	_isShowingKeyboard = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController setToolbarHidden:NO animated:NO];
    
    [self positionTextView:notification];
}

@end
