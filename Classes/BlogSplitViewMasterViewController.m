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
BlogsViewController *theBlogsViewController = [[BlogsViewController alloc] initWithStyle:UITableViewStylePlain];
// TODO - this is a bit of a hack. Should move to BlogsViewController really.
theBlogsViewController.contentSizeForViewInPopover = CGSizeMake(320, 44 * [[BlogDataManager sharedDataManager] countOfBlogs]);

UIPopoverController *theBlogMenuPopoverController = [[UIPopoverController alloc] initWithContentViewController:theBlogsViewController];

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
	
	if (detailViewController) {
		[detailNavController setViewControllers:[NSArray arrayWithObject:detailViewController] animated:NO];
	}
}

@end
