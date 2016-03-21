#import "MenusSelectionDetailView.h"
#import "WPStyleGuide.h"
#import "Menu+ViewDesign.h"
#import "MenusSelectionView.h"

@interface MenusSelectionDetailView ()

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, strong) UILabel *textLabel;
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

- (void)updatewithAvailableItems:(NSUInteger)numItemsAvailable selectedItem:(MenusSelectionViewItem *)selectedItem
{
    NSString *localizedFormat = nil;
    if ([selectedItem isMenuLocation]) {
        
        if (numItemsAvailable > 1) {
            localizedFormat = NSLocalizedString(@"%i menu areas in this theme", @"The number of menu areas available in the theme");
        } else  {
            localizedFormat = NSLocalizedString(@"%i menu area in this theme", @"One menu area available in the theme");
        }
        self.iconView.image = [[UIImage imageNamed:@"gridicons-layout"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
    } else  if ([selectedItem isMenu]) {
        
        if (numItemsAvailable > 1) {
            localizedFormat = NSLocalizedString(@"%i menus available", @"The number of menus on the site and area.");
        } else  {
            localizedFormat = NSLocalizedString(@"%i menu available", @"One menu is available in the site and area");
        }
        self.iconView.image = [[UIImage imageNamed:@"gridicons-menus"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
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
    
    UIEdgeInsets margins = UIEdgeInsetsZero;
    margins.left = MenusDesignDefaultContentSpacing;
    margins.right = MenusDesignDefaultContentSpacing;
    self.stackView.layoutMargins = margins;
    self.stackView.layoutMarginsRelativeArrangement = YES;
    self.stackView.distribution = UIStackViewDistributionFillProportionally;
    self.stackView.alignment = UIStackViewAlignmentCenter;
    self.stackView.spacing = MenusDesignDefaultContentSpacing;
    
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
        UILabel *label = [[UILabel alloc] init];
        label.numberOfLines = 0;
        self.textLabel = label;
        [self.stackView addArrangedSubview:label];
        [label.heightAnchor constraintEqualToAnchor:self.heightAnchor].active = YES;
    }
    {
        UIImageView *accessoryView = [[UIImageView alloc] init];
        accessoryView.contentMode = UIViewContentModeScaleAspectFit;
        accessoryView.image = [[UIImage imageNamed:@"gridicons-chevron-down"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
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
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] init];
    {
        NSDictionary *attributes =  @{NSFontAttributeName: [WPStyleGuide subtitleFont], NSForegroundColorAttributeName: [WPStyleGuide grey]};
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:subtitle attributes:attributes];
        [mutableAttributedString appendAttributedString:attributedString];
    }
    [mutableAttributedString.mutableString appendString:@"\n"];
    {
        NSDictionary *attributes =  @{NSFontAttributeName: [WPStyleGuide regularTextFontSemiBold], NSForegroundColorAttributeName: [WPStyleGuide darkGrey]};
        NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:title attributes:attributes];
        [mutableAttributedString appendAttributedString:attributedString];
    }
    
    self.textLabel.attributedText = mutableAttributedString;
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
