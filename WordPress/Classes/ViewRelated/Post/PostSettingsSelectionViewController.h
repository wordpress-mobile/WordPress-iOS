#import <UIKit/UIKit.h>

@interface PostSettingsSelectionViewController : UITableViewController

@property (nonatomic, copy) void(^onItemSelected)(NSString *);

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithStyle:(UITableViewStyle)style andDictionary:(NSDictionary *)dictionary;
- (void)dismiss;

@end
