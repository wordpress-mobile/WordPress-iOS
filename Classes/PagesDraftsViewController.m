//
//  PagesDraftsViewController.m
//  WordPress
//
//  Created by JanakiRam on 06/11/08.
//

#import "PagesDraftsViewController.h"
#import "BlogDataManager.h"
#import "PagesViewController.h"
#import "EditPageViewController.h"
#import "PageViewController.h"
#import "WordPressAppDelegate.h"

@interface PagesDraftsViewController (Private)
- (void) updateDraftsList;
@end


@implementation PagesDraftsViewController
@synthesize pagesListController;

#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"DraftsUpdated" object:nil];
	[super dealloc];
}

- (void)didReceiveMemoryWarning {
	WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
	[super viewDidLoad];
	dm = [BlogDataManager sharedDataManager];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDraftsList) name:@"DraftsUpdated" object:nil];
    
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	self.navigationItem.title = [NSString stringWithFormat:@"Local Drafts"];
    
   [self updateDraftsList];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	//Code to disable landscape when alert is raised.
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	if([delegate isAlertRunning] == YES)
		return NO;
	
	// Return YES for supported orientations
	return YES;
}

#pragma mark -
#pragma mark Table View Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [dm numberOfPageDrafts];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *MyIdentifier = @"DraftsTableCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
	}
	// Configure the cell
//	cell.text = ( [[dm pageDraftTitleAtIndex:indexPath.row] valueForKey:@"title"] == nil || ([[[dm pageDraftTitleAtIndex:indexPath.row] valueForKey:@"title"] length] == 0) )?
//																	@"(no title)" : [[dm pageDraftTitleAtIndex:indexPath.row] valueForKey:@"title"] ;
	
#if defined __IPHONE_3_0	
	cell.textLabel.text = ( [[dm pageDraftTitleAtIndex:indexPath.row] valueForKey:@"title"] == nil || ([[[dm pageDraftTitleAtIndex:indexPath.row] valueForKey:@"title"] length] == 0) )?
																			@"(no title)" : [[dm pageDraftTitleAtIndex:indexPath.row] valueForKey:@"title"];
	cell.textLabel.font = [cell.textLabel.font fontWithSize:15.0f];
#else if defined __IPHONE_2_0		
	cell.text = ( [[dm pageDraftTitleAtIndex:indexPath.row] valueForKey:@"title"] == nil || ([[[dm pageDraftTitleAtIndex:indexPath.row] valueForKey:@"title"] length] == 0) )?
																			@"(no title)" : [[dm pageDraftTitleAtIndex:indexPath.row] valueForKey:@"title"];
	cell.font = [cell.font fontWithSize:15.0f];
#endif
	
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	//cell.font = [cell.font fontWithSize:15.0f];
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	[dm makePageDraftAtIndexCurrent:indexPath.row];
	PageViewController *pageDetailsController=pagesListController.pageDetailsController;
	pageDetailsController.mode = 1; 
	pageDetailsController.tabController.selectedIndex=0;
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
	[[self navigationController] pushViewController:pagesListController.pageDetailsController animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		if( [dm deletePageDraftAtIndex:indexPath.row forBlog:dm.currentBlog] )
		{
			[dm loadPageDraftTitlesForCurrentBlog];
			[tableView reloadData];			
		}
		
	}
	if (editingStyle == UITableViewCellEditingStyleInsert) {
	}
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

#pragma mark -
- (void) updateDraftsList {
    [self.tableView reloadData];
}

@end