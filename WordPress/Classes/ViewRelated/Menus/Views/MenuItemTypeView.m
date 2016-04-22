#import "MenuItemTypeView.h"
#import "WPStyleGuide.h"
#import "WPFontManager.h"
#import "Menu+ViewDesign.h"
#import "MenuItem+ViewDesign.h"

@import Gridicons;

@interface MenuItemTypeView ()

@property (nonatomic, strong) UIStackView *stackView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UIImageView *arrowView;

@end

@implementation MenuItemTypeView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)init
{
    self = [super init];
    if (self) {
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor whiteColor];
        self.contentMode = UIViewContentModeRedraw;
        
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
            self.stackView = stackView;
        }
        {
            UIImageView *iconView = [[UIImageView alloc] init];
            iconView.translatesAutoresizingMaskIntoConstraints = NO;
            iconView.contentMode = UIViewContentModeScaleAspectFit;
            iconView.backgroundColor = [UIColor whiteColor];
            iconView.tintColor = [WPStyleGuide grey];
            
            [self.stackView addArrangedSubview:iconView];
            
            NSLayoutConstraint *widthConstraint = [iconView.widthAnchor constraintEqualToConstant:MenusDesignItemIconSize];
            widthConstraint.priority = 999;
            widthConstraint.active = YES;
            
            self.iconView = iconView;
        }
        {
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.numberOfLines = 5;
            label.lineBreakMode = NSLineBreakByTruncatingTail;
            label.font = [WPStyleGuide tableviewTextFont];
            label.backgroundColor = [UIColor whiteColor];
            
            [self.stackView addArrangedSubview:label];
            
            [label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
            [label setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
            
            self.label = label;
        }
        {
            UIImageView *iconView = [[UIImageView alloc] init];
            iconView.translatesAutoresizingMaskIntoConstraints = NO;
            iconView.contentMode = UIViewContentModeScaleAspectFit;
            iconView.backgroundColor = [UIColor whiteColor];
            iconView.tintColor = [WPStyleGuide grey];
            iconView.image = [Gridicon iconOfType:GridiconTypeChevronRight];
            
            [self.stackView addArrangedSubview:iconView];
            
            NSLayoutConstraint *widthConstraint = [iconView.widthAnchor constraintEqualToConstant:MenusDesignItemIconSize];
            widthConstraint.priority = 999;
            widthConstraint.active = YES;
            
            self.arrowView = iconView;
            [self hideArrowView];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChangeNotification:) name:UIDeviceOrientationDidChangeNotification object:nil];
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tellDelegateTypeWasSelected)];
        [self addGestureRecognizer:tap];
    }
    
    return self;
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
    self.label.textColor = self.selected ? [WPStyleGuide wordPressBlue] : [WPStyleGuide greyDarken30];
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
    CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten30] CGColor]);
    
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
