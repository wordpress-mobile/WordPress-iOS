//
//  AuthInspectorViewController.m
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

#import "AuthInspectorViewController.h"

#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GooglePlus/GooglePlus.h>

static NSString * const kReusableCellIdentifier = @"AuthInspectorCell";
static CGFloat const kVeryTallConstraint = 10000.f;
static CGFloat const kTableViewCellFontSize = 16.f;
static CGFloat const kTableViewCellPadding = 22.f;

@implementation AuthInspectorViewController {
  UITableView *_tableView;
  NSArray *_fields;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _fields = @[
      @"access_token",
      @"code",
      @"expires_in",
      @"id_token",
      @"refresh_token",
      @"serviceProvider",
      @"token_type"
    ];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self.view addSubview:_tableView];
}

- (void)viewDidLayoutSubviews {
  _tableView.frame = self.view.bounds;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return (NSInteger)[_fields count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  NSString *key = [_fields objectAtIndex:section];
  return key;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kReusableCellIdentifier];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                  reuseIdentifier:kReusableCellIdentifier];
  }

  NSString *key = [_fields objectAtIndex:indexPath.section];

  // Make an |NSString|, since the values can be any |NSObject|.
  NSString *value = [NSString stringWithFormat:@"%@",
      [[[[GPPSignIn sharedInstance] authentication] parameters] objectForKey:key]];
  cell.textLabel.font = [UIFont systemFontOfSize:kTableViewCellFontSize];
  cell.textLabel.numberOfLines = 0;
  cell.textLabel.text = value;
  cell.selectionStyle = UITableViewCellSelectionStyleNone;

  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSString *key = [_fields objectAtIndex:indexPath.section];

  // Make an |NSString|, since the values can be any |NSObject|.
  NSString *value = [NSString stringWithFormat:@"%@",
      [[[[GPPSignIn sharedInstance] authentication] parameters] objectForKey:key]];
  // How will this fit within our table view cell?
  CGSize constraintSize =
      CGSizeMake(tableView.frame.size.width - 2 * kTableViewCellPadding, kVeryTallConstraint);
  CGSize size = [value sizeWithFont:[UIFont systemFontOfSize:kTableViewCellFontSize]
                  constrainedToSize:constraintSize];
  return size.height + kTableViewCellPadding;
}

@end
