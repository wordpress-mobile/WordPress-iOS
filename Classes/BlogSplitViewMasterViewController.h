//
//  BlogSplitViewMasterViewController.h
//  WordPress
//
//  Created by Devin Chalmers on 3/2/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum _WPItemType {
	kWPItemTypePost,
	kWPItemTypePostDraft,
	kWPItemTypePage,
	kWPItemTypePageDraft
} WPItemType;

@class PostsViewController, CommentsViewController, PagesViewController;

@interface BlogSplitViewMasterViewController : UIViewController <UITableViewDelegate> {
	IBOutlet UITableView *tableView;
	
	WPItemType selectedItemType;
	int selectedItemIndex;
	
	id <UITableViewDataSource, UITableViewDelegate> currentDataSource;
	
	IBOutlet PostsViewController *postsViewController;
	IBOutlet PagesViewController *pagesViewController;
	IBOutlet CommentsViewController *commentsViewController;
	
	IBOutlet UIButton *commentsButton;
	IBOutlet UISegmentedControl *segmentedControl;

	UIPopoverController *currentPopoverController;
	
	IBOutlet UINavigationController *detailNavController;
}

@property (nonatomic, assign) id <UITableViewDataSource, UITableViewDelegate> currentDataSource;

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (nonatomic, retain) IBOutlet PostsViewController *postsViewController;
@property (nonatomic, retain) IBOutlet PagesViewController *pagesViewController;
@property (nonatomic, retain) IBOutlet CommentsViewController *commentsViewController;

@property (nonatomic, retain) IBOutlet UINavigationController *detailNavController;

@property (nonatomic, retain) IBOutlet UIButton *commentsButton;
@property (nonatomic, retain) IBOutlet UISegmentedControl *segmentedControl;

@property (readwrite, nonatomic, retain) UIPopoverController *currentPopoverController;

- (void)currentBlogChanged;
- (void)refreshBlogData;

- (IBAction)selectSegmentAction:(id)sender;
- (IBAction)blogMenuAction:(id)sender;
- (IBAction)commentsAction:(id)sender;

- (void)updateSelection;

@end
