#import "StatsViewsVisitorsBarGraphCell.h"

static CGFloat const AxisPadding = 18.0f;
static CGFloat InitialBarWidth = 30.0f;
static NSString *const CategoryKey = @"category";
static NSString *const PointsKey = @"points";

@interface WPStyleGuide (WPBarGraphView)
+ (UIFont *)axisLabelFont;
@end

@implementation WPStyleGuide (WPBarGraphView)
+ (UIFont *)axisLabelFont {
    return [UIFont fontWithName:@"OpenSans" size:8.0f];
}
@end

@interface WPBarGraphView : UIView

@property (nonatomic, strong) NSMutableArray *categoryBars;
@property (nonatomic, strong) NSMutableDictionary *categoryColors;

// Builds legend and determines graph layers
- (void)addCategory:(NSString *)categoryName color:(UIColor *)color;

// Add bars to the graph.
// Limitation: if N x-axis names are used between the N categories, the last takes precendence
// If category A has N points and category B has M points, where N < M, then M points are displayed,
// with M - N points drawn without layers. The x-axis is extended to the last Mth point
/*
 @[
    @{@"name": @"Jan 10",
      @"count": @10},
    @{@"name": @"Jan 11",
      @"count": @20},
    ...
 ]
 */
- (void)setBarsWithCount:(NSArray *)pointToCount forCategory:(NSString *)category;

@end

CGFloat heightFromRangeToRange(NSUInteger height, CGFloat maxOldRange, CGFloat maxNewRange) {
    if (height == 0 || maxNewRange == 0.0) {
        return 0.0;
    }
    
    CGFloat p = ((CGFloat)height) / maxOldRange;
    CGFloat newHeight = p * maxNewRange;
    
    return newHeight;
}

@implementation WPBarGraphView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _categoryBars = [NSMutableArray arrayWithCapacity:2];
        _categoryColors = [NSMutableDictionary dictionaryWithCapacity:2];
        
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)addCategory:(NSString *)categoryName color:(UIColor *)color {
    _categoryColors[categoryName] = color;
}

- (void)setBarsWithCount:(NSArray *)pointToCount forCategory:(NSString *)category {
    [_categoryBars addObject:@{CategoryKey: category, PointsKey: pointToCount}];
    
    [self setNeedsDisplay];
}

- (void)calculateXAxisScale:(CGFloat *)xAxisStepWidth
             maxXPointCount:(NSUInteger *)maxXAxisPointCount maxYPoint:(NSUInteger *)maxYPoint {
    [_categoryBars enumerateObjectsUsingBlock:^(NSDictionary *categoryToPoints, NSUInteger idx, BOOL *stop) {
        *maxXAxisPointCount = MAX(((NSArray *)categoryToPoints[PointsKey]).count, *maxXAxisPointCount);
        
        [categoryToPoints[PointsKey] enumerateObjectsUsingBlock:^(NSDictionary *point, NSUInteger idx, BOOL *stop) {
            *maxYPoint = MAX(*maxYPoint, [point[StatsPointCountKey] unsignedIntegerValue]);
        }];
    }];
    
    *xAxisStepWidth = (self.frame.size.width-3*AxisPadding)/(*maxXAxisPointCount);
}

