#import <UIKit/UIKit.h>
#import "WPStatsViewController.h"

@interface WPStatsLinkToWebviewCell : UITableViewCell

@property (nonatomic, copy) void (^onTappedLinkToWebview)(void);

+ (CGFloat)heightForRow;
- (void)configureForSection:(StatsSection)section;

@end
