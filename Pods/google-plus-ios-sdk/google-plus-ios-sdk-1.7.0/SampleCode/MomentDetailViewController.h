//
//  MomentDetailViewController.h
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

@class GTLPlusMoment;

// View controller to present detailed information about a |GTLPlusMoment| object.
// The properties of the moment are presented as cells in a table view.
@interface MomentDetailViewController : UITableViewController

// The moment whose data is presented in the table view.
@property(weak, nonatomic) GTLPlusMoment *moment;

// Sets the moment property to the |moment| object, and updates the list of keys
// for |moment.target| and |moment.result|.
- (void)resetToMoment:(GTLPlusMoment *)moment;

@end
