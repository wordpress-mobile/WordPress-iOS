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
        self.accessibilityIdentifier = @"visitorsViewsGraph";
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
    NSInteger maxXAxisPointCount = 0; // # points along the x axis
    
    CGFloat xAxisStartPoint = 0;
    CGFloat xAxisWidth = CGRectGetWidth(rect) - 15.0;
    CGFloat yAxisStartPoint = 20.0f;
    CGFloat yAxisHeight = CGRectGetHeight(rect) - AxisPadding - yAxisStartPoint - 10.0;

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
        stepValue = (NSUInteger)(ceil(s / div) * (CGFloat)div);
    }
    CGFloat yAxisStepSize = yAxisHeight/yAxisTicks;
    
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    for (NSUInteger tick = 0; tick <= yAxisTicks; tick++) {
        CGFloat linePosition = yAxisStartPoint + yAxisHeight - (yAxisStepSize * tick) - 2.0f;
        CGContextMoveToPoint(context, xAxisStartPoint, linePosition);
        CGContextAddLineToPoint(context, xAxisStartPoint + xAxisWidth - AxisPadding, linePosition);
        CGContextStrokePath(context);
        
        UILabel *yIncrement = [self axisLabelWithText:[NSString stringWithFormat:@" %@", @(stepValue*tick)]];
        yIncrement.center = CGPointMake(CGRectGetWidth(rect) - CGRectGetMidX(yIncrement.frame) - 7.0f, linePosition);
        [self addSubview:yIncrement];
    }
}

- (UILabel *)axisLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 28.0f, 17.0f)];
    label.text = text;
    label.textAlignment = NSTextAlignmentRight;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.5;
    label.font = [WPStyleGuide axisLabelFontSmaller];
    label.textColor = [WPStyleGuide littleEddieGrey];
    label.backgroundColor = [UIColor clearColor];
    label.opaque = NO;
    label.isAccessibilityElement = NO;
    
    return label;
}


@end
