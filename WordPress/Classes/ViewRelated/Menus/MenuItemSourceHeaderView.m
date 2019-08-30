#import "MenuItemSourceHeaderView.h"
#import "MenuItem+ViewDesign.h"
#import <WordPressShared/WPFontManager.h>
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

@import Gridicons;

@interface MenuItemSourceHeaderView ()

@property (nonatomic, strong, readonly) UIStackView *stackView;
@property (nonatomic, strong, readonly) UIImageView *iconView;

@end

@implementation MenuItemSourceHeaderView

- (id)init
{
    self = [super init];
    if (self) {

        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor murielListForeground];
        self.contentMode = UIViewContentModeRedraw;

        [self setupStackView];
        [self setupIconView];
        [self setupTitleLabel];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
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

    NSLayoutConstraint *top = [stackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:MenusDesignDefaultContentSpacing];
    top.priority = 999;

    NSLayoutConstraint *bottom = [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-MenusDesignDefaultContentSpacing];
    bottom.priority = 999;

    [NSLayoutConstraint activateConstraints:@[
                                              top,
                                              [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:MenusDesignDefaultContentSpacing],
                                              bottom,
                                              [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-MenusDesignDefaultContentSpacing]
                                              ]];
    [stackView setContentCompressionResistancePriority:999 forAxis:UILayoutConstraintAxisVertical];
    _stackView = stackView;
}

- (void)setupIconView
{
    UIImageView *iconView = [[UIImageView alloc] init];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.backgroundColor = [UIColor clearColor];
    iconView.tintColor = [UIColor murielNeutral30];
    iconView.image = [Gridicon iconOfType:GridiconTypeChevronLeft];

    NSAssert(_stackView != nil, @"stackView is nil");
    [_stackView addArrangedSubview:iconView];

    NSLayoutConstraint *widthConstraint = [iconView.widthAnchor constraintEqualToConstant:MenusDesignItemIconSize];
    widthConstraint.active = YES;

    _iconView = iconView;
}

- (void)setupTitleLabel
{
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 1;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    label.font = [WPFontManager systemRegularFontOfSize:16.0];
    label.backgroundColor = [UIColor clearColor];

    NSAssert(_stackView != nil, @"stackView is nil");
    [_stackView addArrangedSubview:label];

    [label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [label setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    _titleLabel = label;
}

- (void)tapGesture:(UITapGestureRecognizer *)tapGesture
{
    [self.delegate sourceHeaderViewSelected:self];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 2.0);
    CGContextSetStrokeColorWithColor(context, [[UIColor murielNeutral5] CGColor]);
    CGContextMoveToPoint(context, 0, rect.size.height);
    CGContextAddLineToPoint(context, rect.size.width, rect.size.height);
    CGContextStrokePath(context);
}

@end
