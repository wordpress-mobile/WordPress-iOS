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

@interface ListPeopleViewController()
- (void)listPeople:(NSString *)collection;
- (void)reportAuthStatus;
- (void)fetchPeopleImages;
@end

@implementation ListPeopleViewController

@synthesize peopleTable = peopleTable_;
@synthesize peopleList = peopleList_;
@synthesize peopleStatus = peopleStatus_;
@synthesize peopleImageList = peopleImageList_;

#pragma mark - Object lifecycle

- (void)dealloc {
  [peopleStatus_ release];
  [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
  // Report whether the user is authenticated with
  // https://www.googleapis.com/auth/plus.login scope.
  [self reportAuthStatus];
  // Send Google+ request to get list of people that is visible to this app.
  [self listPeople:kGTLPlusCollectionVisible];
  [super viewDidLoad];
}

- (void)viewDidUnload {
  [peopleImageList_ release];
  [peopleList_ release];
  [peopleStatus_ release];
  [super viewDidUnload];
}

#pragma mark - UITableViewDelegate/UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
  return peopleList_.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *const kCellIdentifier = @"Cell";
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:kCellIdentifier]
             autorelease];
    cell.accessoryType = UITableViewCellAccessoryNone;
  }

  // Configure the cell by extracting a person's name and image from the list
  // of people.
  if (indexPath.row < peopleList_.count) {
    GTLPlusPerson *person = peopleList_[indexPath.row];
    NSString *name = person.displayName;
    cell.textLabel.text = name;

    if (indexPath.row < [peopleImageList_ count] &&
        ![[peopleImageList_ objectAtIndex:indexPath.row]
            isEqual:[NSNull null]]) {
      cell.imageView.image =
          [[[UIImage alloc]
              initWithData:[peopleImageList_ objectAtIndex:indexPath.row]]
                  autorelease];
    } else {
      cell.imageView.image = nil;
    }
  }

  return cell;
}

#pragma mark - Helper methods

- (void)listPeople:(NSString *)collection {
  GTMOAuth2Authentication *auth = [GPPSignIn sharedInstance].authentication;
  if (!auth) {
    // To authenticate, use Google+ sign-in button.
    peopleStatus_.text = @"Status: Not authenticated";
    return;
  }

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
                peopleStatus_.text =
                    [NSString stringWithFormat:@"Status: Error: %@", error];
              } else {
                // Get an array of people from |GTLPlusPeopleFeed| and reload
                // the table view.
                peopleList_ = [peopleFeed.items retain];
                [peopleTable_ reloadData];

                // Render the status of the Google+ request.
                NSNumber *count = peopleFeed.totalItems;
                if (count.intValue == 1) {
                  peopleStatus_.text = [NSString stringWithFormat:
                      @"Status: Listed 1 person"];
                } else {
                  peopleStatus_.text = [NSString stringWithFormat:
                      @"Status: Listed %@ people", count];
                }
                [self fetchPeopleImages];
              }
          }];
}

- (void)fetchPeopleImages {
  NSInteger index = 0;
  peopleImageList_ =
      [[NSMutableArray alloc] initWithCapacity:[peopleList_ count]];
  for (GTLPlusPerson *person in peopleList_) {
    NSData *imageData = nil;
    NSString *imageURLString = person.image.url;
    if (imageURLString) {
      NSURL *imageURL = [NSURL URLWithString:imageURLString];
      imageData = [NSData dataWithContentsOfURL:imageURL];
    }
    if (imageData) {
      [peopleImageList_ setObject:imageData atIndexedSubscript:index];
    } else {
      [peopleImageList_ setObject:[NSNull null] atIndexedSubscript:index];
    }
    ++index;
  }
}

- (void)reportAuthStatus {
  if (![GPPSignIn sharedInstance].authentication) {
    return;
  }

  if ([[GPPSignIn sharedInstance].scopes containsObject:
          kGTLAuthScopePlusLogin]) {
    peopleStatus_.text = @"Status: Authenticated with plus.login scope";
  } else {
    // To authenticate, use Google+ sign-in button.
    peopleStatus_.text = @"Status: Not authenticated with plus.login scope";
  }
}

@end
