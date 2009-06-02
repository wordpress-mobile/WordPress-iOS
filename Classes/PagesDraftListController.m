//
//  PagesDraftListController.m
//  WordPress
//
//  Created by JanakiRam on 06/11/08.
//

#import "PagesDraftListController.h"
#import "BlogDataManager.h"
#import "PagesListController.h"
#import "PageDetailViewController.h"
#import "PageDetailsController.h"
#import "WordPressAppDelegate.h"


@implementation PagesDraftListController
@synthesize pagesListController;


- (id)initWithStyle:(UITableViewStyle)style {
	if (self = [super initWithStyle:style]) {
	}
	return self;
}


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
	PageDetailsController *pageDetailsController=pagesListController.pageDetailsController;
	pageDetailsController.mode = 1; 
	pageDetailsController.tabController.selectedIndex=0;
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
	[[pagesListController navigationController] pushViewController:pagesListController.pageDetailsController animated:YES];
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

//- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath
//{
//	return UITableViewCellAccessoryDisclosureIndicator;
//}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"DraftsUpdated" object:nil];
	[super dealloc];
}


- (void)viewDidLoad {
	[super viewDidLoad];
	dm = [BlogDataManager sharedDataManager];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsAndDraftsList) name:@"DraftsUpdated" object:nil];

}

- (void)updatePostsAndDraftsList{
	[self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	self.navigationItem.title = [NSString stringWithFormat:@"Local Drafts"];
	[(UITableView *) self.view reloadData];
	
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
	WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	
	//Code to disable landscape when alert is raised.
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	if([delegate isAlertRunning] == YES)
		return NO;
	
	// Return YES for supported orientations
	return YES;
}


@end