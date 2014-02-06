//
//  ListMomentsViewController.h
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

@class GTLPlusMoment;

@interface ListMomentsViewController : UIViewController<
    UITableViewDelegate,
    UITableViewDataSource> {
  // A map from activities to verbs used for display.
  NSDictionary *verbMap_;
  // An array of |GTLPlusMoment|, as the data source.
  NSMutableArray *momentsData_;
  // Currently selected moment in the |momentsData_| array.
  GTLPlusMoment *selectedMoment_;
}

// The table that displays the list of moments for the user.
@property (retain, nonatomic) IBOutlet UITableView *momentsTable;
// A label to display the status of selected moment, or general status.
@property (retain, nonatomic) IBOutlet UILabel *momentStatus;
// A label to display the target of selected moment.
@property (retain, nonatomic) IBOutlet UILabel *momentTarget;
// A label to display the time of selected moment.
@property (retain, nonatomic) IBOutlet UILabel *momentTime;
// A button to remove selected moment.
@property (retain, nonatomic) IBOutlet UIButton *momentRemoval;

// Called when the remove button is pressed.
- (IBAction)removeMoment:(id)sender;

@end
