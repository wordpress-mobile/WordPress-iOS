#import "MenusSelectionDetailView.h"
#import "Menu+ViewDesign.h"
#import "MenusSelectionView.h"
#import <WordPressShared/WPFontManager.h>
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

@import Gridicons;

@interface MenusSelectionDetailView ()

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, strong, readonly) UIStackView *labelsStackView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subTitleLabel;
@property (nonatomic, strong, readonly) UIImageView *iconView;
@property (nonatomic, strong, readonly) UIImageView *accessoryView;

@end

@implementation MenusSelectionDetailView

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.translatesAutoresizingMaskIntoConstraints = NO;

    UIEdgeInsets margins = UIEdgeInsetsZero;
    CGFloat spacing = MenusDesignDefaultContentSpacing;
    // Spacing + tweak for design stroke offset.
    margins.left = spacing;
    margins.right = spacing;
    self.stackView.layoutMargins = margins;
    self.stackView.layoutMarginsRelativeArrangement = YES;
    self.stackView.distribution = UIStackViewDistributionFill;
    self.stackView.alignment = UIStackViewAlignmentCenter;
    self.stackView.spacing = spacing;

    [self setupIconView];
    [self setupLabelsStackView];
    [self setupSubtTitleLabel];
    [self setupTitleLabel];
    [self setupAccessoryView];

    self.backgroundColor = [UIColor clearColor];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tellDelegateTapGestureRecognized:)];
    [self addGestureRecognizer:tap];
}

- (void)setupIconView
{
    UIImageView *iconView = [[UIImageView alloc] init];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.tintColor = [UIColor murielListIcon];
    [iconView.widthAnchor constraintEqualToConstant:24].active = YES;
    [iconView.heightAnchor constraintEqualToConstant:24].active = YES;
    [self.stackView addArrangedSubview:iconView];
    _iconView = iconView;
}

- (void)setupLabelsStackView
{
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.layoutMargins = UIEdgeInsetsMake(14, 0, 14, 0);
    stackView.layoutMarginsRelativeArrangement = YES;
    [stackView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    _labelsStackView = stackView;

    [self.stackView addArrangedSubview:stackView];
}

- (void)setupSubtTitleLabel
{
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.font = [WPStyleGuide fontForTextStyle:UIFontTextStyleFootnote maximumPointSize:[WPStyleGuide maxFontSize]];
    label.adjustsFontForContentSizeCategory = YES;
    label.textColor = [UIColor murielTextSubtle];
    _subTitleLabel = label;

    NSAssert(_labelsStackView != nil, @"labelsStackView is nil");

    [_labelsStackView addArrangedSubview:label];
}

- (void)setupTitleLabel
{
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 1;
    label.font = [WPStyleGuide fontForTextStyle:UIFontTextStyleBody maximumPointSize:[WPStyleGuide maxFontSize]];
    label.adjustsFontForContentSizeCategory = YES;
    label.textColor = [UIColor murielText];
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.70;
    label.allowsDefaultTighteningForTruncation = YES;
    _titleLabel = label;

    NSAssert(_labelsStackView != nil, @"labelsStackView is nil");

    [_labelsStackView addArrangedSubview:label];
}

- (void)setupAccessoryView
{
    UIImageView *accessoryView = [[UIImageView alloc] init];
    accessoryView.contentMode = UIViewContentModeScaleAspectFit;
    accessoryView.image = [Gridicon iconOfType:GridiconTypeChevronDown];
    accessoryView.tintColor = [UIColor murielTextTertiary];
    [accessoryView.widthAnchor constraintEqualToConstant:24].active = YES;
    [accessoryView.heightAnchor constraintEqualToConstant:24].active = YES;
    _accessoryView = accessoryView;

    [self.stackView addArrangedSubview:accessoryView];
}

- (void)setShowsDesignActive:(BOOL)showsDesignActive
{
    if (_showsDesignActive != showsDesignActive) {
        _showsDesignActive = showsDesignActive;

        if (showsDesignActive) {
            self.accessoryView.transform = CGAffineTransformMakeScale(1.0, -1.0);
        } else  {
            self.accessoryView.transform = CGAffineTransformIdentity;
        }
    }
}

- (void)updatewithAvailableItems:(NSUInteger)numItemsAvailable selectedItem:(MenusSelectionItem *)selectedItem
{
    NSString *localizedFormat = nil;
    if ([selectedItem isMenuLocation]) {

        if (numItemsAvailable > 1) {
            localizedFormat = NSLocalizedString(@"%i menu areas in this theme", @"The number of menu areas available in the theme");
        } else  {
            localizedFormat = NSLocalizedString(@"%i menu area in this theme", @"One menu area available in the theme");
        }
        self.iconView.image = [Gridicon iconOfType:GridiconTypeLayout];

    } else  if ([selectedItem isMenu]) {

        if (numItemsAvailable > 1) {
            localizedFormat = NSLocalizedString(@"%i menus available", @"The number of menus on the site and area.");
        } else  {
            localizedFormat = NSLocalizedString(@"%i menu available", @"One menu is available in the site and area");
        }
        self.iconView.image = [Gridicon iconOfType:GridiconTypeMenus];
    }

    [self setTitleText:selectedItem.displayName subTitleText:[NSString stringWithFormat:localizedFormat, numItemsAvailable]];
}

- (void)setTitleText:(NSString *)title subTitleText:(NSString *)subtitle
{
    self.subTitleLabel.text = subtitle;
    self.titleLabel.text = title;

    [self.labelsStackView setNeedsLayout];
    [self.labelsStackView layoutIfNeeded];
}

#pragma mark - overrides

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self tellDelegateTouchesHighlightedStateChanged:YES];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self tellDelegateTouchesHighlightedStateChanged:NO];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self tellDelegateTouchesHighlightedStateChanged:NO];
}

#pragma mark - delegate helpers

- (void)tellDelegateTapGestureRecognized:(UITapGestureRecognizer *)tap
{
    if ([self.delegate respondsToSelector:@selector(selectionDetailView:tapGestureRecognized:)]) {
        [self.delegate selectionDetailView:self tapGestureRecognized:tap];
    }
}

- (void)tellDelegateTouchesHighlightedStateChanged:(BOOL)highlighted
{
    if ([self.delegate respondsToSelector:@selector(selectionDetailView:touchesHighlightedStateChanged:)]) {
        [self.delegate selectionDetailView:self touchesHighlightedStateChanged:highlighted];
    }
}

@end
