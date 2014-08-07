#import <UIKit/UIKit.h>
#import <WPTableViewCell.h>

@interface WPStatsCounterCell : WPTableViewCell

+ (CGFloat)heightForRow;

- (void)setTitle:(NSString *)title;
- (void)addCount:(NSNumber *)count withLabel:(NSString *)label;

@end
