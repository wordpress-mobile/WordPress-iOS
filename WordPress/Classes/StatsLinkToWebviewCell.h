#import "WPTableViewCell.h"
#import "StatsViewController.h"

@interface StatsLinkToWebviewCell : WPTableViewCell

@property (nonatomic, copy) void (^onTappedLinkToWebview)(void);

+ (CGFloat)heightForRow;
- (void)configureForSection:(StatsSection)section;

@end
