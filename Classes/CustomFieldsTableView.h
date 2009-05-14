//
//  CustomFieldsTableView.h
//  WordPress
//
//  Created by John Bickerstaff on 5/5/09.
//  Copyright 2009 Smilodon Software. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "BlogDataManager.h"
#import "CustomFieldsEditView.h"
#import "PostDetailViewController.h"
#import "CustomFieldsDetailController.h"



@interface CustomFieldsTableView : UITableViewController {


	CustomFieldsDetailController *customFieldsDetailController;
	
	CustomFieldsEditView *customFieldsEditView;
	PostDetailViewController * postDetailViewController;
	BlogDataManager *dm;
	NSArray *customFieldsArray;
	IBOutlet	UITableView		*customFieldsTableView;
	IBOutlet	UIBarButtonItem *saveButtonItem;
	BOOL newCustomFieldBool;
}

@property (nonatomic, retain) CustomFieldsDetailController *customFieldsDetailController;

@property (nonatomic, retain) CustomFieldsEditView *customFieldsEditView;
@property (nonatomic, assign) PostDetailViewController * postDetailViewController;
@property (nonatomic, assign) BlogDataManager *dm;
@property (nonatomic, retain) NSArray *customFieldsArray;
@property (retain, nonatomic) UITableView * customFieldsTableView;

- (void) getCustomFieldsStripMetadata;
- (NSDictionary *) getDictForThisCell:(NSString *) rowString;

@end
