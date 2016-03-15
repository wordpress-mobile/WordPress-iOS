#import "MenuItemCheckButtonView.h"
#import "MenusDesign.h"
#import "WPStyleGuide.h"
#import "WPFontManager.h"

static CGFloat const iconPadding = 3.0;

@interface MenuItemCheckButtonView ()

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, assign) BOOL drawsHighlighted;
@property (nonatomic, assign) CGPoint touchesBeganLocation;

@end

@implementation MenuItemCheckButtonView

- (id)init
{
    self = [super init];
    if(self) {
     
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor whiteColor];
        self.contentMode = UIViewContentModeRedraw;
        
        {
            UIImageView *iconView = [[UIImageView alloc] init];
            iconView.translatesAutoresizingMaskIntoConstraints = NO;
            iconView.image = [[UIImage imageNamed:@"icon-menus-checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            iconView.tintColor = [WPStyleGuide mediumBlue];
            iconView.contentMode = UIViewContentModeScaleAspectFit;
            iconView.alpha = 0.0;
            [self addSubview:iconView];
            
            [NSLayoutConstraint activateConstraints:@[
                                                      [iconView.topAnchor constraintEqualToAnchor:self.topAnchor constant:iconPadding],
                                                      [iconView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:iconPadding],
                                                      [iconView.widthAnchor constraintEqualToAnchor:iconView.heightAnchor],
                                                      [iconView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-iconPadding]
                                                      ]];
            self.iconView = iconView;
        }
        {
            UILabel *label = [[UILabel alloc] init];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            label.backgroundColor = [UIColor whiteColor];
            
            NSDictionary *attributes = [self attributesForText];
            label.font = [attributes objectForKey:NSFontAttributeName];
            label.textColor = [attributes objectForKey:NSForegroundColorAttributeName];
            
            [self addSubview:label];
            
            [NSLayoutConstraint activateConstraints:@[
                                                      [label.topAnchor constraintEqualToAnchor:self.topAnchor],
                                                      [label.leadingAnchor constraintEqualToAnchor:self.iconView.trailingAnchor constant:MenusDesignDefaultContentSpacing / 2.0],
                                                      [label.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
                                                      [label.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
                                                      ]];
            
            _label = label;
        }
    }
    
    return self;
}

- (CGFloat)preferredHeightForLayout
{
    CGSize size = [self.label.text sizeWithAttributes:[self attributesForText]];
    return size.height;
}

- (void)setChecked:(BOOL)checked
{
    if(_checked != checked) {
        _checked = checked;
        self.iconView.alpha = checked ? 1.0 : 0.0;
    }
}

- (void)setDrawsHighlighted:(BOOL)drawsHighlighted
{
    if(_drawsHighlighted != drawsHighlighted) {
        _drawsHighlighted = drawsHighlighted;
        [self setNeedsDisplay];
    }
}

- (NSDictionary *)attributesForText
{
    return @{NSFontAttributeName: [WPFontManager systemRegularFontOfSize:14.0], NSForegroundColorAttributeName: [UIColor blackColor]};
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if(self.drawsHighlighted) {
        CGContextSetFillColorWithColor(context, [[WPStyleGuide mediumBlue] CGColor]);
    }else {
        CGContextSetFillColorWithColor(context, [[WPStyleGuide greyLighten20] CGColor]);
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
    
    if(CGRectContainsPoint(self.bounds, self.touchesBeganLocation) && CGRectContainsPoint(self.bounds, [[touches anyObject] locationInView:self])) {
        self.checked = !self.checked;
        if (self.onChecked) {
            self.onChecked();
        }
    }
    
    self.drawsHighlighted = NO;
}

@end
