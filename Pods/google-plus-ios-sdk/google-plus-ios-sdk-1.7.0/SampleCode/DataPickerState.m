#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "This file requires ARC support."
#endif

#import "DataPickerState.h"

NSString * const kMultipleSelectKey = @"multiple-select";
NSString * const kElementsKey = @"elements";
NSString * const kLabelKey = @"label";
NSString * const kShortLabelKey = @"shortLabel";
NSString * const kSelectedKey = @"selected";

@implementation DataPickerState

- (id)initWithDictionary:(NSDictionary *)dict {
  self = [super init];
  if (self) {
    _multipleSelectEnabled =
        [[dict objectForKey:kMultipleSelectKey] boolValue];

    NSMutableArray *cellLabels = [[NSMutableArray alloc] init];
    NSMutableSet *selectedCells = [[NSMutableSet alloc] init];

    NSArray *elements = [dict objectForKey:kElementsKey];
    for (NSDictionary *elementDict in elements) {
      NSMutableDictionary *cellLabelDict = [NSMutableDictionary dictionary];
      NSString *label = [elementDict objectForKey:kLabelKey];
      cellLabelDict[kLabelKey] = label;

      if ([elementDict objectForKey:kShortLabelKey]) {
        cellLabelDict[kShortLabelKey] = [elementDict objectForKey:kShortLabelKey];
      }
      [cellLabels addObject:cellLabelDict];

      // Default selection mode is unselected, unless specified in plist.
      if ([[elementDict objectForKey:kSelectedKey] boolValue]) {
        [selectedCells addObject:label];
      }
    }

    self.cellLabels = cellLabels;
    self.selectedCells = selectedCells;
  }
  return self;
}

@end
