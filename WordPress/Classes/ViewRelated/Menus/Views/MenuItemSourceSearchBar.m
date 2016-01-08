#import "MenuItemSourceSearchBar.h"
#import "MenusDesign.h"
#import "WPStyleGuide.h"
#import "WPFontManager.h"

@interface MenuItemSourceSearchBar () <UITextFieldDelegate>

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIStackView *contentStackView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *cancelLabel;

@end

@implementation MenuItemSourceSearchBar

- (id)init
{
    self = [super init];
    if(self) {
        
        self.backgroundColor = [UIColor whiteColor];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        UIEdgeInsets margin = UIEdgeInsetsZero;
        margin.top = MenusDesignDefaultContentSpacing / 2.0;
        margin.left = MenusDesignDefaultContentSpacing;
        margin.right = MenusDesignDefaultContentSpacing;
        margin.bottom = MenusDesignDefaultContentSpacing / 2.0;
        self.layoutMargins = margin;
        UILayoutGuide *marginsGuide = self.layoutMarginsGuide;
        const CGFloat spacing = ceilf(MenusDesignDefaultContentSpacing / 2.0);
        {
            UIStackView *stackView = [[UIStackView alloc] init];
            stackView.translatesAutoresizingMaskIntoConstraints = NO;
            stackView.distribution = UIStackViewDistributionFill;
            stackView.alignment = UIStackViewAlignmentFill;
            stackView.axis = UILayoutConstraintAxisHorizontal;
            stackView.spacing = spacing;
            
            [self addSubview:stackView];
            
            [NSLayoutConstraint activateConstraints:@[
                                                      [stackView.topAnchor constraintEqualToAnchor:marginsGuide.topAnchor],
                                                      [stackView.leadingAnchor constraintEqualToAnchor:marginsGuide.leadingAnchor],
                                                      [stackView.trailingAnchor constraintEqualToAnchor:marginsGuide.trailingAnchor],
                                                      [stackView.bottomAnchor constraintEqualToAnchor:marginsGuide.bottomAnchor]
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
            iconView.image = [[UIImage imageNamed:@"icon-menus-search"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            iconView.contentMode = UIViewContentModeScaleAspectFit;
            
            [self.contentStackView addArrangedSubview:iconView];
            
            [NSLayoutConstraint activateConstraints:@[
                                                      [iconView.widthAnchor constraintEqualToConstant:14.0],
                                                      ]];
            
            self.iconView = iconView;
        }
        {
            UITextField *textField = [[UITextField alloc] init];
            textField.delegate = self;
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
            textField.returnKeyType = UIReturnKeyDone;
            textField.opaque = YES;
            
            [textField addTarget:self action:@selector(textFieldDidEndOnExit:) forControlEvents:UIControlEventEditingDidEndOnExit];
            [textField addTarget:self action:@selector(textFieldValueDidChange:) forControlEvents:UIControlEventValueChanged];
            
            UIFont *font = [WPFontManager openSansRegularFontOfSize:16.0];
            NSString *placeholder = NSLocalizedString(@"Search...", @"Menus search bar placeholder text.");
            NSDictionary *attributes = @{NSFontAttributeName: font, NSForegroundColorAttributeName: [WPStyleGuide greyLighten10]};
            textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder attributes:attributes];
            textField.font = font;
            
            [self.contentStackView addArrangedSubview:textField];
            
            [textField setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
            
            self.textField = textField;
        }
        {
            UILabel *label = [[UILabel alloc] init];
            label.text = NSLocalizedString(@"Cancel", @"Menus cancel button for searching items.");
            label.textColor = [WPStyleGuide greyDarken20];
            label.font = [WPFontManager openSansRegularFontOfSize:14.0];
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
    [self.delegate sourceSearchBarDidBeginSearching:self];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self setCancelLabelHidden:YES animated:YES];
    [self.delegate sourceSearchBarDidEndSearching:self];
}

- (void)textFieldValueDidChange:(UITextField *)textField
{
    [self.delegate sourceSearchBar:self didUpdateSearchWithText:textField.text];
}

- (void)textFieldDidEndOnExit:(UITextField *)textField
{
    [textField resignFirstResponder];
}

@end
