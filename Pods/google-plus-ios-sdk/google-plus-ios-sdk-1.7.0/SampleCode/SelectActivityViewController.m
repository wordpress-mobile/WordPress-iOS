//
//  SelectActivityViewController.m
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

#import "SelectActivityViewController.h"

// Stores the dictionary in ActivitySapleData.plist for later access.
// This dictionary contains sample values for the fields for each
// activity type as well as an sorted list of the activity types.
static NSDictionary *sampleActivityData;

@implementation SelectActivityViewController {
  NSInteger _selectedActivityIndex;
}

// Load sample data dictionary into memory and save it for later access
+ (void)initialize {
  NSString *file = [[NSBundle mainBundle] pathForResource:@"ActivitySampleData"
                                                   ofType:@"plist"];
  sampleActivityData = [[NSDictionary alloc] initWithContentsOfFile:file];
}

#pragma mark - Sample data accessors

// Return a dictionary containing sample data about an activity type
+ (NSDictionary *)sampleDataForActivity:(NSString *)activity {
  return [sampleActivityData objectForKey:activity];
}

// Return an array of ordered activity subclasses
+ (NSArray *)activityTypes {
  return [sampleActivityData objectForKey:@"ActivityTypes"];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
  self.navigationItem.title = @"Select Activity";
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  return [[SelectActivityViewController activityTypes] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString * const kCellIdentifier = @"Cell";
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];

  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
               reuseIdentifier:kCellIdentifier];
  }

  NSArray *activityTypes = [SelectActivityViewController activityTypes];

  cell.textLabel.text = [activityTypes objectAtIndex:indexPath.row];
  if (indexPath.row == _selectedActivityIndex) {
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
  } else {
    cell.accessoryType = UITableViewCellAccessoryNone;
  }

  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (_selectedActivityIndex != indexPath.row) {
    UITableViewCell *previouslySelectedCell =
        [self.tableView cellForRowAtIndexPath:
            [NSIndexPath indexPathForRow:_selectedActivityIndex inSection:0]];
    previouslySelectedCell.accessoryType = UITableViewCellAccessoryNone;

    _selectedActivityIndex = indexPath.row;

    [self.tableView cellForRowAtIndexPath:indexPath].accessoryType =
        UITableViewCellAccessoryCheckmark;
  }

  [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Instance methods

- (NSString *)selectedActivity {
  NSArray *activityTypes = [SelectActivityViewController activityTypes];
  return [activityTypes objectAtIndex:_selectedActivityIndex];
}

@end
