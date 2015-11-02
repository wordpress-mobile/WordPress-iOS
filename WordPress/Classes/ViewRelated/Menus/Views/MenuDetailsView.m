#import "MenuDetailsView.h"
#import "Menu.h"
#import "WPStyleGuide.h"
#import "UIColor+Helpers.h"
#import "WPFontManager.h"

static CGFloat const MenusDetailsButtonDesignPadding = 2.0;

@interface MenusDetailsButton : UIButton

@property (nonatomic, copy) UIColor *backgroundDrawColor;
@property (nonatomic, copy) UIColor *borderDrawColor;

@end

@implementation MenusDetailsButton

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor clearColor];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
//    CGContextRef context = UIGraphicsGetCurrentContext();
    const CGFloat cornerRadius = 4.0;
    {
        // draw the base layer based on a darker color of the draw color
        [[self darkerBaseColorWithColor:self.backgroundDrawColor] set];
        [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius] fill];
    }
    {
        // draw the actual fill color on top of the base layer
        [self.backgroundDrawColor set];
        
        CGRect fillRect = rect;
        // add height padding for design parity with web
        fillRect.size.height -= MenusDetailsButtonDesignPadding / 2.0;
        UIBezierPath *fillPath = [UIBezierPath bezierPathWithRoundedRect:fillRect cornerRadius:cornerRadius];
        // scale down the fill rect to maintain the corner radius and inset the fill
        CGFloat scalePointDelta = MenusDetailsButtonDesignPadding;
        CGAffineTransform transform = CGAffineTransformMakeScale((fillRect.size.width - scalePointDelta) / fillRect.size.width, (fillRect.size.height - scalePointDelta) / fillRect.size.height);
        // re-center the scaled path
        transform = CGAffineTransformTranslate(transform, scalePointDelta / 2, scalePointDelta / 2);
        [fillPath applyTransform:transform];
        [fillPath fill];
    }
}

- (UIColor *)darkerBaseColorWithColor:(UIColor *)color
{
    CGFloat r, g, b, a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    return [UIColor colorWithRed:r - 0.16 green:g - 0.16 blue:b - 0.16 alpha:a];
}

@end

@interface MenuDetailsView ()

@property (nonatomic, weak) IBOutlet UIStackView *stackView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet MenusDetailsButton *trashButton;
@property (nonatomic, weak) IBOutlet MenusDetailsButton *saveButton;

@end

@implementation MenuDetailsView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setupStyling];
}

- (void)setupStyling
{
    self.backgroundColor = [UIColor clearColor];
    self.titleLabel.font = [WPFontManager openSansLightFontOfSize:22.0];
    self.titleLabel.textColor = [UIColor colorWithWhite:0.25 alpha:1.0];
    
    self.trashButton.backgroundDrawColor = [UIColor whiteColor];
    self.saveButton.backgroundDrawColor = [WPStyleGuide mediumBlue];
    self.saveButton.titleLabel.font = [WPFontManager openSansRegularFontOfSize:14.0];
    [self.saveButton setTitle:NSLocalizedString(@"Save", @"Menus save button title") forState:UIControlStateNormal];
    [self.saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    UIEdgeInsets inset = self.saveButton.titleEdgeInsets;
    inset.bottom += MenusDetailsButtonDesignPadding;
    self.saveButton.titleEdgeInsets = inset;
}

- (void)setMenu:(Menu *)menu
{
    if(_menu != menu) {
        _menu = menu;
        [self updatedMenu];
    }
}

- (void)updatedMenu
{
    self.titleLabel.text = self.menu.name;
}

@end
