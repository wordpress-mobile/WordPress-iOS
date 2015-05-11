#import <UIKit/UIKit.h>

extern NSString * const SettingsSelectionTitleKey;
extern NSString * const SettingsSelectionTitlesKey;
extern NSString * const SettingsSelectionValuesKey;
extern NSString * const SettingsSelectionDefaultValueKey;
extern NSString * const SettingsSelectionCurrentValueKey;

@interface PostSettingsSelectionViewController : UITableViewController

@property (nonatomic, copy) void(^onItemSelected)(id);
@property (nonatomic, copy) void(^onCancel)();

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;
- (instancetype)initWithStyle:(UITableViewStyle)style andDictionary:(NSDictionary *)dictionary;
- (void)dismiss;

@end
