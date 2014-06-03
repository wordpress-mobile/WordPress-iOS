#import <UIKit/UIKit.h>
#import "WPTableViewCell.h"

@interface StatsCounterCell : WPTableViewCell

+ (CGFloat)heightForRow;

- (void)setTitle:(NSString *)title;
- (void)addCount:(NSNumber *)count withLabel:(NSString *)label;

@end
