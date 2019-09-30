#import "MenuItemSourceTextBar.h"
#import "Menu+ViewDesign.h"
#import <WordPressShared/WPDeviceIdentification.h>
#import <WordPressShared/WPFontManager.h>
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

@import Gridicons;

@interface MenuItemSourceTextBarFieldObserver ()

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, copy) NSString *lastTextObserved;
@property (nonatomic, strong) NSTimer *timer;

- (void)timerFired;

@end

@interface MenuItemSourceTextBar () <UITextFieldDelegate>

@property (nonatomic, strong, readonly) UIStackView *stackView;
@property (nonatomic, strong, readonly) UIView *contentView;
@property (nonatomic, strong, readonly) UIStackView *contentStackView;
@property (nonatomic, strong, readonly) UILabel *cancelLabel;
@property (nonatomic, strong) NSMutableArray <MenuItemSourceTextBarFieldObserver *> *textObservers;

@end

@implementation MenuItemSourceTextBar

- (id)init
{
    self = [super init];
    if (self) {

        self.backgroundColor = [UIColor clearColor];
        self.translatesAutoresizingMaskIntoConstraints = NO;

        [self setupStackView];
        [self setupContentStackView];
        [self setupIconView];
        [self setupTextField];
        [self setupCancelLabel];
    }

    return self;
}

- (id)initAsSearchBar
{
    self = [self init];
    if (self) {

        NSAssert(_iconView != nil, @"iconView is nil");

        _iconView.image = [Gridicon iconOfType:GridiconTypeSearch];
        _iconView.hidden = NO;

        NSAssert(_textField != nil, @"textField is nil");

        UIFont *font = [WPFontManager systemRegularFontOfSize:16.0];
        NSString *placeholder = NSLocalizedString(@"Search...", @"Menus search bar placeholder text.");
        NSDictionary *attributes = @{NSFontAttributeName: font, NSForegroundColorAttributeName: [UIColor murielTextPlaceholder]};
        _textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:attributes];
    }

    return self;
}

