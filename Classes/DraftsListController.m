#import "DraftsListController.h"
#import "BlogDataManager.h"
#import "PostsListController.h"
#import "PostPhotosViewController.h"
#import "WordPressAppDelegate.h"

@implementation DraftsListController
@synthesize postsListController;

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
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updatePostsAndDraftsList) name:@"DraftsUpdated" object:nil];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
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
	return [dm numberOfDrafts];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *MyIdentifier = @"DraftsTableCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
	}
	// Configure the cell
	//cell.text = [[dm draftTitleAtIndex:indexPath.row] valueForKey:@"title"];
#if defined __IPHONE_3_0	
	cell.textLabel.text = [[dm draftTitleAtIndex:indexPath.row] valueForKey:@"title"];
	cell.textLabel.font = [cell.textLabel.font fontWithSize:15.0f];
#else if defined __IPHONE_2_0		
	cell.text = [[dm draftTitleAtIndex:indexPath.row] valueForKey:@"title"];
	cell.font = [cell.font fontWithSize:15.0f];
#endif
	cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
	//cell.font = [cell.font fontWithSize:15.0f];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	if([[[dm draftTitleAtIndex:indexPath.row] valueForKey:kAsyncPostFlag]intValue] == 1)
		return;
	
	[dm makeDraftAtIndexCurrent:indexPath.row];
	postsListController.postDetailViewController.mode = 1; 
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
	[[postsListController navigationController] pushViewController:postsListController.postDetailViewController animated:YES];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{	
	if (editingStyle == UITableViewCellEditingStyleDelete) {		
		if( [dm deleteDraftAtIndex:indexPath.row forBlog:dm.currentBlog] )
		{
			[dm loadDraftTitlesForCurrentBlog];
			[tableView reloadData];			
		}
	}
	if (editingStyle == UITableViewCellEditingStyleInsert) {
	}
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)updatePostsAndDraftsList{
	[self.tableView reloadData];
}

@end