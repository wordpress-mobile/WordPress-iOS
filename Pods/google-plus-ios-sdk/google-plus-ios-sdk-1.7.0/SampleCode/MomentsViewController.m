//
//  MomentsViewController.m
//
//  Copyright 2012 Google Inc.
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

#import "MomentsViewController.h"

#import "AddMomentsViewController.h"
#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GooglePlus/GooglePlus.h>
#import "MomentDetailViewController.h"

@interface MomentsViewController ()

@property(copy, nonatomic) NSString *status;

@end

@implementation MomentsViewController {
  // A map from activities to verbs used for display.
  NSDictionary *_verbMap;
  // An array of |GTLPlusMoment|, as the data source.
  NSMutableArray *_momentsData;
  // Navigation button that links to the AddMoments VC.
  UIBarButtonItem *_addMomentButton;
}

#pragma mark - Object lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _verbMap = @{
      @"http://schemas.google.com/AddActivity" :     @"Added",
      @"http://schemas.google.com/BuyActivity" :     @"Bought",
      @"http://schemas.google.com/CheckInActivity" : @"Checked in",
      @"http://schemas.google.com/CommentActivity" : @"Commented on",
      @"http://schemas.google.com/CreateActivity" :  @"Created",
      @"http://schemas.google.com/ListenActivity" :  @"Listened to",
      @"http://schemas.google.com/ReserveActivity" : @"Made a reservation at",
      @"http://schemas.google.com/ReviewActivity" :  @"Reviewed"
    };

    _addMomentButton = [[UIBarButtonItem alloc]
                            initWithTitle:@"Add"
                                    style:UIBarButtonItemStylePlain
                                   target:self
                                   action:@selector(prepareToAddMoment)];
    self.navigationItem.rightBarButtonItem = _addMomentButton;
  }
  return self;
}

#pragma mark - View lifecycle

- (void)viewWillAppear:(BOOL)animated {
  [self refreshData];

  [super viewWillAppear:animated];
}

#pragma mark - UITableViewDelegate/UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  // One section for a status header (so it can be reloaded independently)
  // and one section for the moment cells.
  return 2;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  if (section == 1) {
    return _momentsData.count;
  } else {
    return 0;
  }
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
  if (section == 0) {
    return self.status;
  } else {
    return nil;
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString * const kCellIdentifier = @"Cell";
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:kCellIdentifier];
    cell.accessoryType = UITableViewCellAccessoryNone;
  }

  // Configure the cell.
  GTLPlusMoment *moment = _momentsData[indexPath.row];
  cell.textLabel.text = [self textForMoment:moment];
  return cell;
}

- (void)tableView:(UITableView *)tableView
    commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
     forRowAtIndexPath:(NSIndexPath *)indexPath {
  [self removeMomentAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  MomentDetailViewController *detailViewController =
      [[MomentDetailViewController alloc] initWithNibName:nil bundle:nil];

  [detailViewController resetToMoment:_momentsData[indexPath.row]];
  [self.navigationController pushViewController:detailViewController animated:YES];
}

#pragma mark - Helper methods

- (void)removeMomentAtIndexPath:(NSIndexPath *)indexPath {
  GTLPlusMoment *moment = _momentsData[indexPath.row];

  // Here is an example of removing an app activity from Google+:
  // 1. Create a |GTLQuery| object to remove the app activity.
  GTLQueryPlus *query = [GTLQueryPlus
      queryForMomentsRemoveWithIdentifier:moment.identifier];

  [self updateStatus:@"Deleting app activity..."];
  [_momentsData removeObject:moment];
  [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                        withRowAnimation:UITableViewRowAnimationAutomatic];

  // 2. Execute the query.
  [[[GPPSignIn sharedInstance] plusService]
           executeQuery:query
      completionHandler:^(GTLServiceTicket *ticket,
                          id object,
                          NSError *error) {
        if (error) {
          [self updateStatus:[NSString stringWithFormat:@"Error: %@", error]];
          [self refreshData];
          GTMLoggerError(@"Status: Error: %@", error);
        } else {
          [self updateStatus:@"Deleted app activity."];
        }
      }];
}

- (void)refreshData {
  GTMOAuth2Authentication *auth = [GPPSignIn sharedInstance].authentication;
  if (!auth) {
    // To authenticate, use Google+ sign-in button.
    [self updateStatus:@"Status: Not authenticated"];
    return;
  }

  // Clear old moments data.
  _momentsData = nil;
  [self.tableView reloadData];

  [self updateStatus:@"Loading app activities..."];

  // Here is an example of reading list of app activities from Google+:
  // 1. Create a |GTLQuery| object to list app activities.
  GTLQueryPlus *query =
      [GTLQueryPlus queryForMomentsListWithUserId:@"me"
                                       collection:kGTLPlusCollectionVault];

  // 2. Execute the query
  [[[GPPSignIn sharedInstance] plusService]
           executeQuery:query
      completionHandler:^(GTLServiceTicket *ticket,
                              id object,
                              NSError *error) {
        if (error) {
          [self updateStatus:[NSString stringWithFormat:@"Error: %@", error]];
          GTMLoggerError(@"Status: Error: %@", error);
        } else {
          GTLPlusMomentsFeed *moments = (GTLPlusMomentsFeed *)object;
          _momentsData = [NSMutableArray arrayWithArray:moments.items];
          [self.tableView reloadData];
          [self updateStatus:@"Loaded app activities."];
        }
      }];
}

- (NSString *)textForMoment:(GTLPlusMoment *)moment {
  NSString *verb = [_verbMap objectForKey:moment.type];
  if (!verb) {
    // Fallback for verbs we don't recognize.
    verb = [moment.type lastPathComponent];
  }
  return [NSString stringWithFormat:@"%@ %@", verb, moment.target.name];
}

- (void)prepareToAddMoment {
  AddMomentsViewController *addMomentsViewController =
      [[AddMomentsViewController alloc] initWithNibName:nil
                                                 bundle:nil];

  [self.navigationController pushViewController:addMomentsViewController
                                       animated:YES];
}

- (void)updateStatus:(NSString *)status {
  self.status = status;
  // Refresh just the status header (section 0)
  [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
