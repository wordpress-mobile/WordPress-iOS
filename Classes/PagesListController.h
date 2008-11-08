//
//  PagesListController.h
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//  Copyright 2008 Prithvi Information Solutions Limited. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PageDetailViewController,PageDetailsController;
@interface PagesListController : UIViewController {
	IBOutlet UIBarButtonItem *pagessStatusButton;
	IBOutlet UITableView *pagesTableView;
	PageDetailViewController *pageDetailViewController;
	PageDetailsController *pageDetailsController;
	
	BOOL connectionStatus;
}
@property (nonatomic, retain) PageDetailViewController *pageDetailViewController;
@property (nonatomic, retain) PageDetailsController *pageDetailsController;
- (IBAction)downloadRecentPages:(id)sender;
- (IBAction)showAddNewPage:(id)sender;
@end
