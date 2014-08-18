#import <UIKit/UIKit.h>
#import "WPStatsViewController.h"
#import <WPTableViewCell.h>

@interface WPStatsLinkToWebviewCell : WPTableViewCell

@property (nonatomic, copy) void (^onTappedLinkToWebview)(void);

+ (CGFloat)heightForRow;
- (void)configureForSection:(StatsSection)section;

@end
