#import <Foundation/Foundation.h>

// DataPickerState objects keep track of the list of available cells and set
// of selected cells that are being used in a DataPickerViewController object.
@interface DataPickerState : NSObject

// An ordered list of cell labels (NSStrings) to select from
@property(strong, nonatomic) NSArray *cellLabels;
// A set of the labels of the selected cells (NSStrings).
@property(strong, nonatomic) NSMutableSet *selectedCells;
// Determines if multiple cells can be checked.
@property(assign, nonatomic) BOOL multipleSelectEnabled;

// Initializes a DataPickerState to collect its data from
// the provided dictionary. The assumption about the provided
// dictionary is that it obeys the structure:
// dict[@"multiple-select"] - BOOL that represents whether multiple of the
//                            elements can be simultaneously selected.
// dict[@"elements"] - Array that contains the list of cell items to be shown.
// dict[@"elements"][index] - Dictionary that contains properties for each cell.
// dict[@"elements"][index][@"label"] - String storing the label of the cell.
// dict[@"elements"][index][@"selected"] - BOOL for whether the cell begins as
//                                         selected. If this property is not
//                                         set, then we default to NO.
- (id)initWithDictionary:(NSDictionary *)dict;

@end
