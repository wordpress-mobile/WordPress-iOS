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
#import "PageViewController.h"
#import "DraftManager.h"
#import "MediaManager.h"
#import "BlogDataManager.h"
#import "Reachability.h"
#import "WPProgressHUD.h"
#import "IncrementPost.h"
#import "Post.h"

@interface PagesViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIAccelerometerDelegate> {
	IBOutlet UITabBarController *tabController;
    UIBarButtonItem *newButtonItem;
	UIAlertView *progressAlert;
	
	WordPressAppDelegate *appDelegate;
	DraftManager *draftManager;
	MediaManager *mediaManager;
    RefreshButtonView *refreshButton;
	BOOL anyMorePages;
	
	NSIndexPath *selectedIndexPath;
	NSMutableArray *drafts;
}

@property (nonatomic, retain) IBOutlet UITabBarController *tabController;
@property (nonatomic, assign) WordPressAppDelegate *appDelegate;
@property (readonly) UIBarButtonItem *newButtonItem;
@property (nonatomic, retain) DraftManager *draftManager;
@property (nonatomic, retain) MediaManager *mediaManager;
@property (nonatomic, assign) BOOL anyMorePages;
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) NSMutableArray *drafts;

- (void)addSpinnerToCell:(NSIndexPath *)indexPath;
- (void)removeSpinnerFromCell:(NSIndexPath *)indexPath;
- (void)loadPages;
- (void)showAddNewPage;

@end
