#import "WPStatsGraphBackgroundView.h"
#import "WPStyleGuide+Stats.h"

static CGFloat const AxisPadding = 18.0f;

@implementation WPStatsGraphBackgroundView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.contentMode = UIViewContentModeRedraw;
        self.accessibilityLabel = NSLocalizedString(@"Visitors and Views Graph", @"Accessibility label for visitors and views graph view");
        self.isAccessibilityElement = YES;
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        [view removeFromSuperview];
    }];
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    NSUInteger maxYPoint = self.maximumYValue;   // The tallest bar 'point'
    CGFloat xAxisStepWidth = 0;
    NSUInteger maxXAxisPointCount = 0; // # points along the x axis
    
    CGFloat xAxisStartPoint = AxisPadding * 2;
    CGFloat xAxisWidth = rect.size.width - 10.0;
    CGFloat yAxisStartPoint = AxisPadding + 10.0f;
    CGFloat yAxisHeight = rect.size.height - AxisPadding - yAxisStartPoint;

    xAxisStepWidth = (CGRectGetWidth(self.frame) - 3 * AxisPadding) / self.numberOfXValues;

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0f);
    
    // X Axis ticks
    CGContextSetGrayStrokeColor(context, 0.90, 1.0f);
    CGFloat const tickHeight = 6.0f;
    for (NSInteger i = 0; i < maxXAxisPointCount; i++) {
        CGFloat xOffset = xAxisStartPoint - xAxisStepWidth/2 + xAxisStepWidth*(i+1);
        CGContextMoveToPoint(context, xOffset, yAxisStartPoint+yAxisHeight-tickHeight/2);
        CGContextAddLineToPoint(context, xOffset, yAxisStartPoint+yAxisHeight+tickHeight/2);
        CGContextStrokePath(context);
    }
    
    // Y axis line markers and values
    // Round up and extend past max value to the next 10s
    NSUInteger yAxisTicks = self.numberOfYValues;
    NSUInteger stepValue = 1;
    if (maxYPoint > 0) {
        CGFloat s = (CGFloat)maxYPoint / (CGFloat)yAxisTicks;
        long len = (long)(double)log10(s);
        long div = (long)(double)pow(10, len);
        stepValue = ceil(s / div) * div;
    }
    CGFloat yAxisStepSize = yAxisHeight/yAxisTicks;
    
    for (NSUInteger tick = 0; tick < yAxisTicks; tick++) {
        CGFloat linePosition = yAxisStartPoint+yAxisHeight-(yAxisStepSize*tick)-0.5f;
        CGContextMoveToPoint(context, xAxisStartPoint, linePosition);
        CGContextAddLineToPoint(context, xAxisStartPoint+xAxisWidth-2*AxisPadding, linePosition);
        CGContextStrokePath(context);
        
        UILabel *yIncrement = [self axisLabelWithText:[@(stepValue*tick) stringValue]];
        yIncrement.center = CGPointMake(xAxisStartPoint-CGRectGetMidX(yIncrement.frame)-6.0f, linePosition);
        [self addSubview:yIncrement];
    }
}

- (UILabel *)axisLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [WPStyleGuide axisLabelFont];
    label.textColor = [WPStyleGuide littleEddieGrey];
    label.backgroundColor = [UIColor whiteColor];
    label.opaque = YES;
    label.isAccessibilityElement = NO;
    [label sizeToFit];
    return label;
}


@end
