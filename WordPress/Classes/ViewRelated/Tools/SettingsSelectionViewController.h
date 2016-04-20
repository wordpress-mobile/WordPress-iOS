#import <UIKit/UIKit.h>


#pragma mark - External Constants
extern NSString * const SettingsSelectionTitleKey;
extern NSString * const SettingsSelectionTitlesKey;
extern NSString * const SettingsSelectionValuesKey;
extern NSString * const SettingsSelectionHintsKey;
extern NSString * const SettingsSelectionDefaultValueKey;
extern NSString * const SettingsSelectionCurrentValueKey;


/**
 *  @class      SettingsSelectionViewController
 *  @brief      This class displays a collection of titles (with associated values), and allows the user to
 *              pick an item from the list.
 */

@interface SettingsSelectionViewController : UITableViewController

#pragma mark - Properties
@property (nonatomic, strong) NSArray<NSString *>   *titles;
@property (nonatomic, strong) NSArray               *values;
@property (nonatomic, strong) NSArray<NSString *>   *hints;
@property (nonatomic, strong) NSObject              *defaultValue;
@property (nonatomic, strong) NSObject              *currentValue;
@property (nonatomic,   copy) void                  (^onItemSelected)(id);
@property (nonatomic,   copy) void                  (^onCancel)();


/**
 *  @brief      Initializes the SettingsSelection Instance.
 *
 *  @param      dictionary  A Dictionary containing the target "Settings".
 */

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;


/**
 *  @brief      Initializes the SettingsSelection Instance.
 *
 *  @param      style       The desired TableView Style.
 *  @param      dictionary  A Dictionary containing the target "Settings".
 */

- (instancetype)initWithStyle:(UITableViewStyle)style andDictionary:(NSDictionary *)dictionary;


/**
 *  @brief      Dismisses the Settings Picker from the window.
 */

- (void)dismiss;

@end
