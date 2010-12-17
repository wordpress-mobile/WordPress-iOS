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
#import "PageManager.h"
#import "DraftManager.h"
#import "MediaManager.h"
#import "BlogDataManager.h"
#import "WPReachability.h"
#import "WPProgressHUD.h"
#import "UILoadMoreCell.h"
#import "Post.h"

@interface PagesViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, UIAccelerometerDelegate> {
	IBOutlet UITabBarController *tabController;
    UIBarButtonItem *newButtonItem;
	
	BlogDataManager *dm;
	WordPressAppDelegate *appDelegate;
	PageManager *pageManager;
	DraftManager *draftManager;
	MediaManager *mediaManager;
    RefreshButtonView *refreshButton;
	WPProgressHUD *progressAlert;
	
	NSIndexPath *selectedIndexPath;
	NSMutableArray *drafts, *pages;
	int loadLimit;
}

@property (nonatomic, retain) IBOutlet UITabBarController *tabController;
@property (nonatomic, assign) WordPressAppDelegate *appDelegate;
@property (readonly) UIBarButtonItem *newButtonItem;
@property (nonatomic, assign) BlogDataManager *dm;
@property (nonatomic, retain) PageManager *pageManager;
@property (nonatomic, retain) DraftManager *draftManager;
@property (nonatomic, retain) MediaManager *mediaManager;
@property (nonatomic, assign) BOOL anyMorePages;
@property (nonatomic, retain) NSIndexPath *selectedIndexPath;
@property (nonatomic, retain) NSMutableArray *drafts, *pages;
@property (nonatomic, retain) WPProgressHUD *progressAlert;
@property (nonatomic, assign) int loadLimit;

- (void)loadPages;
- (void)showAddNewPage;
- (void)refreshHandler;
- (void)addRefreshButton;
- (void)deletePageAtIndexPath:(NSIndexPath *)indexPath;
- (void)didDeleteDraftAtIndexPath:(NSIndexPath *)indexPath;
- (void)didDeletePageAtIndexPath:(NSIndexPath *)indexPath;
- (void)refreshTable;
- (NSDate *)localDateFromGMT:(NSDate *)sourceDate;
- (void)loadMore;
- (void)loadMoreInBackground;
- (void)addNewPage:(NSNotification *)notification;

@end
