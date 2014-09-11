//
//  MasterViewController.m
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

#import "MasterViewController.h"

#import <GooglePlus/GooglePlus.h>

static const int kNumViewControllers = 4;
static NSString * const kMenuOptions[kNumViewControllers] = {
    @"Sign in", @"Share", @"People", @"App Activities" };
static NSString * const kUnselectableMenuOptions[kNumViewControllers] = {
    nil, nil, @"Sign in to list people", @"Sign in to edit app activities" };
static NSString * const kNibNames[kNumViewControllers] = {
    @"SignInViewController",
    @"ShareViewController",
    @"ListPeopleViewController",
    @"MomentsViewController" };

@implementation MasterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.title = @"Google+ SDK Sample";
  }
  return self;
}

#pragma mark - View lifecycle

- (NSUInteger)supportedInterfaceOrientations {
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return UIInterfaceOrientationMaskAllButUpsideDown;
  } else {
    return UIInterfaceOrientationMaskAll;
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self.tableView reloadData];
}

#pragma mark - UITableViewDelegate/UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  return kNumViewControllers;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  BOOL selectable = [self isSelectable:indexPath];
  NSString * const kCellIdentifier = selectable ? @"Cell" : @"GreyCell";
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
  if (cell == nil) {
    cell =
        [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                               reuseIdentifier:kCellIdentifier];
    if (selectable) {
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      cell.textLabel.textColor = [UIColor lightGrayColor];
    }
  }
  cell.textLabel.text = (selectable ? kMenuOptions : kUnselectableMenuOptions)
      [indexPath.row];
  cell.accessibilityLabel = cell.textLabel.text;

  return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (![self isSelectable:indexPath]) {
    return;
  }
  Class nibClass = NSClassFromString(kNibNames[indexPath.row]);
  UIViewController *controller =
      [[nibClass alloc] initWithNibName:nil bundle:nil];
  controller.navigationItem.title = kMenuOptions[indexPath.row];

  [self.navigationController pushViewController:controller animated:YES];
}

#pragma mark - Helper methods

- (BOOL)isSelectable:(NSIndexPath *)indexPath {
  if (kUnselectableMenuOptions[indexPath.row]) {
    // To use Google+ app activities, you need to sign in.
    return [GPPSignIn sharedInstance].authentication != nil;
  }
  return YES;
}

@end
