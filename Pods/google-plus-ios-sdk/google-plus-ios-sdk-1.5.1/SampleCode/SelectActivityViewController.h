#import <UIKit/UIKit.h>

@interface SelectActivityViewController : UITableViewController

+ (NSDictionary *)sampleDataForActivity:(NSString *)activity;
+ (NSArray *)activityTypes;
- (NSString *)selectedActivity;

@end
