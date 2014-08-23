#import "WPStatsViewController.h"

@interface WPStatsViewController (PrivateMethods)

/*!
 Override point to do initialization with local storage - super must be called
 */
- (void)initStats;

/*!
 Display error message if no results available - can be used to display offline error
 if your app contains custom logic to determine status.
 */
- (void)showNoResultsWithTitle:(NSString *)title message:(NSString *)message;

@end