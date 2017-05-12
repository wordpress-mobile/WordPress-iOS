#import <UIKit/UIKit.h>
#import "WPStatsService.h"
#import "WPStatsViewController.h"

@interface StatsPostDetailsTableViewController : UITableViewController

@property (nonatomic, strong) NSNumber *postID;
@property (nonatomic, copy) NSString *postTitle;
@property (nonatomic, strong) WPStatsService *statsService;
@property (nonatomic, weak) id<WPStatsViewControllerDelegate> statsDelegate;

@end
