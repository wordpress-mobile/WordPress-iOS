#import "MenuItemEmptyView.h"

@implementation MenuItemEmptyView

- (id)init
{
    self = [super init];
    if(self) {

    }
    
    return self;
}

- (UIColor *)contentViewBackgroundColor
{
    return [UIColor clearColor];
}

- (void)drawingViewDrawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect dashRect = CGRectInset(rect, 0.0, 8.0);
    dashRect.origin.x += 2.0;
    dashRect.size.width -= 8.0;
    
    CGContextSetStrokeColorWithColor(context, [[WPStyleGuide greyLighten10] CGColor]);
    CGContextSetLineWidth(context, 1.0);
    
    const CGFloat dashLength = 6.0;
    const CGFloat dashFillPercentage = 60; // fill % of the line with dashes, rest with white space
    
    CGFloat(^spacingForLineLength)(CGFloat) = ^ CGFloat (CGFloat lineLength) {
        // calculate the white spacing needed to fill the full line with dashes
        const CGFloat dashFill = (lineLength * dashFillPercentage) / 100;
        //// the white spacing is proportionate to amount of space the dashes will take
        //// uses (dashFill - dashLength) to ensure there is one extra dash to touch the end of the line
        return ((lineLength - dashFill) * dashLength) / (dashFill - dashLength);
    };

    const CGFloat pointOffset = 0.5;
    {
        CGFloat dash[2] = {dashLength, spacingForLineLength(dashRect.size.width)};
        CGContextSetLineDash(context, 0, dash, 2);
        
        const CGFloat leftX = dashRect.origin.x - pointOffset;
        const CGFloat rightX = dashRect.origin.x + dashRect.size.width + pointOffset;
        CGContextMoveToPoint(context, leftX, dashRect.origin.y);
        CGContextAddLineToPoint(context, rightX, dashRect.origin.y);
        CGContextMoveToPoint(context, leftX, dashRect.origin.y + dashRect.size.height);
        CGContextAddLineToPoint(context, rightX, dashRect.origin.y + dashRect.size.height);
        CGContextStrokePath(context);
        
    }
    {
        CGFloat dash[2] = {dashLength, spacingForLineLength(dashRect.size.height)};
        CGContextSetLineDash(context, 0, dash, 2);
        
        const CGFloat topY = dashRect.origin.y - pointOffset;
        const CGFloat bottomY = dashRect.origin.y + dashRect.size.height + pointOffset;
        CGContextMoveToPoint(context, dashRect.origin.x, topY);
        CGContextAddLineToPoint(context, dashRect.origin.x, bottomY);
        CGContextMoveToPoint(context, dashRect.origin.x + dashRect.size.width, topY);
        CGContextAddLineToPoint(context, dashRect.origin.x + dashRect.size.width, bottomY);
        CGContextStrokePath(context);
    }
}

@end
