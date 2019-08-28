#import "MenuItemTypeSelectionView.h"
#import "Menu+ViewDesign.h"
#import "MenuItem+ViewDesign.h"
#import <WordPressShared/WPFontManager.h>
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

@import Gridicons;

@interface MenuItemTypeSelectionView ()

@property (nonatomic, strong, readonly) UIStackView *stackView;
@property (nonatomic, strong, readonly) UILabel *label;
@property (nonatomic, strong, readonly) UIImageView *iconView;
@property (nonatomic, strong, readonly) UIImageView *arrowView;

@end

@implementation MenuItemTypeSelectionView

- (id)init
{
    self = [super init];
    if (self) {

        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor murielListForeground];
        self.contentMode = UIViewContentModeRedraw;

        [self setupStackView];
        [self setupIconView];
        [self setupLabel];
        [self setupArrowIconView];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChangeNotification:) name:UIDeviceOrientationDidChangeNotification object:nil];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tellDelegateTypeWasSelected)];
        [self addGestureRecognizer:tap];
    }

    return self;
}

- (void)setupStackView
{
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.alignment = UIStackViewAlignmentFill;
    stackView.distribution = UIStackViewDistributionFill;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.spacing = MenusDesignDefaultContentSpacing;

    [self addSubview:stackView];

    NSLayoutConstraint *leading = [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:MenusDesignDefaultContentSpacing];
    leading.priority = UILayoutPriorityDefaultHigh;

    NSLayoutConstraint *trailing = [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-MenusDesignDefaultContentSpacing];
    trailing.priority = UILayoutPriorityDefaultHigh;

    [NSLayoutConstraint activateConstraints:@[
                                              leading,
                                              [stackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:MenusDesignDefaultContentSpacing],
                                              trailing,
                                              [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-MenusDesignDefaultContentSpacing]
                                              ]];
    _stackView = stackView;
}

- (void)setupIconView
{
    UIImageView *iconView = [[UIImageView alloc] init];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.backgroundColor = [UIColor clearColor];
    iconView.tintColor = [UIColor murielListIcon];

    NSAssert(_stackView != nil, @"stackView is nil");
    [_stackView addArrangedSubview:iconView];

    NSLayoutConstraint *widthConstraint = [iconView.widthAnchor constraintEqualToConstant:MenusDesignItemIconSize];
    widthConstraint.priority = 999;
    widthConstraint.active = YES;

    _iconView = iconView;
}

- (void)setupLabel
{
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 5;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    label.font = [WPStyleGuide tableviewTextFont];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor murielNeutral60];

    NSAssert(_stackView != nil, @"stackView is nil");
    [_stackView addArrangedSubview:label];

    [label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [label setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    _label = label;
}

- (void)setupArrowIconView
{
    UIImageView *iconView = [[UIImageView alloc] init];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.backgroundColor = [UIColor clearColor];
    iconView.tintColor = [UIColor murielListIcon];
    iconView.image = [Gridicon iconOfType:GridiconTypeChevronRight];

    NSAssert(_stackView != nil, @"stackView is nil");
    [_stackView addArrangedSubview:iconView];

    NSLayoutConstraint *widthConstraint = [iconView.widthAnchor constraintEqualToConstant:MenusDesignItemIconSize];
    widthConstraint.priority = 999;
    widthConstraint.active = YES;

    iconView.alpha = 0.0;
    iconView.hidden = YES;
    _arrowView = iconView;

}

- (void)setSelected:(BOOL)selected
{
    if (_selected != selected) {
        _selected = selected;
        [self updateSelection];
    }
}

- (void)setItemType:(NSString *)itemType
{
    if (_itemType != itemType) {
        _itemType = itemType;
        self.iconView.image = [MenuItem iconImageForItemType:itemType];
        [self setNeedsDisplay];
    }
}

- (void)setItemTypeLabel:(NSString *)itemTypeLabel
{
    if (_itemTypeLabel != itemTypeLabel) {
        _itemTypeLabel = itemTypeLabel;
        self.label.text = itemTypeLabel;
    }
}

- (void)updateSelection
{
    self.label.textColor = self.selected ? [UIColor murielPrimary] : [UIColor murielNeutral60];
    if (self.selected && ![self.delegate typeViewRequiresCompactLayout:self]) {
        [self showArrowView];
    } else  {
        [self hideArrowView];
    }
    [self setNeedsDisplay];
}

- (void)updateDesignForLayoutChangeIfNeeded
{
    [self updateSelection];
}

- (void)showArrowView
{
    if (self.arrowView.hidden) {
        self.arrowView.alpha = 1.0;
        self.arrowView.hidden = NO;
    }
}

- (void)hideArrowView
{
    if (!self.arrowView.hidden) {
        self.arrowView.alpha = 0.0;
        self.arrowView.hidden = YES;
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    CGContextSetLineWidth(context, 2.0);
    CGContextSetStrokeColorWithColor(context, [[UIColor murielNeutral5] CGColor]);

    if (self.selected) {

        if (!self.designIgnoresDrawingTopBorder) {
            CGContextMoveToPoint(context, 0, 0);
            CGContextAddLineToPoint(context, rect.size.width, 0);
        }

        CGContextMoveToPoint(context, 0, rect.size.height);
        CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
        CGContextStrokePath(context);

    } else  {

        CGContextMoveToPoint(context, rect.size.width, 0);
        CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
        CGContextStrokePath(context);
    }

    CGContextRestoreGState(context);
}

#pragma mark - delegate

- (void)tellDelegateTypeWasSelected
{
    [self.delegate typeViewPressedForSelection:self];
}

#pragma mark - notifications

- (void)deviceOrientationDidChangeNotification:(NSNotification *)notification
{
    [self updateSelection];
}

@end
