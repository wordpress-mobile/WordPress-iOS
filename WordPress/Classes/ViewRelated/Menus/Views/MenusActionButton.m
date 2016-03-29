#import "MenusActionButton.h"
#import "WPStyleGuide.h"
#import "WPFontManager.h"
#import "Menu+ViewDesign.h"

static CGFloat const MenusDetailsButtonDesignPadding = 2.0;

@interface MenusActionButton ()

@property (nonatomic, assign) BOOL showsDesignHighlighted;

@end

@implementation MenusActionButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupStyling];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupStyling];
    }
    
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self setNeedsDisplay];
}

- (UIImage *)templatedIconImageNamed:(NSString *)imageName
{
    return [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)setupStyling
{
    self.backgroundColor = [UIColor clearColor];
    
    self.adjustsImageWhenHighlighted = NO;
    self.adjustsImageWhenDisabled = NO;
    
    UIColor *defaultContentColor = [self defaultContentFillColor];
    
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    // tintColor used for the fill color when drawing the UIImage with the template rendering mode
    self.tintColor = defaultContentColor;
    self.backgroundFillColor = [UIColor whiteColor];
    
    self.titleLabel.font = [WPFontManager systemRegularFontOfSize:14.0];
    [self setTitleColor:defaultContentColor forState:UIControlStateNormal];
    
    [self updateDesignInsets];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    [self setNeedsDisplay];
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{    
    UIColor *fillColor = self.backgroundFillColor;
    
    const BOOL drawHighlighted = self.showsDesignHighlighted;
    const BOOL drawsDisabledHighlight = !self.enabled; // will overlay a transparent white layer to appear disabled
    
    UIBezierPath *basePath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:MenusDesignDefaultCornerRadius];
    if (self.backgroundBaseColor) {
        if (drawHighlighted) {
            [[self adjustedColorWithColor:self.backgroundBaseColor delta:-0.25] set];
        } else  {
            [self.backgroundBaseColor set];
        }
    } else  {
        [[self adjustedColorWithColor:fillColor delta:drawHighlighted ? -0.25 : -0.16] set];
    }
    
    // draw the base layer based on a darker color of the draw color
    [basePath fill];
    
    if (drawsDisabledHighlight) {
        [[UIColor colorWithWhite:1.0 alpha:0.55] set];
        [basePath fill];
    }

    // draw the actual fill color on top of the base layer
    [fillColor set];
    CGRect fillRect = rect;
    // add height padding for design parity with web
    fillRect.size.height -= MenusDetailsButtonDesignPadding / 2.0;
    UIBezierPath *fillPath = [UIBezierPath bezierPathWithRoundedRect:fillRect cornerRadius:MenusDesignDefaultCornerRadius];
    // scale down the fill rect to maintain the corner radius and inset the fill
    CGFloat scalePointDelta = MenusDetailsButtonDesignPadding;
    CGAffineTransform transform = CGAffineTransformMakeScale((fillRect.size.width - scalePointDelta) / fillRect.size.width, (fillRect.size.height - scalePointDelta) / fillRect.size.height);
    // reposition the scaled path
    CGFloat translateY = drawHighlighted ? scalePointDelta : scalePointDelta / 2;
    transform = CGAffineTransformTranslate(transform, scalePointDelta / 2, translateY);
    [fillPath applyTransform:transform];
    [fillPath fill];
    
    if (drawsDisabledHighlight) {
        [[UIColor colorWithWhite:1.0 alpha:0.75] set];
        [fillPath fill];
    }
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    BOOL begin = [super beginTrackingWithTouch:touch withEvent:event];
    self.showsDesignHighlighted = YES;
    return begin;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    [super endTrackingWithTouch:touch withEvent:event];
    self.showsDesignHighlighted = NO;
}

- (void)cancelTrackingWithEvent:(UIEvent *)event
{
    [super cancelTrackingWithEvent:event];
    self.showsDesignHighlighted = NO;
}

#pragma mark - private

- (void)setShowsDesignHighlighted:(BOOL)showsDesignHighlighted
{
    if (_showsDesignHighlighted != showsDesignHighlighted) {
        _showsDesignHighlighted = showsDesignHighlighted;
        [self setNeedsDisplay];
        [self updateDesignInsets];
    }
}

- (void)updateDesignInsets
{
    const BOOL highlighted = self.showsDesignHighlighted;
    // inset the imageView image % of the ideal width of the button
    // if we don't have a width, default to 20pt inset
    // this draws a nicely sized image within the button
    UIEdgeInsets imageEdgeInsets = UIEdgeInsetsZero;
    CGFloat imageInsetHorizontal = self.frame.size.width ? (self.frame.size.width * 0.22) : 20;
    CGFloat imageInsetVertical = self.frame.size.height ? (self.frame.size.height * 0.22) : 10;

    imageEdgeInsets.left = imageInsetHorizontal;
    imageEdgeInsets.top = imageInsetVertical;
    imageEdgeInsets.right = imageInsetHorizontal;
    imageEdgeInsets.bottom = imageInsetVertical;
    
    UIEdgeInsets titleEdgeInsets = UIEdgeInsetsZero;
    
    if (highlighted) {
        imageEdgeInsets.top += MenusDetailsButtonDesignPadding;
        titleEdgeInsets.top += MenusDetailsButtonDesignPadding;
    } else  {
        imageEdgeInsets.bottom += MenusDetailsButtonDesignPadding;
        titleEdgeInsets.bottom += MenusDetailsButtonDesignPadding;
    }
    
    self.imageEdgeInsets = imageEdgeInsets;
    self.titleEdgeInsets = titleEdgeInsets;
}

- (UIColor *)defaultContentFillColor
{
    return [UIColor colorWithRed:0.133 green:0.204 blue:0.259 alpha:1.000];
}

- (UIColor *)adjustedColorWithColor:(UIColor *)color delta:(CGFloat)delta
{
    CGFloat r, g, b, a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    return [UIColor colorWithRed:r + delta green:g + delta blue:b + delta alpha:a];
}

@end
