//
//  PagesViewController.h
//  WordPress
//
//  Created by Janakiram on 01/11/08.
//

#import <Foundation/Foundation.h>
#import "WordPressAppDelegate.h"
#import "RefreshButtonView.h"
#import "PostTableViewCell.h"
#import "DraftManager.h"

@class EditPageViewController, PageViewController;

@interface PagesViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIAccelerometerDelegate> {
@private
    UIBarButtonItem *newButtonItem;
	UIAlertView *progressAlert;
	
	WordPressAppDelegate *appDelegate;
	DraftManager *draftManager;
    EditPageViewController *pageDetailViewController;
    PageViewController *pageDetailsController;
    RefreshButtonView *refreshButton;
	BOOL anyMorePages;
	
	NSIndexPath *selectedIndexPath;
}

@property (nonatomic, assign) WordPressAppDelegate *appDelegate;
@property (readonly) UIBarButtonItem *newButtonItem;
@property (nonatomic, retain) EditPageViewController *pageDetailViewController;
@property (nonatomic, retain) PageViewController *pageDetailsController;
@property (nonatomic, retain) DraftManager *draftManager;
@property (nonatomic, assign) BOOL anyMorePages;
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;

- (void) addSpinnerToCell:(NSIndexPath *)indexPath;
- (void) removeSpinnerFromCell:(NSIndexPath *)indexPath;
- (void) loadPages;
- (void) showAddNewPage;

@end
