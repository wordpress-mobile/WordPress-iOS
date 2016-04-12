#import "MenusSelectionDetailView.h"
#import "WPStyleGuide.h"
#import "Menu+ViewDesign.h"
#import "MenusSelectionView.h"

@import Gridicons;

@interface MenusSelectionDetailView ()

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) UIStackView *labelsStackView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UIImageView *accessoryView;

@end

@implementation MenusSelectionDetailView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setupArrangedViews];
    [self setupStyling];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tellDelegateTapGestureRecognized:)];
    [self addGestureRecognizer:tap];
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

- (void)setupStyling
{
    self.backgroundColor = [UIColor clearColor];
}

- (void)setupArrangedViews
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    {
        UIStackView *stackView = self.stackView;
        UIEdgeInsets margins = UIEdgeInsetsZero;
        CGFloat spacing = MenusDesignDefaultContentSpacing;
        if (IS_IPHONE) {
            // If we know we're on an iPhone and the screen is 320pts, lessen the padding.
            // Otherwise things get a bit crowded.
            CGRect screenBounds = [UIScreen mainScreen].bounds;
            if (screenBounds.size.width == 320 || screenBounds.size.height == 320) {
                spacing = MenusDesignDefaultContentSpacing / 2.0;
            }
        }
        margins.left = spacing;
        margins.right = spacing;
        stackView.layoutMargins = margins;
        stackView.layoutMarginsRelativeArrangement = YES;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.alignment = UIStackViewAlignmentCenter;
        stackView.spacing = spacing;
    }
    {
        UIImageView *iconView = [[UIImageView alloc] init];
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        iconView.tintColor = [WPStyleGuide darkBlue];
        [iconView.widthAnchor constraintEqualToConstant:30].active = YES;
        [iconView.heightAnchor constraintEqualToConstant:30].active = YES;
        [self.stackView addArrangedSubview:iconView];
        self.iconView = iconView;
    }
    {
        UIStackView *stackView = [[UIStackView alloc] init];
        stackView.alignment = UIStackViewAlignmentFill;
        stackView.distribution = UIStackViewDistributionFill;
        stackView.axis = UILayoutConstraintAxisVertical;
        [stackView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [self.stackView addArrangedSubview:stackView];
        self.labelsStackView = stackView;
    }
    {
        UILabel *label = [[UILabel alloc] init];
        label.numberOfLines = 0;
        label.font = [WPStyleGuide subtitleFont];
        label.textColor = [WPStyleGuide grey];
        self.subTitleLabel = label;
        [self.labelsStackView addArrangedSubview:label];
    }
    {
        UILabel *label = [[UILabel alloc] init];
        label.numberOfLines = 1;
        label.font = [WPStyleGuide regularTextFontSemiBold];
        label.textColor = [WPStyleGuide darkGrey];
        label.adjustsFontSizeToFitWidth = YES;
        label.minimumScaleFactor = 0.50;
        label.allowsDefaultTighteningForTruncation = YES;
        self.titleLabel = label;
        [self.labelsStackView addArrangedSubview:label];
    }
    {
        UIImageView *accessoryView = [[UIImageView alloc] init];
        accessoryView.contentMode = UIViewContentModeScaleAspectFit;
        accessoryView.image = [Gridicon iconOfType:GridiconTypeChevronDown];
        accessoryView.tintColor = [WPStyleGuide mediumBlue];
        [accessoryView.widthAnchor constraintEqualToConstant:30].active = YES;
        [accessoryView.heightAnchor constraintEqualToConstant:30].active = YES;
        [self.stackView addArrangedSubview:accessoryView];
        self.accessoryView = accessoryView;
    }
}

- (void)setShowsDesignActive:(BOOL)showsDesignActive
{
    if (_showsDesignActive != showsDesignActive) {
        _showsDesignActive = showsDesignActive;
        
        if (showsDesignActive) {
            self.accessoryView.transform = CGAffineTransformMakeScale(0.5, 0.5);
            self.accessoryView.alpha = 0.0;
        } else  {
            self.accessoryView.transform = CGAffineTransformIdentity;
            self.accessoryView.alpha = 1.0;
        }
    }
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
