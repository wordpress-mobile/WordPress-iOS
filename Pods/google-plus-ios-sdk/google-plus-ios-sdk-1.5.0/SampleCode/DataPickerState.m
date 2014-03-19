#import "DataPickerState.h"

@implementation DataPickerState

- (id)initWithDictionary:(NSDictionary *)dict {
  self = [super init];
  if (self) {
    _multipleSelectEnabled =
        [[dict objectForKey:@"multiple-select"] boolValue];

    NSMutableArray *cellLabels = [[NSMutableArray alloc] init];
    NSMutableSet *selectedCells = [[NSMutableSet alloc] init];

    NSArray *elements = [dict objectForKey:@"elements"];
    for (NSDictionary *elementDict in elements) {
      NSString *label = [elementDict objectForKey:@"label"];
      [cellLabels addObject:label];

      // Default selection mode is unselected, unless specified in plist.
      if ([[elementDict objectForKey:@"selected"] boolValue]) {
        [selectedCells addObject:label];
      }
    }

    self.cellLabels = cellLabels;
    self.selectedCells = selectedCells;
  }
  return self;
}

@end
