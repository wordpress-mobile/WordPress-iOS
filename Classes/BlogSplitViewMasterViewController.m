    //
//  BlogSplitViewMasterViewController.m
//  WordPress
//
//  Created by Devin Chalmers on 3/2/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "BlogSplitViewMasterViewController.h"

#import "BlogsViewController.h"
#import "BlogDataManager.h"

#import "PostsViewController.h"
#import "PagesViewController.h"
#import "CommentsViewController.h"

#import "PostViewController.h"
#import "PageViewController.h"

@implementation BlogSplitViewMasterViewController

@synthesize currentDataSource;
@synthesize currentIndexPath;

@synthesize tableView;

@synthesize postsViewController;
@synthesize pagesViewController;
@synthesize commentsViewController;
@synthesize currentPopoverController;
@synthesize detailNavController;

@synthesize commentsButton;
@synthesize segmentedControl;

- (void)dealloc {
	[[BlogDataManager sharedDataManager] removeObserver:self forKeyPath:@"currentPostIndex"];
	[[BlogDataManager sharedDataManager] removeObserver:self forKeyPath:@"currentDraftIndex"];
	[[BlogDataManager sharedDataManager] removeObserver:self forKeyPath:@"currentPageIndex"];
	[[BlogDataManager sharedDataManager] removeObserver:self forKeyPath:@"currentPageDraftIndex"];

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[tableView release], tableView = nil;
	
	[postsViewController release], postsViewController = nil;
	[pagesViewController release], pagesViewController = nil;
	[commentsViewController release], commentsViewController = nil;
	
	[detailNavController release], detailNavController = nil;

	[currentPopoverController release], currentPopoverController = nil;
	
	[commentsButton release], commentsButton = nil;
	[segmentedControl release], segmentedControl = nil;

    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(blogMenuAction:)] autorelease];
	
	[self refreshBlogData];
	self.currentDataSource = postsViewController;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBlogs:) name:@"DraftsUpdated" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBlogs:) name:@"BlogsRefreshNotification" object:nil];
	
	[[BlogDataManager sharedDataManager] addObserver:self forKeyPath:@"currentPostIndex" options:NSKeyValueObservingOptionNew context:nil];
	[[BlogDataManager sharedDataManager] addObserver:self forKeyPath:@"currentDraftIndex" options:NSKeyValueObservingOptionNew context:nil];
	[[BlogDataManager sharedDataManager] addObserver:self forKeyPath:@"currentPageIndex" options:NSKeyValueObservingOptionNew context:nil];
	[[BlogDataManager sharedDataManager] addObserver:self forKeyPath:@"currentPageDraftIndex" options:NSKeyValueObservingOptionNew context:nil];
	
	[self updateSelection];
}

