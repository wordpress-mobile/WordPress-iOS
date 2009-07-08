//
//  PagesViewController.h
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//

#import <Foundation/Foundation.h>

@class EditPageViewController,PagePhotosViewController;

@interface PagesViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate> {
	UIBarButtonItem *newButtonItem;
	
	EditPageViewController *pageDetailViewController;
	PagePhotosViewController *pageDetailsController;
	
	BOOL connectionStatus;
}

@property (readonly) UIBarButtonItem *newButtonItem;
@property (nonatomic, retain) EditPageViewController *pageDetailViewController;
@property (nonatomic, retain) PagePhotosViewController *pageDetailsController;

@end