- (void)drawRect:(CGRect)rect {
    NSUInteger maxYPoint = 0;   // The tallest bar 'point'
    CGFloat xAxisStepWidth = 0;
    NSUInteger maxXAxisPointCount = 0; // # points along the x axis
    
    CGFloat xAxisStartPoint = AxisPadding*2;
    CGFloat xAxisWidth = rect.size.width - AxisPadding;
    CGFloat yAxisStartPoint = AxisPadding + 10.0f;
    CGFloat yAxisHeight = rect.size.height - AxisPadding - yAxisStartPoint;
    
    [self calculateXAxisScale:&xAxisStepWidth maxXPointCount:&maxXAxisPointCount maxYPoint:&maxYPoint];
    
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
    NSUInteger yAxisTicks = 7;
    NSUInteger stepValue = 1;
    if (maxYPoint > 0) {
        CGFloat s = (CGFloat)maxYPoint/(CGFloat)yAxisTicks;
        long len = (long)(double)log10(s);
        long div = (long)(double)pow(10, len);
        stepValue = ceil(s / div) * div;
    }
    CGFloat yAxisStepSize = yAxisHeight/yAxisTicks;
    
    for (NSUInteger tick = 0; tick <= yAxisTicks; tick++) {
        CGFloat linePosition = yAxisStartPoint+yAxisHeight-(yAxisStepSize*tick)-0.5f;
        CGContextMoveToPoint(context, xAxisStartPoint, linePosition);
        CGContextAddLineToPoint(context, xAxisStartPoint+xAxisWidth-2*AxisPadding, linePosition);
        CGContextStrokePath(context);
        
        UILabel *yIncrement = [self axisLabelWithText:[@(stepValue*tick) stringValue]];
        yIncrement.center = CGPointMake(xAxisStartPoint-CGRectGetMidX(yIncrement.frame)-6.0f, linePosition);
        [self addSubview:yIncrement];
    }

    // Bars
    __block CGFloat currentXPoint = 0;
    __block NSInteger iteration = 0;
    __block CGFloat legendXOffset = rect.size.width - AxisPadding;
    
    CGFloat const availableHeight = yAxisStepSize*(CGFloat)yAxisTicks;
    CGFloat const yUpperBound = (CGFloat)stepValue*yAxisTicks;
    
    [_categoryBars enumerateObjectsUsingBlock:^(NSDictionary *categoryToPoints, NSUInteger idx, BOOL *stop) {
        NSString *category = categoryToPoints[CategoryKey];
        CGColorRef categoryColor = ((UIColor *)_categoryColors[category]).CGColor;
        CGContextSetLineWidth(context, InitialBarWidth-iteration*6.0f);
        CGContextSetStrokeColorWithColor(context, categoryColor);
        currentXPoint = xAxisStartPoint + xAxisStepWidth/2;
        
        // Legend
        UILabel *legendName = [self legendLabelWithText:category];
        legendXOffset = legendXOffset - CGRectGetMaxX(legendName.frame);
        legendName.frame = (CGRect) {
            .origin = CGPointMake(legendXOffset, AxisPadding/2 - (legendName.frame.size.height-10)/2),
            .size = legendName.frame.size
        };
        [self addSubview:legendName];
        
        // Colour indicator
        legendXOffset -= 15.0f;
        CGContextSetFillColorWithColor(context, categoryColor);
        CGContextFillRect(context, CGRectMake(legendXOffset, AxisPadding/2, 10.0f, 10.0f));
        legendXOffset -= 10.0f;

        [categoryToPoints[PointsKey] enumerateObjectsUsingBlock:^(NSDictionary *point, NSUInteger idx, BOOL *stop) {
            // Bar
            CGContextMoveToPoint(context, currentXPoint, yAxisStartPoint+yAxisHeight);
            CGFloat barHeight = heightFromRangeToRange([point[StatsPointCountKey] unsignedIntegerValue], yUpperBound, availableHeight);
            CGContextAddLineToPoint(context, currentXPoint, yAxisStartPoint+yAxisHeight-barHeight);
            CGContextStrokePath(context);
         
            // Label
            if (iteration == 0) {
                UILabel *pointLabel = [self axisLabelWithText:point[StatsPointNameKey]];
                pointLabel.center = CGPointMake(currentXPoint, yAxisStartPoint+yAxisHeight+pointLabel.frame.size.height);
                [self addSubview:pointLabel];
            }
            
            // Move to next spot
            currentXPoint += xAxisStepWidth;
        }];
        iteration += 1;
    }];
}

- (UILabel *)axisLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [WPStyleGuide axisLabelFont];
    label.textColor = [WPStyleGuide littleEddieGrey];
    label.backgroundColor = [UIColor whiteColor];
    label.opaque = YES;
    [label sizeToFit];
    return label;
}

- (UILabel *)legendLabelWithText:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [WPStyleGuide subtitleFont];
    label.textColor = [WPStyleGuide littleEddieGrey];
    label.opaque = YES;
    label.backgroundColor = [UIColor whiteColor];
    [label sizeToFit];
    return label;
}

#pragma mark - UIAccessibilityTraits

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return NSLocalizedString(@"Visitors and Views Graph", @"Accessibility label for visitors and views graph view");
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitImage | UIAccessibilityTraitSummaryElement;
}

- (NSString *)accessibilityHint
{
    return [super accessibilityHint];
}

@end

@interface StatsViewsVisitorsBarGraphCell ()

@property (nonatomic, weak) WPBarGraphView *barGraph;
@property (nonatomic, assign) StatsViewsVisitorsUnit currentUnit;
@property (nonatomic, strong) StatsViewsVisitors *viewsVisitorsData;

@end

@implementation StatsViewsVisitorsBarGraphCell

+ (CGFloat)heightForRow {
    return 200.0f;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.barGraph removeFromSuperview];

    NSDictionary *categoryData = [_viewsVisitorsData viewsVisitorsForUnit:_currentUnit];
    WPBarGraphView *barGraph = [[WPBarGraphView alloc] initWithFrame:self.bounds];
    self.barGraph = barGraph;
    [self.barGraph addCategory:StatsViewsCategory color:[WPStyleGuide statsLighterBlue]];
    [self.barGraph addCategory:StatsVisitorsCategory color:[WPStyleGuide statsDarkerBlue]];
    if (categoryData && [categoryData count] > 0) {
        [self.barGraph setBarsWithCount:categoryData[StatsViewsCategory] forCategory:StatsViewsCategory];
        [self.barGraph setBarsWithCount:categoryData[StatsVisitorsCategory] forCategory:StatsVisitorsCategory];
    }
    [self.contentView addSubview:self.barGraph];
}

- (void)setViewsVisitors:(StatsViewsVisitors *)viewsVisitors {
    _viewsVisitorsData = viewsVisitors;
}

- (void)showGraphForUnit:(StatsViewsVisitorsUnit)unit {
    _currentUnit = unit;
    [self setNeedsDisplay];
}

@end
