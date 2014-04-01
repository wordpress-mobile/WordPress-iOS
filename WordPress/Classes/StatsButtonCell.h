#import "StatsViewController.h"
#import "WPTableViewCell.h"

@interface StatsButtonCell : WPTableViewCell

@property (nonatomic, strong) NSMutableArray *buttons;
@property (nonatomic, assign) NSUInteger currentActiveButton;

+ (CGFloat)heightForRow;

- (void)addButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action section:(StatsSection)section;

@end
