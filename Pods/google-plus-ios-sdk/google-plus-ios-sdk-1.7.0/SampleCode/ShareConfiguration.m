//
//  ShareConfiguration.m
//
//  Copyright 2013 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ShareConfiguration.h"

static ShareConfiguration *sharedInstance = nil;

// Key in each section dictionary for an array of cells.
static NSString * const kCellArrayKey = @"cells";

// Keys in each cell dictionary.
static NSString * const kCellDataFieldLabel = @"label";
static NSString * const kCellDataFieldProperty = @"property";
static NSString * const kCellDataFieldSample = @"sample";
static NSString * const kCellDataFieldType = @"type";

@implementation ShareConfiguration {
  // Cache the table view section/cell data from the ShareConfigurationOptions.plist file.
  // _sectionData -
  //     Array containing a list of sections.
  // _sectionData[sectionIndex] -
  //     Dictionary containing information about a particular section.
  // _sectionData[sectionIndex][@"label"] -
  //     NSString storing the label for the section.
  // _sectionData[sectionIndex][@"cells"] -
  //     Array of cells that belong to the section at index |index|.
  // _sectionData[sectionIndex][@"cells"][cellIndex] -
  //     Dictionary storing information about a particular cell.
  // _sectionData[sectionIndex][@"cells"][cellIndex][@"label"] -
  //     NSString storing the label for the cell.
  // _sectionData[sectionIndex][@"cells"][cellIndex][@"type"] -
  //     NSString storing the type of the cell (either "editable", "switch", or "drilldown").
  // _sectionData[sectionIndex][@"cells"][cellIndex][@"property"] -
  //     NSString storing the name of the property to which this cell's data is connected.
  // _sectionData[sectionIndex][@"cells"][cellIndex][@"sample"] -
  //     NSString storing the sample value for the field to which this cell corresponds.
  NSArray *_sectionData;
}

+ (ShareConfiguration *)sharedInstance {
  if (!sharedInstance) {
    sharedInstance = [[ShareConfiguration alloc] init];
  }
  return sharedInstance;
}

+ (void)reset {
  sharedInstance = nil;
  [self sharedInstance];
}

- (id)init {
  self = [super init];
  if (self) {
    NSString *file = [[NSBundle mainBundle] pathForResource:@"ShareConfigurationOptions"
                                                     ofType:@"plist"];
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:file];
    _sectionData = dict[@"sections"];

    // Populate sample values for fields.
    for (NSDictionary *section in _sectionData) {
      for (NSDictionary *cell in section[@"cells"]) {
        NSString *propertyName = cell[@"property"];
        if (propertyName) {
          [self setValue:cell[@"sample"] forKey:propertyName];
        }
      }
    }

    _callToActionLabelState =
        [[DataPickerState alloc] initWithDictionary:dict[@"callToActionLabels"]];
  }
  return self;
}

- (NSDictionary *)cellDataForIndexPath:(NSIndexPath *)indexPath {
  return _sectionData[indexPath.section][kCellArrayKey][indexPath.row];
}

#pragma mark - Section accessor methods.

- (NSInteger)numberOfSections {
  return [_sectionData count];
}

- (NSInteger)numberOfCellsInSection:(NSInteger)section {
  return [_sectionData[section][kCellArrayKey] count];
}

- (NSString *)titleForSection:(NSInteger)section {
  return _sectionData[section][kCellDataFieldLabel];
}

#pragma mark - Cell accessor methods.

- (NSString *)labelForCellAtIndexPath:(NSIndexPath *)path {
  NSDictionary *cellData = [self cellDataForIndexPath:path];
  return cellData[kCellDataFieldLabel];
}

- (NSString *)typeForCellAtIndexPath:(NSIndexPath *)path {
  NSDictionary *cellData = [self cellDataForIndexPath:path];
  return cellData[kCellDataFieldType];
}

- (NSString *)propertyForCellAtIndexPath:(NSIndexPath *)path {
  NSDictionary *cellData = [self cellDataForIndexPath:path];
  return cellData[kCellDataFieldProperty];
}

- (NSString *)textForCellAtIndexPath:(NSIndexPath *)path {
  NSString *propertyName = [self propertyForCellAtIndexPath:path];
  if (propertyName) {
    return [self valueForKey:propertyName];
  } else {
    return nil;
  }
}



@end
