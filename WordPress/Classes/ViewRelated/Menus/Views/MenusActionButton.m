#import "MenusActionButton.h"
#import "WPStyleGuide.h"
#import "WPFontManager.h"
#import "Menu+ViewDesign.h"

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

- (void)setupStyling
{
    self.backgroundColor = [UIColor clearColor];
    
    self.adjustsImageWhenHighlighted = NO;
    self.adjustsImageWhenDisabled = NO;
        
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    self.titleLabel.font = [WPFontManager systemSemiBoldFontOfSize:18.0];
    [self setTitleColor:[WPStyleGuide wordPressBlue] forState:UIControlStateNormal];
    [self setTitleColor:[WPStyleGuide greyLighten20] forState:UIControlStateDisabled];
    
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
    }
}

- (void)updateDesignInsets
{

}

@end
