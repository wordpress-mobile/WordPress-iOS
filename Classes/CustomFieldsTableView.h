//
//  CustomFieldsTableView.h
//  WordPress
//
//  Created by John Bickerstaff on 5/5/09.
//  Copyright 2009 Smilodon Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlogDataManager.h"
#import "PostPhotosViewController.h"
#import "PagePhotosViewController.h"
#import "CustomFieldsDetailController.h"

@interface CustomFieldsTableView : UITableViewController {
	CustomFieldsDetailController *customFieldsDetailController;
	
	
	PostPhotosViewController * postDetailViewController;
	PagePhotosViewController * pageDetailsController;
	
	BlogDataManager *dm;
	NSArray *customFieldsArray;
	IBOutlet	UITableView		*customFieldsTableView;
	IBOutlet	UIBarButtonItem *saveButtonItem;
	BOOL newCustomFieldBool;
	BOOL _isPost;
}

@property (nonatomic, retain) CustomFieldsDetailController *customFieldsDetailController;

@property (nonatomic, assign) PostPhotosViewController * postDetailViewController;
@property (nonatomic, assign) PagePhotosViewController *pageDetailsController;
@property (nonatomic, assign) BlogDataManager *dm;
@property (nonatomic, retain) NSArray *customFieldsArray;
@property (retain, nonatomic) UITableView * customFieldsTableView;
@property BOOL isPost;

- (void) getCustomFieldsStripMetadata;
- (NSDictionary *) getDictForThisCell:(NSString *) rowString;

@end
