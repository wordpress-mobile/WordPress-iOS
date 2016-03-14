#import "MenuItemSourceTextBar.h"
#import "MenusDesign.h"
#import "WPStyleGuide.h"
#import "WPFontManager.h"

@interface MenuItemSourceTextBarFieldObserver ()

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, copy) NSString *lastTextObserved;
@property (nonatomic, strong) NSTimer *timer;

@end

@interface MenuItemSourceTextBar () <UITextFieldDelegate>

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIStackView *contentStackView;
@property (nonatomic, strong) UILabel *cancelLabel;
@property (nonatomic, strong) NSMutableArray <MenuItemSourceTextBarFieldObserver *> *textObservers;

@end

@implementation MenuItemSourceTextBar

- (id)init
{
    self = [super init];
    if(self) {
        
        self.backgroundColor = [UIColor whiteColor];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        const CGFloat spacing = ceilf(MenusDesignDefaultContentSpacing / 2.0);
        {
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
            self.stackView = stackView;
        }
        {
            UIView *contentView = [[UIView alloc] init];
            contentView.translatesAutoresizingMaskIntoConstraints = NO;
            contentView.layer.borderColor = [[WPStyleGuide greyLighten20] CGColor];
            contentView.layer.borderWidth = 1.0;
            contentView.backgroundColor = [UIColor whiteColor];
            
            [self.stackView addArrangedSubview:contentView];
            self.contentView = contentView;
            
            UIStackView *contentStackView = [[UIStackView alloc] init];
            contentStackView.translatesAutoresizingMaskIntoConstraints = NO;
            contentStackView.distribution = UIStackViewDistributionFill;
            contentStackView.alignment = UIStackViewAlignmentFill;
            contentStackView.axis = UILayoutConstraintAxisHorizontal;
            contentStackView.spacing = spacing;
            
            [contentView addSubview:contentStackView];
            
            [NSLayoutConstraint activateConstraints:@[
                                                      [contentStackView.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:spacing],
                                                      [contentStackView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor constant:spacing],
                                                      [contentStackView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor constant:-spacing],
                                                      [contentStackView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor constant:-spacing]
                                                      ]];
            
            self.contentStackView = contentStackView;
        }
        {
            UIImageView *iconView = [[UIImageView alloc] init];
            iconView.translatesAutoresizingMaskIntoConstraints = NO;
            iconView.tintColor = [WPStyleGuide greyDarken30];
            iconView.contentMode = UIViewContentModeScaleAspectFit;
            
            [self.contentStackView addArrangedSubview:iconView];
            
            NSLayoutConstraint *width = [iconView.widthAnchor constraintEqualToConstant:14.0];
            width.priority = 999;
            width.active = YES;
            
            iconView.hidden = YES;
            _iconView = iconView;
        }
        {
            UITextField *textField = [[UITextField alloc] init];
            textField.delegate = self;
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
            textField.returnKeyType = UIReturnKeyDone;
            textField.opaque = YES;
            
            [textField addTarget:self action:@selector(textFieldDidEndOnExit:) forControlEvents:UIControlEventEditingDidEndOnExit];
            [textField addTarget:self action:@selector(textFieldValueDidChange:) forControlEvents:UIControlEventEditingChanged];
            
            UIFont *font = [WPFontManager systemRegularFontOfSize:16.0];
            textField.font = font;
            
            [self.contentStackView addArrangedSubview:textField];
            
            [textField setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
            
            _textField = textField;
        }
        {
            UILabel *label = [[UILabel alloc] init];
            label.text = NSLocalizedString(@"Cancel", @"Menus cancel button within text bar while editing items.");
            label.textColor = [WPStyleGuide greyDarken20];
            label.font = [WPFontManager systemRegularFontOfSize:14.0];
            label.userInteractionEnabled = YES;
            [self.stackView addArrangedSubview:label];
            
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelTapGesture:)];
            [label addGestureRecognizer:tap];
            
            [label setContentHuggingPriority:UILayoutPriorityDefaultHigh forAxis:UILayoutConstraintAxisHorizontal];
            
            self.cancelLabel = label;
            [self setCancelLabelHidden:YES animated:NO];
        }
    }
    
    return self;
}

- (id)initAsSearchBar
{
    self = [self init];
    if(self) {
        
        self.iconView.image = [[UIImage imageNamed:@"icon-menus-search"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.iconView.hidden = NO;
        
        UIFont *font = [WPFontManager systemRegularFontOfSize:16.0];
        NSString *placeholder = NSLocalizedString(@"Search...", @"Menus search bar placeholder text.");
        NSDictionary *attributes = @{NSFontAttributeName: font, NSForegroundColorAttributeName: [WPStyleGuide greyLighten10]};
        self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:attributes];
    }
    
    return self;
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
    if([self.textField isFirstResponder]) {
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
    if(self.cancelLabel.hidden != hidden) {
        
        void(^toggleButton)() = ^() {
            self.cancelLabel.hidden = hidden;
            self.cancelLabel.alpha = hidden ? 0.0 : 1.0;
        };
        
        if(animated) {
            [UIView animateWithDuration:0.20 animations:^{
                toggleButton();
            }];
        }else {
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
