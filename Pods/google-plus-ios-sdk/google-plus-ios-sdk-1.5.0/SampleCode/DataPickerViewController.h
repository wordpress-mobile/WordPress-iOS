#import <UIKit/UIKit.h>

@class DataPickerState;

// This view controller controls a table view meant to select
// options from a list. The list is supplied from the DataPickerDictionary.plist
// file based upon what |dataKey| the controller is initialized with.
@interface DataPickerViewController : UITableViewController

// |dataState| stores the list of cells and the current set of selected cells.
// It should be created and owned by whoever owns the DataPickerViewController,
// so we only need a weak reference to it from here.
@property(weak, readonly, nonatomic) DataPickerState *dataState;

// This method initializes a DataPickerViewController using
// a DataPickerState object, from which the view controller
// obtains cell information for use in its table.
- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
            dataState:(DataPickerState *)dataState;

@end
