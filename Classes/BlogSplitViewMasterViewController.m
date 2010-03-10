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

@synthesize tableView;

@synthesize postsViewController;
@synthesize pagesViewController;
@synthesize commentsViewController;
@synthesize currentPopoverController;
@synthesize detailNavController;

@synthesize commentsButton;

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[tableView release], tableView = nil;
	
	[postsViewController release], postsViewController = nil;
	[pagesViewController release], pagesViewController = nil;
	[commentsViewController release], commentsViewController = nil;
	
	[detailNavController release], detailNavController = nil;

	[currentPopoverController release], currentPopoverController = nil;
	
	[commentsButton release], commentsButton = nil;

    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(blogMenuAction:)] autorelease];
	
	[self refreshBlogData];
	self.currentDataSource = postsViewController;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBlogs:) name:@"DraftsUpdated" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshBlogs:) name:@"BlogsRefreshNotification" object:nil];
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
	[tableView reloadData];
}

@end
