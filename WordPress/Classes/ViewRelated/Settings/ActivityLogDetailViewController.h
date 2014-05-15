#import <UIKit/UIKit.h>

@interface ActivityLogDetailViewController : UIViewController <UIActionSheetDelegate>

- (id)initWithLog:(NSString *)logText forDateString:(NSString *)logDate;

@end
