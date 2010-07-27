//
//  BlogSplitViewMasterViewController.h
//  WordPress
//
//  Created by Devin Chalmers on 3/2/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BlogViewController.h"

typedef enum _WPItemType {
	kWPItemTypePost,
	kWPItemTypePostDraft,
	kWPItemTypePage,
	kWPItemTypePageDraft
} WPItemType;

@class PostsViewController, CommentsViewController, PagesViewController;

@interface BlogSplitViewMasterViewController : BlogViewController <UITableViewDelegate> {
	IBOutlet UITableView *tableView;
	
	WPItemType selectedItemType;
	int selectedItemIndex;
	
	id <UITableViewDataSource, UITableViewDelegate> currentDataSource;
	NSIndexPath *currentIndexPath;
	
	IBOutlet UINavigationController *detailNavController;
}

@property (nonatomic, assign) id <UITableViewDataSource, UITableViewDelegate> currentDataSource;
@property (nonatomic, retain) NSIndexPath *currentIndexPath;
@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet PostsViewController *postsViewController;
@property (nonatomic, retain) IBOutlet PagesViewController *pagesViewController;
@property (nonatomic, retain) IBOutlet UINavigationController *detailNavController;

- (void)currentBlogChanged;
- (void)refreshBlogData;
- (void)showDetailController:(UIViewController *)detailViewController;
- (IBAction)selectSegmentAction:(id)sender;
- (IBAction)blogMenuAction:(id)sender;
- (IBAction)commentsAction:(id)sender;
- (IBAction)newItemAction:(id)sender;
- (IBAction)newPostAction:(id)sender;
- (IBAction)newPageAction:(id)sender;
- (void)updateSelection;

@end
