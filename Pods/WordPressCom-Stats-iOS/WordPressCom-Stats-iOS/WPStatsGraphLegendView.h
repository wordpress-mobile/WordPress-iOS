#import <UIKit/UIKit.h>

@interface WPStatsGraphLegendView : UICollectionReusableView

- (void)addCategory:(NSString *)categoryName withColor:(UIColor *)color;
- (void)removeAllCategories;
- (void)finishedAddingCategories;

@end
