//
//  PagesViewController.h
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//

#import <Foundation/Foundation.h>
#import "RefreshButtonView.h"
#import "PostTableViewCell.h"

@class EditPageViewController, PageViewController;

@interface PagesViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate> {
@private
    UIBarButtonItem *newButtonItem;
	UIAlertView *progressAlert;
	//PostTableViewCell *cell;

    EditPageViewController *pageDetailViewController;
    PageViewController *pageDetailsController;
    RefreshButtonView *refreshButton;
	BOOL anyMorePages;
}

@property (readonly) UIBarButtonItem *newButtonItem;
@property (nonatomic, retain) EditPageViewController *pageDetailViewController;
@property (nonatomic, retain) PageViewController *pageDetailsController;
//@property (nonatomic, retain) PostTableViewCell	*cell;
@property (nonatomic, assign) BOOL anyMorePages;

- (void) addSpinnerToCell:(NSIndexPath *)indexPath;
- (void) removeSpinnerFromCell:(NSIndexPath *)indexPath;

@end