- (void)setCurrentIndexPath:(NSIndexPath *)newIndexPath;
{
	int section = MIN(newIndexPath.section, [currentDataSource numberOfSectionsInTableView:tableView] - 1);
	int row = MIN(newIndexPath.row, [currentDataSource tableView:tableView numberOfRowsInSection:section] - 1);
	
	newIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
	[tableView selectRowAtIndexPath:newIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];

//	if ([newIndexPath isEqual:currentIndexPath])
//		return;
	
	[currentIndexPath release];
	currentIndexPath = [newIndexPath retain];
	
	// avoid selecting the "Load more posts..." row
	if ([currentDataSource numberOfSectionsInTableView:tableView] == 1 && [currentDataSource tableView:tableView numberOfRowsInSection:1] == 1) {
		return;
	}
	
	[tableView selectRowAtIndexPath:currentIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
	[self tableView:tableView didSelectRowAtIndexPath:currentIndexPath];
}

- (void)setCurrentDataSource:(id<UITableViewDataSource, UITableViewDelegate>)newDataSource;
{
	if (currentDataSource == newDataSource)
		return;
	
	currentDataSource = newDataSource;
	
	tableView.dataSource = currentDataSource;
	[tableView reloadData];
}

- (IBAction)selectSegmentAction:(id)sender;
{
	id<UITableViewDataSource, UITableViewDelegate> newDataSource;
	switch ([sender selectedSegmentIndex]) {
		case 0:
			newDataSource = postsViewController;
			[postsViewController loadPosts];
			break;
		case 1:
			newDataSource = pagesViewController;
			[pagesViewController loadPages];
			break;
		default:
			break;
	}
	self.currentDataSource = newDataSource;
	[self updateSelection];
}

#pragma mark -

- (void)refreshBlogData;
{
	self.navigationItem.title = [[BlogDataManager sharedDataManager].currentBlog valueForKey:@"blogName"];
	
	[postsViewController loadPosts];
	[pagesViewController loadPages];
	[commentsViewController refreshCommentsList];
}

- (void)currentBlogChanged
{
	[self refreshBlogData];
	[self updateSelection];
}

- (void)updateSelection;
{
	if (currentDataSource == postsViewController) {
		if (selectedItemType == kWPItemTypePost || selectedItemType == kWPItemTypePostDraft) {
			int sectionNum = (selectedItemType == kWPItemTypePost) ? 1 : 0;
			self.currentIndexPath = [NSIndexPath indexPathForRow:selectedItemIndex inSection:sectionNum];
		}
	} else if (currentDataSource == pagesViewController) {
		if (selectedItemType == kWPItemTypePage || selectedItemType == kWPItemTypePageDraft) {
			int sectionNum = (selectedItemType == kWPItemTypePage) ? 1 : 0;
			self.currentIndexPath = [NSIndexPath indexPathForRow:selectedItemIndex inSection:sectionNum];
		}
	}
}

#pragma mark -


- (IBAction)blogMenuAction:(id)sender;
{
self.currentPopoverController = NULL;

BlogsViewController *theBlogsViewController = [[BlogsViewController alloc] initWithStyle:UITableViewStylePlain];
// TODO - this is a bit of a hack. Should move to BlogsViewController really.
theBlogsViewController.contentSizeForViewInPopover = CGSizeMake(320, 44 * [[BlogDataManager sharedDataManager] countOfBlogs]);

UINavigationController *theNavigationController = [[UINavigationController alloc] initWithRootViewController:theBlogsViewController];

UIPopoverController *theBlogMenuPopoverController = [[UIPopoverController alloc] initWithContentViewController:theNavigationController];

[theBlogMenuPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];

[theBlogsViewController release];

self.currentPopoverController = theBlogMenuPopoverController;

[theBlogMenuPopoverController release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
{
	return YES;
}

- (IBAction)commentsAction:(id)sender;
{
	commentsButton.selected = YES;
	commentsButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
	commentsViewController.navigationItem.title = @"All Blog Comments";
	[commentsViewController refreshCommentsList];
	[detailNavController setViewControllers:[NSArray arrayWithObject:commentsViewController] animated:NO];
}

#pragma mark -
#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)theTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([currentDataSource respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]) {
		return [currentDataSource tableView:theTableView heightForRowAtIndexPath:indexPath];
	}
	return 0.0;
}

- (void)tableView:(UITableView *)theTableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([currentDataSource respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)]) {
		[currentDataSource tableView:theTableView willDisplayCell:cell forRowAtIndexPath:indexPath];
	}
	cell.accessoryType = UITableViewCellAccessoryNone;
}

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
	commentsButton.selected = NO;
	commentsButton.titleLabel.shadowOffset = CGSizeMake(0, 1);
	
	[currentDataSource tableView:theTableView didSelectRowAtIndexPath:indexPath];
	
	UIViewController *detailViewController = nil;
	
	if (currentDataSource == postsViewController) {
		detailViewController = postsViewController.postDetailViewController;
		[detailViewController refreshUIForCurrentPost];
	}
	else if (currentDataSource == pagesViewController) {
		detailViewController = pagesViewController.pageDetailsController;
	}
	
	UIBarButtonItem *newPostButton = [[[UIBarButtonItem alloc] initWithTitle:@"New Post" style:UIBarButtonItemStyleBordered target:self action:@selector(newPostAction:)] autorelease];
	detailViewController.navigationItem.rightBarButtonItem = newPostButton;
	
	if (detailViewController) {
//		[detailViewController viewWillAppear:NO];
		[detailNavController setViewControllers:[NSArray arrayWithObject:detailViewController] animated:NO];
	}
}

#pragma mark -
#pragma mark Interface actions

- (IBAction)newPostAction:(id)sender;
{
	[postsViewController showAddPostView];
	
	PostViewController *detailViewController = postsViewController.postDetailViewController;
	[detailViewController refreshUIForCompose];
	[detailViewController editAction:self];
}

- (void)refreshBlogs:(NSNotification *)notification;
{
	NSLog(@"Refreshed!");
	[tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:YES];
	[self performSelectorOnMainThread:@selector(updateSelection) withObject:nil waitUntilDone:YES];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == [BlogDataManager sharedDataManager]) {
		NSNumber *new = [change valueForKey:NSKeyValueChangeNewKey];
		int newSelectedIndex = [new intValue];
		if (newSelectedIndex < 0)
			return;
		
		WPItemType newItemType;
		if ([keyPath isEqual:@"currentDraftIndex"]) {
			newItemType = kWPItemTypePostDraft;
			NSLog(@"SHOULD SHOW DRAFT #%@", new);
		}
		if ([keyPath isEqual:@"currentPostIndex"]) {
			newItemType = kWPItemTypePost;
			NSLog(@"SHOULD SHOW POST #%@", new);
		}
		if ([keyPath isEqual:@"currentPageIndex"]) {
			newItemType = kWPItemTypePage;
			NSLog(@"SHOULD SHOW PAGE #%@", new);
		}
		if ([keyPath isEqual:@"currentPageDraftIndex"]) {
			newItemType = kWPItemTypePageDraft;
			NSLog(@"SHOULD SHOW PAGE DRAFT #%@", new);
		}
		
		if (newItemType != selectedItemType || newSelectedIndex != selectedItemIndex) {
			selectedItemType = newItemType;
			selectedItemIndex = newSelectedIndex;
			[self updateSelection];
		}
	}
}

@end