- (void)setupStackView
{
    const CGFloat spacing = ceilf(MenusDesignDefaultContentSpacing / 2.0);
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.spacing = spacing;

    [self addSubview:stackView];

    const CGFloat padding = 3.0;
    NSLayoutConstraint *top = [stackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:padding];
    top.priority = 999;
    NSLayoutConstraint *bottom = [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-padding];
    bottom.priority = 999;
    [NSLayoutConstraint activateConstraints:@[
                                              top,
                                              [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                              [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                                              bottom
                                              ]];
    _stackView = stackView;
}

- (void)setupContentStackView
{
    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    contentView.layer.borderColor = [[UIColor murielNeutral10] CGColor];
    contentView.layer.borderWidth = MenusDesignStrokeWidth;
    if (![WPDeviceIdentification isRetina]) {
        // Increase the stroke width on non-retina screens.
        contentView.layer.borderWidth = MenusDesignStrokeWidth * 2;
    }
    contentView.backgroundColor = [UIColor murielBasicBackground];

    NSAssert(_stackView != nil, @"stackView is nil");

    [_stackView addArrangedSubview:contentView];
    _contentView = contentView;

    UIStackView *contentStackView = [[UIStackView alloc] init];
    contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
    contentStackView.distribution = UIStackViewDistributionFill;
    contentStackView.alignment = UIStackViewAlignmentFill;
    contentStackView.axis = UILayoutConstraintAxisHorizontal;

    const CGFloat spacing = _stackView.spacing;
    contentStackView.spacing = spacing;

    [contentView addSubview:contentStackView];

    const CGFloat leadingMargin = spacing;
    const CGFloat trailingMargin = spacing / 2.0; // Less on the right as the textField adds it's own margin inset.
    [NSLayoutConstraint activateConstraints:@[
                                              [contentStackView.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:spacing],
                                              [contentStackView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:leadingMargin],
                                              [contentStackView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-spacing],
                                              [contentStackView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-trailingMargin]
                                              ]];
    [contentStackView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    _contentStackView = contentStackView;
}

- (void)setupIconView
{
    UIImageView *iconView = [[UIImageView alloc] init];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.tintColor = [UIColor murielNeutral40];
    iconView.contentMode = UIViewContentModeScaleAspectFit;

    NSAssert(_contentStackView != nil, @"contentStackView is nil");

    [_contentStackView addArrangedSubview:iconView];

    NSLayoutConstraint *width = [iconView.widthAnchor constraintEqualToConstant:20.0];
    width.priority = 999;
    width.active = YES;

    iconView.hidden = YES;
    _iconView = iconView;
}

- (void)setupTextField
{
    UITextField *textField = [[UITextField alloc] init];
    textField.delegate = self;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.returnKeyType = UIReturnKeyDone;
    textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.opaque = YES;

    [textField addTarget:self action:@selector(textFieldDidEndOnExit:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [textField addTarget:self action:@selector(textFieldValueDidChange:) forControlEvents:UIControlEventEditingChanged];

    UIFont *font = [WPFontManager systemRegularFontOfSize:16.0];
    textField.font = font;

    NSAssert(_contentStackView != nil, @"contentStackView is nil");

    [_contentStackView addArrangedSubview:textField];

    [textField setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [textField setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    _textField = textField;
}

- (void)setupCancelLabel
{
    UILabel *label = [[UILabel alloc] init];
    label.text = NSLocalizedString(@"Cancel", @"Menus cancel button within text bar while editing items.");
    label.textColor = [UIColor murielText];
    label.font = [WPFontManager systemRegularFontOfSize:14.0];
    label.userInteractionEnabled = YES;

    NSAssert(_stackView != nil, @"stackView is nil");

    [_stackView addArrangedSubview:label];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelTapGesture:)];
    [label addGestureRecognizer:tap];

    [label setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
    [label setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];

    label.hidden = YES;
    label.alpha = 0.0;

    _cancelLabel = label;
}

- (void)addTextObserver:(MenuItemSourceTextBarFieldObserver *)textObserver
{
    if (!self.textObservers) {
        self.textObservers = [NSMutableArray array];
    }

    textObserver.textField = self.textField;
    [self.textObservers addObject:textObserver];
}

- (BOOL)isFirstResponder
{
    return [self.textField isFirstResponder];
}

- (BOOL)resignFirstResponder
{
    if ([self.textField isFirstResponder]) {
        return [self.textField resignFirstResponder];
    }

    return [super resignFirstResponder];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    [self setNeedsDisplay];
}

- (void)setCancelLabelHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (self.cancelLabel.hidden != hidden) {

        void(^toggleButton)(void) = ^() {
            self.cancelLabel.hidden = hidden;
            self.cancelLabel.alpha = hidden ? 0.0 : 1.0;
        };

        if (animated) {
            [UIView animateWithDuration:0.20 animations:^{
                toggleButton();
            }];
        } else  {
            toggleButton();
        }
    }
}

- (void)cancelTapGesture:(UITapGestureRecognizer *)tap
{
    [self.textField resignFirstResponder];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self setCancelLabelHidden:NO animated:YES];
    [self.delegate sourceTextBarDidBeginEditing:self];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self setCancelLabelHidden:YES animated:YES];
    [self.delegate sourceTextBarDidEndEditing:self];
}

- (void)textFieldValueDidChange:(UITextField *)textField
{
    for (MenuItemSourceTextBarFieldObserver *textObserver in self.textObservers) {

        [textObserver.timer invalidate];
        textObserver.timer = [NSTimer scheduledTimerWithTimeInterval:textObserver.interval target:textObserver selector:@selector(timerFired) userInfo:nil repeats:NO];
    }

    [self.delegate sourceTextBar:self didUpdateWithText:textField.text];
}

- (void)textFieldDidEndOnExit:(UITextField *)textField
{
    [textField resignFirstResponder];
}

@end

@implementation MenuItemSourceTextBarFieldObserver

- (void)dealloc
{
    [self.timer invalidate];
}

- (void)timerFired
{
    if ([self.textField.text isEqualToString:self.lastTextObserved]) {
        // text hasn't changed, no observation needed
        return;
    }
    // text is different, change should be observed
    self.lastTextObserved = self.textField.text;
    if (self.onTextChange) {
        self.onTextChange(self.textField.text);
    }
}

@end
