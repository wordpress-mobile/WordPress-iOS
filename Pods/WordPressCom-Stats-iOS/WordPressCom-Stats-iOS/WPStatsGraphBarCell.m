#import "WPStatsGraphBarCell.h"
#import <WPStyleGuide.h>
#import "WPStyleGuide+Stats.h"

@interface WPStatsGraphBarCell ()

@property (nonatomic, strong) NSMutableArray *barsWithColors;

@end

@implementation WPStatsGraphBarCell

- (void)prepareForReuse
{
    [super prepareForReuse];

    [self.barsWithColors removeAllObjects];
    
    [self.contentView.subviews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        [view removeFromSuperview];
    }];
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    [self.barsWithColors enumerateObjectsUsingBlock:^(NSDictionary *dict, NSUInteger idx, BOOL *stop) {
        UIView *view = dict[@"view"];
        UIColor *color = dict[@"color"];
        UIColor *selectedColor = dict[@"selectedColor"];
        
        view.backgroundColor = self.isSelected ? selectedColor : color;
    }];
}

- (void)finishedSettingProperties
{
    self.barsWithColors = [NSMutableArray new];
    
    // Y axis line markers and values
    // Round up and extend past max value to the next 10s
    NSUInteger yAxisTicks = self.numberOfYValues;
    NSUInteger stepValue = 1;
    
    if (self.maximumY > 0) {
        CGFloat s = (CGFloat)self.maximumY/(CGFloat)yAxisTicks;
        long len = (long)(double)log10(s);
        long div = (long)(double)pow(10, len);
        stepValue = ceil(s / div) * div;
    }
    self.maximumY = stepValue * yAxisTicks;

    // For each subsequent category, inset the bar a set amount
    __block CGFloat inset = 0.0;
    
    __block NSMutableString *accessibilityValue = [NSMutableString new];
    
    [self.categoryBars enumerateObjectsUsingBlock:^(NSDictionary *category, NSUInteger idx, BOOL *stop) {
        UIColor *color = category[@"color"];
        UIColor *selectedColor = category[@"selectedColor"];
        NSInteger value = [category[@"value"] integerValue];
        NSString *name = category[@"name"];
        
        CGFloat percentHeight = value / self.maximumY;
        CGFloat height = floorf((CGRectGetHeight(self.contentView.bounds) - 20.0) * percentHeight);
        CGFloat offsetY = CGRectGetHeight(self.contentView.bounds) - (height + 20.0);
        
        CGRect rect = CGRectInset(self.contentView.bounds, inset, 0.0);
        rect.size.height = height;
        rect.origin.y = offsetY;
        
        UIView *view = [[UIView alloc] initWithFrame:rect];
        view.backgroundColor = self.isSelected ? selectedColor : color;
        
        [self.contentView addSubview:view];

        [accessibilityValue appendString:[NSString stringWithFormat:@"%@ %@ ", name, @(value)]];
    
        inset += 2.0;
        
        [self.barsWithColors addObject:@{ @"view" : view, @"color" : color, @"selectedColor" : selectedColor }];
    }];
    
    UILabel *axisLabel = [self axisLabelWithText:self.barName];
    axisLabel.center = CGPointMake(self.contentView.center.x, CGRectGetHeight(self.contentView.bounds) - 10.0);
    [self.contentView addSubview:axisLabel];

    self.isAccessibilityElement = YES;
    self.accessibilityLabel = self.barName;
    self.accessibilityValue = accessibilityValue;
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


@end
