//
//  ListViewController.h
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

@class ListPeopleViewController;

@protocol ListPeopleViewControllerDelegate <NSObject>

// Will be called on the delegate if |allowSelection| is set to YES and the user finish selecting
// people.
- (void)viewController:(ListPeopleViewController *)viewController
         didPickPeople:(NSArray *)people;

@end

// A view controller for listing people that are visible to this sample app.
// The open-source GTLPlus libraries are required.
@interface ListPeopleViewController : UITableViewController

// Whether or not the view controller allow people selection.
@property (nonatomic, assign) BOOL allowSelection;

// A delegate for getting the callback after selecting people.
@property (nonatomic, weak) id<ListPeopleViewControllerDelegate> delegate;

@end
