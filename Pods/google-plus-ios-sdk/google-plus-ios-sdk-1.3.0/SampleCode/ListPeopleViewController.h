//
//  GooglePlusSamplePeopleListViewController.h
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

#import <UIKit/UIKit.h>

// A view controller for listing people that are visible to this sample app.
// The open-source GTLPlus libraries are required.
@interface ListPeopleViewController : UIViewController<
    UITableViewDelegate,
    UITableViewDataSource>

// A label to display the result of the listing people action.
@property (retain, nonatomic) IBOutlet UILabel *peopleStatus;
// The table that displays a list of people that is visible to this sample app.
@property (retain, nonatomic) IBOutlet UITableView *peopleTable;

// A list of people that is visible to this sample app.
@property (retain, nonatomic) NSArray *peopleList;
// A list of people profile images that we will prefetch that is
// visible to this sample app.
@property (retain, nonatomic) NSMutableArray *peopleImageList;

@end
