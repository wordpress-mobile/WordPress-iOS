//
//  ListPeopleViewController.m
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

#import "ListPeopleViewController.h"

#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GooglePlus/GooglePlus.h>

@interface ListPeopleViewController ()

@property(copy, nonatomic) NSString *status;

@end

@implementation ListPeopleViewController {
  UIImage *_placeholderAvatar;
  NSArray *_peopleList;
  NSMutableArray *_selectedPeopleList;
  NSMutableArray *_peopleImageList;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
  // Send Google+ request to get list of people that is visible to this app.
  [self listPeople:kGTLPlusCollectionVisible];
  _selectedPeopleList = [NSMutableArray array];
  _placeholderAvatar = [UIImage imageNamed:@"PlaceholderAvatar.png"];

  if (self.allowSelection) {
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                      target:self
                                                      action:@selector(doneSelecting)];
  }

  [super viewDidLoad];
}

- (void)doneSelecting {
  if (self.delegate) {
    [self.delegate viewController:self didPickPeople:_selectedPeopleList];
  }
}

#pragma mark - UITableViewDelegate/UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  return _peopleList.count;
}

- (NSString *)tableView:(UITableView *)tableView
    titleForHeaderInSection:(NSInteger)section {
  return self.status;
}

- (BOOL)tableView:(UITableView *)tableView
    shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
  return self.allowSelection;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString * const kCellIdentifier = @"Cell";
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:kCellIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
  }

  // Configure the cell by extracting a person's name and image from the list
  // of people.
  if ((NSUInteger)indexPath.row < _peopleList.count) {
    GTLPlusPerson *person = _peopleList[indexPath.row];
    NSString *name = person.displayName;
    cell.textLabel.text = name;

    if ((NSUInteger)indexPath.row < [_peopleImageList count] &&
        ![[_peopleImageList objectAtIndex:indexPath.row]
            isEqual:[NSNull null]]) {
      cell.imageView.image =
          [[UIImage alloc]
              initWithData:[_peopleImageList objectAtIndex:indexPath.row]];
    } else {
      cell.imageView.image = _placeholderAvatar;
    }
    if (self.allowSelection && [_selectedPeopleList containsObject:person.identifier]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
      cell.accessoryType = UITableViewCellAccessoryNone;
    }
  }

  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.allowSelection) {
    GTLPlusPerson *person = _peopleList[indexPath.row];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
      cell.accessoryType = UITableViewCellAccessoryCheckmark;
      [_selectedPeopleList addObject:person.identifier];
    } else {
      cell.accessoryType = UITableViewCellAccessoryNone;
      [_selectedPeopleList removeObject:person.identifier];
    }
  }
}

#pragma mark - Helper methods

- (void)listPeople:(NSString *)collection {
  _peopleList = nil;
  _peopleImageList = nil;
  self.status = @"Loading people...";
  [self.tableView reloadData];

  // 1. Create a |GTLQuery| object to list people that are visible to this
  // sample app.
  GTLQueryPlus *query =
      [GTLQueryPlus queryForPeopleListWithUserId:@"me"
                                      collection:collection];

  // 2. Execute the query.
  [[[GPPSignIn sharedInstance] plusService] executeQuery:query
          completionHandler:^(GTLServiceTicket *ticket,
                              GTLPlusPeopleFeed *peopleFeed,
                              NSError *error) {
              if (error) {
                GTMLoggerError(@"Error: %@", error);
                self.status = [NSString stringWithFormat:@"Error: %@", error];
                [self.tableView reloadData];
              } else {
                // Get an array of people from |GTLPlusPeopleFeed| and reload
                // the table view.
                _peopleList = peopleFeed.items;

                // Render the status of the Google+ request.
                NSNumber *count = peopleFeed.totalItems;
                if (count.intValue == 1) {
                  self.status = @"1 person in your circles";
                } else {
                  self.status = [NSString stringWithFormat:
                      @"%@ people in your circles", count];
                }
                [self.tableView reloadData];

                dispatch_queue_t backgroundQueue =
                    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,
                                              0);
                dispatch_async(backgroundQueue, ^{
                    [self fetchPeopleImages];
                });
              }
          }];
}

- (void)fetchPeopleImages {
  NSInteger index = 0;
  _peopleImageList =
      [[NSMutableArray alloc] initWithCapacity:[_peopleList count]];
  for (GTLPlusPerson *person in _peopleList) {
    // Stop loading images if the user has left the table view.
    if (!self.navigationController) {
      return;
    }
    NSData *imageData = nil;
    NSString *imageURLString = person.image.url;
    if (imageURLString) {
      NSURL *imageURL = [NSURL URLWithString:imageURLString];
      imageData = [NSData dataWithContentsOfURL:imageURL];
    }
    if (imageData) {
      [_peopleImageList setObject:imageData atIndexedSubscript:index];

      NSIndexPath *path = [NSIndexPath indexPathForItem:index inSection:0];
      dispatch_async(dispatch_get_main_queue(), ^{
          [self.tableView reloadRowsAtIndexPaths:@[path]
                                withRowAnimation:UITableViewRowAnimationNone];
      });
    } else {
      [_peopleImageList setObject:[NSNull null] atIndexedSubscript:index];
    }
    ++index;
  }
}

@end
