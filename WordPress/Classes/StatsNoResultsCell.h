#import <UIKit/UIKit.h>
#import "StatsViewController.h"
#import "WPTableViewCell.h"

@interface StatsNoResultsCell : WPTableViewCell

+ (CGFloat)heightForRowForSection:(StatsSection)section withWidth:(CGFloat)width;

- (void)configureForSection:(StatsSection)section;

@end