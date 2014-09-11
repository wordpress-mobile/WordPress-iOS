//
//  MomentDetailViewController.m
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

#import "MomentDetailViewController.h"

#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GooglePlus/GooglePlus.h>

// This is the ordered list of sections in the table view.
enum {
  kProperties,
  kTarget,
  kResult
};

@implementation MomentDetailViewController {
  // This stores a list of properties for the moment whose values we want to display.
  NSArray *_propertyIdentifiers;

  // List of section header titles.
  NSArray *_sectionTitles;

  // List of the non-nil properties for the |GTLPlusItemScope| object |_moment.target|
  NSArray *_targetProperties;

  // List of the non-nil properties for the |GTLPlusItemScope| object |_moment.result|
  NSArray *_resultProperties;
}

- (void)gppInit {
  _propertyIdentifiers = @[
    @"type",
    @"identifier",
    @"kind",
    @"startDate"
  ];

  _sectionTitles = @[ @"Properties", @"Target", @"Result" ];

  self.navigationItem.title = @"Details";
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    [self gppInit];
  }
  return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    [self gppInit];
  }
  return self;
}

- (void)resetToMoment:(GTLPlusMoment *)moment {
  self.moment = moment;

  _targetProperties = [self.moment.target.JSON allKeys];
  _resultProperties = [self.moment.result.JSON allKeys];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [_sectionTitles count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  return _sectionTitles[section];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  if (section == kProperties) {
    return [_propertyIdentifiers count];
  } else if (section == kTarget) {
    return [_targetProperties count];
  } else if (section == kResult) {
    return [_resultProperties count];
  } else {
    return 0;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString * const kCellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];

  if (!cell) {
      cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                    reuseIdentifier:kCellIdentifier];
  }

  if (indexPath.section == kProperties) {
    NSString *propertyName = _propertyIdentifiers[indexPath.row];
    NSObject *value = [self.moment valueForKey:propertyName];

    cell.textLabel.text = propertyName;
    cell.detailTextLabel.text = [self descriptionForObject:value];
    cell.accessibilityIdentifier =
        [NSString stringWithFormat:@"properties %@", cell.textLabel.text];
  } else {
    NSString *propertyName;
    if (indexPath.section == kTarget) {
      propertyName = @"target";
    } else {
      propertyName = @"result";
    }
    GTLPlusItemScope *itemScope = [self.moment valueForKey:propertyName];

    NSObject *value = [itemScope.JSON objectForKey:_targetProperties[indexPath.row]];
    cell.textLabel.text = _targetProperties[indexPath.row];
    cell.detailTextLabel.text = [value description];
    cell.accessibilityIdentifier =
        [NSString stringWithFormat:@"%@ %@", propertyName, cell.textLabel.text];
  }

  return cell;
}

// Returns a readable string version of |value|. This makes a special case of the |GTLDateTime|
// class, and just calls the |NSObject| method |description| on all other object types.
- (NSString *)descriptionForObject:(NSObject *)value {
  if ([value isKindOfClass:[GTLDateTime class]]) {
    return [((GTLDateTime *)value).date description];
  } else {
    return [value description];
  }
}

#pragma mark - Table view delegate

// Push to a text view to display the cell label in case it is too long to be dispayed in the table.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
  UIViewController *viewController = [[UIViewController alloc] init];
  UITextView *textView = [[UITextView alloc] init];

  viewController.navigationItem.title = cell.textLabel.text;
  textView.text = cell.detailTextLabel.text;
  textView.font = [UIFont systemFontOfSize:16];
  textView.editable = NO;
  textView.accessibilityIdentifier = @"textView";
  viewController.view = textView;

  [self.navigationController pushViewController:viewController animated:YES];
}

@end
