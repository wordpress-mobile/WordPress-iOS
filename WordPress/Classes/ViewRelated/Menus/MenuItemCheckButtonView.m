#import "MenuItemCheckButtonView.h"
#import "Menu+ViewDesign.h"
#import <WordPressShared/WPFontManager.h>
#import <WordPressShared/WPStyleGuide.h>
#import "WordPress-Swift.h"

@import Gridicons;

static CGFloat const iconPadding = 3.0;

@interface MenuItemCheckButtonView ()

@property (nonatomic, strong, readonly) UIImageView *iconView;
@property (nonatomic, assign) BOOL drawsHighlighted;
@property (nonatomic, assign) CGPoint touchesBeganLocation;

@end

@implementation MenuItemCheckButtonView

- (id)init
{
    self = [super init];
    if (self) {

        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;

        [self setupIconView];
        [self setupLabel];
    }

    return self;
}

- (void)setupIconView
{
    UIImageView *iconView = [[UIImageView alloc] init];
    iconView.translatesAutoresizingMaskIntoConstraints = NO;
    iconView.image = [Gridicon iconOfType:GridiconTypeCheckmark];
    iconView.tintColor = [UIColor murielListIcon];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.backgroundColor = [UIColor clearColor];
    iconView.alpha = 0.0;
    [self addSubview:iconView];

    [NSLayoutConstraint activateConstraints:@[
                                              [iconView.topAnchor constraintEqualToAnchor:self.topAnchor constant:iconPadding],
                                              [iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:iconPadding],
                                              [iconView.widthAnchor constraintEqualToAnchor:iconView.heightAnchor],
                                              [iconView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-iconPadding]
                                              ]];
    _iconView = iconView;
}

- (void)setupLabel
{
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.backgroundColor = [UIColor clearColor];

    NSDictionary *attributes = [self attributesForText];
    label.font = [attributes objectForKey:NSFontAttributeName];
    label.textColor = [UIColor murielTextSubtle];

    [self addSubview:label];

    NSAssert(_iconView != nil, @"iconView is nil");

    [NSLayoutConstraint activateConstraints:@[
                                              [label.topAnchor constraintEqualToAnchor:self.topAnchor],
                                              [label.leadingAnchor constraintEqualToAnchor:_iconView.trailingAnchor constant:MenusDesignDefaultContentSpacing / 2.0],
                                              [label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                                              [label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
                                              ]];

    _label = label;
}

- (CGFloat)preferredHeightForLayout
{
    CGSize size = [self.label.text sizeWithAttributes:[self attributesForText]];
    return size.height;
}

- (void)setChecked:(BOOL)checked
{
    if (_checked != checked) {
        _checked = checked;
        self.iconView.alpha = checked ? 1.0 : 0.0;
        self.drawsHighlighted = checked;
    }
}

- (void)setDrawsHighlighted:(BOOL)drawsHighlighted
{
    if (_drawsHighlighted != drawsHighlighted) {
        _drawsHighlighted = drawsHighlighted;
        [self setNeedsDisplay];
    }
}

- (NSDictionary *)attributesForText
{
    return @{NSFontAttributeName: [WPFontManager systemRegularFontOfSize:14.0], NSForegroundColorAttributeName: [UIColor murielText]};
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    if (self.drawsHighlighted) {
        CGContextSetFillColorWithColor(context, [[UIColor murielPrimary40] CGColor]);
    } else  {
        CGContextSetFillColorWithColor(context, [[UIColor murielNeutral10] CGColor]);
    }

    CGRect boxRect = CGRectZero;
    boxRect.size.height = rect.size.height;
    boxRect.size.width = boxRect.size.height;

    CGContextFillRect(context, boxRect);

    CGRect innerBoxRect = CGRectInset(boxRect, 1.0, 1.0);
    CGContextSetFillColorWithColor(context, [self.backgroundColor CGColor]);
    CGContextFillRect(context, innerBoxRect);
}

#pragma mark - touches

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];

    self.touchesBeganLocation = [[touches anyObject] locationInView:self];
    self.drawsHighlighted = YES;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];

    self.touchesBeganLocation = CGPointZero;
    self.drawsHighlighted = NO;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];

    self.drawsHighlighted = NO;

    if (CGRectContainsPoint(self.bounds, self.touchesBeganLocation) && CGRectContainsPoint(self.bounds, [[touches anyObject] locationInView:self])) {
        self.checked = !self.checked;
        if (self.onChecked) {
            self.onChecked();
        }
    }
}

@end
