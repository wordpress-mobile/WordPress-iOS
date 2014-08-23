#import <UIKit/UIKit.h>

@interface WPStatsGraphBarCell : UICollectionViewCell

@property (nonatomic, assign) CGFloat maximumY;
@property (nonatomic, assign) NSUInteger numberOfYValues;

// @[ @{ @"color" : UIColor, @"value" : CGFloat, @"name" : @"Views"}, @{ ... } ]
@property (nonatomic, strong) NSArray *categoryBars;

@property (nonatomic, copy) NSString *barName;

- (void)finishedSettingProperties;

@end
