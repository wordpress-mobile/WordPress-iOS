#import "MenusSelectionItemView.h"
#import "MenusSelectionView.h"
#import "Menu+ViewDesign.h"
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

@import Gridicons;

@interface MenusSelectionItemView ()

@property (nonatomic, strong, readonly) UIStackView *stackView;
@property (nonatomic, strong, readonly) UILabel *label;
@property (nonatomic, strong, readonly) UIImageView *iconImageView;
@property (nonatomic, assign) BOOL drawsDesignLineSeparator;
@property (nonatomic, assign) BOOL drawsHighlighted;

@end

@implementation MenusSelectionItemView

- (id)init
{
    self = [super init];
    if (self) {

        self.backgroundColor = [UIColor clearColor];
        self.translatesAutoresizingMaskIntoConstraints = NO;

        [self setupStackView];
        [self setupLabel];
        [self setupIconImageView];

        _drawsDesignLineSeparator = YES; // defaults to YES

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemSelectionChanged:) name:MenusSelectionViewItemChangedSelectedNotification object:nil];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tellDelegateViewWasSelected)];
        [self addGestureRecognizer:tap];
    }

    return self;
}

- (void)setupStackView
{
    UIStackView *stackView = [[UIStackView alloc] init];
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.axis = UILayoutConstraintAxisHorizontal;
    stackView.distribution = UIStackViewDistributionFill;

    UIEdgeInsets insets = UIEdgeInsetsZero;
    insets.left = MenusDesignDefaultContentSpacing;
    insets.right = MenusDesignDefaultContentSpacing;
    stackView.layoutMargins = insets;
    stackView.layoutMarginsRelativeArrangement = YES;
    stackView.spacing = MenusDesignDefaultContentSpacing / 2.0;

    [self addSubview:stackView];
    [NSLayoutConstraint activateConstraints:@[
                                              [stackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
                                              [stackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:12],
                                              [stackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                                              [stackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-12]
                                              ]];
    _stackView = stackView;
}

- (void)setupLabel
{
    UILabel *label = [[UILabel alloc] init];
    label.backgroundColor = [UIColor clearColor];
    label.font = [WPStyleGuide fontForTextStyle:UIFontTextStyleSubheadline maximumPointSize:[WPStyleGuide maxFontSize]];
    label.adjustsFontForContentSizeCategory = YES;
    label.textColor = [UIColor murielText];
    [self addSubview:label];
    _label = label;

    NSAssert(_stackView != nil, @"stackView is nil");
    [self.stackView addArrangedSubview:label];
}

- (void)setupIconImageView
{
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.tintColor = [UIColor murielNeutral40];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.image = [Gridicon iconOfType:GridiconTypeCheckmark];

    NSLayoutConstraint *width = [imageView.widthAnchor constraintEqualToConstant:20.0];
    width.priority = 999;
    NSLayoutConstraint *height = [imageView.heightAnchor constraintEqualToConstant:width.constant];

    [NSLayoutConstraint activateConstraints:@[width, height]];

    NSAssert(_stackView != nil, @"stackView is nil");
    [self.stackView addArrangedSubview:imageView];
    imageView.hidden = YES;

    _iconImageView = imageView;
}

- (void)setItem:(MenusSelectionItem *)item
{
    if (_item != item) {
        _item = item;
    }
    self.label.text = item.displayName;
    self.iconImageView.hidden = !item.selected;
}

- (void)setDrawsDesignLineSeparator:(BOOL)drawsDesignLineSeparator
{
    if (_drawsDesignLineSeparator != drawsDesignLineSeparator) {
        _drawsDesignLineSeparator = drawsDesignLineSeparator;
        [self setNeedsDisplay];
    }
}

- (void)setDrawsHighlighted:(BOOL)drawsHighlighted
{
    if (_drawsHighlighted != drawsHighlighted) {
        _drawsHighlighted = drawsHighlighted;

        [self.previousItemView setNeedsDisplay];
        [self.nextItemView setNeedsDisplay];
        self.drawsDesignLineSeparator = !drawsHighlighted;
        [self setNeedsDisplay];
    }
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    [self setNeedsDisplay];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (self.drawsHighlighted) {

        [[UIColor murielNeutral5] set];
        CGContextFillRect(context, rect);

    } else  if (self.drawsDesignLineSeparator) {

        // draw the line separator
        CGContextSetLineWidth(context, MenusDesignStrokeWidth);

        if (self.nextItemView && !self.nextItemView.drawsHighlighted) {
            // draw a line on the bottom
            CGContextMoveToPoint(context, MenusDesignDefaultContentSpacing, rect.size.height - (MenusDesignStrokeWidth / 2.0));
            CGContextAddLineToPoint(context, rect.size.width, rect.size.height - (MenusDesignStrokeWidth / 2.0));
        }

        CGContextSetStrokeColorWithColor(context, [[UIColor murielNeutral10] CGColor]);
        CGContextStrokePath(context);
    }
}

#pragma mark - delegate helpers

- (void)tellDelegateViewWasSelected
{
    [self.delegate selectionItemViewWasSelected:self];
}

#pragma mark - touches

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.drawsHighlighted = YES;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.drawsHighlighted = NO;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.drawsHighlighted = NO;
}

#pragma mark - notifications

- (void)itemSelectionChanged:(NSNotification *)notification
{
    self.iconImageView.hidden = !self.item.selected;
}

@end
