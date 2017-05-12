#import "WPStatsGraphLegendView.h"
#import "WPStyleGuide+Stats.h"

@interface WPStatsGraphLegendView ()

@property (nonatomic, strong) NSMutableArray *categoryBars;
@property (nonatomic, strong) NSMutableDictionary *categoryObjects;

@end

static CGFloat const AxisPadding = 18.0f;

@implementation WPStatsGraphLegendView

- (void)layoutSubviews
{
    [super layoutSubviews];

    CGFloat legendXOffset = CGRectGetWidth(self.frame);
    
    for (NSString *category in self.categoryBars) {
        UILabel *legendName = self.categoryObjects[category][@"label"];
        legendXOffset = legendXOffset - CGRectGetWidth(legendName.frame);
        legendName.frame = (CGRect) {
            .origin = CGPointMake(legendXOffset, AxisPadding/2 - (legendName.frame.size.height-10)/2),
            .size = legendName.frame.size
        };
        
        legendXOffset -= 15.0f;
        UIView *swatchView = self.categoryObjects[category][@"swatch"];
        swatchView.frame = CGRectMake(legendXOffset, AxisPadding/2, 10.0f, 10.0f);
        legendXOffset -= 10.0f;
    }

}

- (void)addCategory:(NSString *)categoryName withColor:(UIColor *)color
{
    NSAssert(categoryName.length > 0, @"Category name can't be nil/empty");
    NSAssert(color, @"Category color can't be nil");
    
    [self.categoryBars addObject:categoryName];
    self.categoryObjects[categoryName] = @{@"color" : color};
}

- (void)removeAllCategories
{
    for (NSString *category in self.categoryBars) {
        NSDictionary *categoryObjects = self.categoryObjects[category];
        UILabel *label = categoryObjects[@"label"];
        UIView *swatch = categoryObjects[@"swatch"];
        [label removeFromSuperview];
        [swatch removeFromSuperview];
    }
    
    [self.categoryBars removeAllObjects];
    [self.categoryObjects removeAllObjects];
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self removeAllCategories];
}

- (UILabel *)legendLabelWithText:(NSString *)text
{
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [WPStyleGuide subtitleFont];
    label.textColor = [WPStyleGuide littleEddieGrey];
    label.opaque = YES;
    label.backgroundColor = [UIColor whiteColor];
    label.isAccessibilityElement = NO;
    [label sizeToFit];
    return label;
}

- (NSMutableDictionary *)categoryObjects
{
    if (!_categoryObjects) {
        _categoryObjects = [NSMutableDictionary new];
    }
    
    return _categoryObjects;
}

- (NSMutableArray *)categoryBars
{
    if (!_categoryBars) {
        _categoryBars = [NSMutableArray new];
    }
    
    return _categoryBars;
}

- (void)finishedAddingCategories
{
    for (NSString *category in self.categoryBars) {
        // Legend
        UILabel *legendName = [self legendLabelWithText:category];
        [self addSubview:legendName];
        
        // Colour indicator
        UIView *colorSwatch = [[UIView alloc] initWithFrame:CGRectZero];
        colorSwatch.backgroundColor = self.categoryObjects[category][@"color"];
        [self addSubview:colorSwatch];
        
        self.categoryObjects[category] = @{@"color" : self.categoryObjects[category][@"color"],
                                           @"label" : legendName,
                                           @"swatch" : colorSwatch};
    }
}

@end
