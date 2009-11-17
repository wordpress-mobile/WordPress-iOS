//
//  PagesViewController.h
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//

#import <Foundation/Foundation.h>
#import "RefreshButtonView.h"

@class EditPageViewController, PageViewController;

@interface PagesViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate> {
@private
    UIBarButtonItem *newButtonItem;
	UIAlertView *progressAlert;

    EditPageViewController *pageDetailViewController;
    PageViewController *pageDetailsController;
    RefreshButtonView *refreshButton;
}

@property (readonly) UIBarButtonItem *newButtonItem;
@property (nonatomic, retain) EditPageViewController *pageDetailViewController;
@property (nonatomic, retain) PageViewController *pageDetailsController;

@end
