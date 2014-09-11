//
//  AddMomentsViewController.m
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

#import "AddMomentsViewController.h"
#import "EditableCell.h"
#import "SelectActivityViewController.h"

#import "Activity.h"
#import "AddActivity.h"
#import "BuyActivity.h"
#import "CheckInActivity.h"
#import "CommentActivity.h"
#import "CreateActivity.h"
#import "DiscoverActivity.h"
#import "ListenActivity.h"
#import "ReserveActivity.h"
#import "ReviewActivity.h"
#import "WantActivity.h"

#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GooglePlus/GooglePlus.h>
#import <QuartzCore/QuartzCore.h>

@implementation AddMomentsViewController {
  UIBarButtonItem *_saveButton;
  EditableCell *_urlCell;
  SelectActivityViewController *_selectActivityViewController;

  NSArray *_tableSections;
}

// Constants indicating the section ordering in the table view.
enum sections {
  kActivityTypeSection,
  kURLSection,
  kRequiredFieldsSection,
  kRecommendedFieldsSection,
  kOptionalFieldsSection
};

#pragma mark - View lifecycle

- (void)viewDidLoad {
  _tableSections = @[
    @"Activity Type",
    @"URL",
    @"Required fields",
    @"Recommended fields",
    @"Optional fields"
  ];

  _saveButton = [[UIBarButtonItem alloc]
                    initWithTitle:@"Save"
                            style:UIBarButtonItemStyleDone
                           target:self
                           action:@selector(saveMoment)];
  self.navigationItem.rightBarButtonItem = _saveButton;
  self.navigationItem.title = @"Add Activity";

  _selectActivityViewController = [[SelectActivityViewController alloc]
                                     initWithNibName:nil
                                              bundle:nil];

  [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  NSString *activity = [_selectActivityViewController selectedActivity];
  NSDictionary *activityDict =
      [SelectActivityViewController sampleDataForActivity:activity];
  _urlCell.textField.text = [activityDict objectForKey:@"URL"];

  [self.tableView reloadData];
}

- (void)saveMoment {
  GTMOAuth2Authentication *auth = [GPPSignIn sharedInstance].authentication;
  if (!auth) {
    GTMLoggerError(@"Error: not authenticated.");
    return;
  }

  // Here is an example of writing a moment to Google+:
  // 1. Create a |GTLPlusMoment| object with required fields. For reference, see
  // https://developers.google.com/+/features/app-activities .

  NSString *selectedMoment = [_selectActivityViewController selectedActivity];
  Class activitySubclass = NSClassFromString(selectedMoment);
  if (!activitySubclass) {
    GTMLoggerError(@"Error: unable to save app activity of type %@", selectedMoment);
    return;
  }
  Activity *activity = [[activitySubclass alloc] init];
  [self fillSampleValuesForActivity:activity url:_urlCell.textField.text];

  GTLPlusMoment *moment = [activity getMoment];

  // 2. Create a |GTLQuery| object to write a moment.
  GTLQueryPlus *query =
      [GTLQueryPlus queryForMomentsInsertWithObject:moment
                                             userId:@"me"
                                         collection:kGTLPlusCollectionVault];

  // 3. Execute the query.
  [[[GPPSignIn sharedInstance] plusService] executeQuery:query
          completionHandler:^(GTLServiceTicket *ticket,
                              id object,
                              NSError *error) {
              if (error) {
                GTMLoggerError(@"Error: %@", error);
              } else {
                [self.navigationController popViewControllerAnimated:YES];
              }
          }];
}

#pragma mark - UITableViewDelegate/UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [_tableSections count];
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
  return [_tableSections objectAtIndex:section];
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  if (section == kActivityTypeSection || section == kURLSection) {
    return 1;
  } else {
    NSString *activity = [_selectActivityViewController selectedActivity];
    return [[self fieldListForActivity:activity section:section] count];
  }
  return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString * const kCellIdentifier = @"Cell";
  static NSString * const kEditableCellIdentifier = @"EditableCell";

  NSString *activity = [_selectActivityViewController selectedActivity];
  NSDictionary *activityDict =
      [SelectActivityViewController sampleDataForActivity:activity];

  if (indexPath.section == kURLSection) {
    if (_urlCell == nil) {
      _urlCell = [[EditableCell alloc] initWithStyle:UITableViewCellStyleDefault
                                     reuseIdentifier:kEditableCellIdentifier];
      _urlCell.textField.text = [activityDict objectForKey:@"URL"];
      _urlCell.textField.keyboardType = UIKeyboardTypeURL;
    }
    return _urlCell;
  }

  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];

  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:kCellIdentifier];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.minimumScaleFactor = 0;
  }

  if (indexPath.section == kActivityTypeSection) {
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = [_selectActivityViewController selectedActivity];
  } else if (indexPath.section == kRequiredFieldsSection ||
             indexPath.section == kRecommendedFieldsSection ||
             indexPath.section == kOptionalFieldsSection) {
    cell.accessoryType = UITableViewCellAccessoryNone;
    NSArray *fieldArray = [self fieldListForActivity:activity
                                             section:indexPath.section];
    cell.textLabel.text = [fieldArray objectAtIndex:indexPath.row];
  }

  return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView
  willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  // Only the activity cell should be selectable
  if (indexPath.section == kActivityTypeSection) {
    return indexPath;
  } else {
    return nil;
  }
}

- (BOOL)tableView:(UITableView *)tableView
    shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
  return indexPath.section == kActivityTypeSection;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (indexPath.section == kActivityTypeSection) {
    [self.navigationController pushViewController:_selectActivityViewController
                                         animated:YES];
  }
}

#pragma mark - Helper methods

- (void)fillSampleValuesForActivity:(Activity *)activity url:(NSString *)URL {
  NSString *className = NSStringFromClass([activity class]);
  NSDictionary *activityDict = [SelectActivityViewController
                                   sampleDataForActivity:className];

  if (URL) {
    activity.url = URL;
  } else {
    activity.url = [activityDict objectForKey:@"URL"];
  }

  NSDictionary *resultDict = [activityDict objectForKey:@"result"];
  [activity setValuesForKeysWithDictionary:resultDict];
}

- (NSArray *)fieldListForActivity:(NSString *)activity section:(NSInteger)section {
  NSDictionary *activityDict = [SelectActivityViewController
                                   sampleDataForActivity:activity];

  if (section == kRequiredFieldsSection) {
    return [activityDict objectForKey:@"requiredFields"];
  } else if (section == kRecommendedFieldsSection) {
    return [activityDict objectForKey:@"recommendedFields"];
  } else if (section == kOptionalFieldsSection) {
    return [activityDict objectForKey:@"optionalFields"];
  } else {
    return nil;
  }
}

@end
