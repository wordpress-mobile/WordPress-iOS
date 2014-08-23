#import <UIKit/UIKit.h>

@interface PostSettingsSelectionViewController : UITableViewController

@property (nonatomic, copy) void(^onItemSelected)(NSString *);

- (id)initWithDictionary:(NSDictionary *)dictionary;
- (void)dismiss;

@end
