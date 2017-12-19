#import <UIKit/UIKit.h>


#pragma mark - External Constants
extern NSString * const SettingsSelectionTitleKey;
extern NSString * const SettingsSelectionTitlesKey;
extern NSString * const SettingsSelectionValuesKey;
extern NSString * const SettingsSelectionHintsKey;
extern NSString * const SettingsSelectionDefaultValueKey;
extern NSString * const SettingsSelectionCurrentValueKey;
extern NSString * const SettingsSelectionEditableIndexKey;

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
@property (nonatomic, assign) NSInteger             editableIndex;
@property (nonatomic,   copy) void                  (^onItemSelected)(id);
@property (nonatomic,   copy) void                  (^onRefresh)(UIRefreshControl *refreshControl);
@property (nonatomic,   copy) void                  (^onCancel)(void);
@property (nonatomic, assign) BOOL                  invokesRefreshOnViewWillAppear;

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
 *  @brief      Reloads the SettingsSelection data with a new dictionary.
 *
 *  @param      dictionary  A Dictionary containing the target "Settings".
 */
- (void)reloadWithDictionary:(NSDictionary *)dictionary;

/**
 *  @brief      Configures a cancel button as a barButtonItem that dismisses the view and call the onCancel block.
 *
 *  @note       This should be used only for modal presentations.
 */
- (void)configureCancelBarButtonItem;

/**
 *  @brief      Dismisses the Settings Picker from the window.
 */
- (void)dismiss;

@end
