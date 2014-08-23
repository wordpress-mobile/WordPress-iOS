#import <UIKit/UIKit.h>

@interface WPStatsCounterCell : UITableViewCell

+ (CGFloat)heightForRow;

- (void)setTitle:(NSString *)title;
- (void)addCount:(NSNumber *)count withLabel:(NSString *)label;

@end
