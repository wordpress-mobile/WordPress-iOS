#import "WPBlogsListController.h"

#import "PostsListController.h"
#import "BlogDetailModalViewController.h"
#import "BlogDataManager.h"
#import "Reachability.h"

@interface WPBlogsListController (private)
- (void) addBlogsToolbarItems;
@end

@implementation WPBlogsListController

@synthesize blogDetailViewController, postsListController;
//@synthesize addBlogButton;
//@synthesize blogsToolbar, blogsTableView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

- (void)dealloc {
	[addBlogButton release];
	[blogDetailViewController release];
	[postsListController release];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"BlogsRefreshNotification" object:nil];
	
	[super dealloc];
}

/*
 Set up the navigation bar
 - Set a navigation prompt if required
 - set up the buttons
 Create the table view and toolbar and add them to a containing view
 
 Note: the navigation bar should be set here in loadView rather than in viewWillAppear or viewDidLoad because
 it affects how the subviews are laid out.
 
 */
- (void)viewDidLoad {
	self.title = NSLocalizedString(@"Blogs", @"RootViewController_Title");
	
	// set up the add blog button
	if (!addBlogButton) {
		addBlogButton = [[UIBarButtonItem alloc] 
										 initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
										 target:self
										 action:@selector(showAddBlogView:)];
	}
	self.navigationItem.leftBarButtonItem = addBlogButton;	
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blogsRefreshNotificationReceived:) name:@"BlogsRefreshNotification" object:nil];
}

- (void) showAddBlogView:(id)sender {
	
	// Set current blog to a new blog
	// Detail view will bind data into this instance and call save
	
	[[BlogDataManager sharedDataManager] makeNewBlogCurrent];
	
	
	if (self.blogDetailViewController == nil) {
		self.blogDetailViewController = [[BlogDetailModalViewController alloc] initWithNibName:@"WPBlogDetailViewController" bundle:nil];
	}
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:blogDetailViewController];
	blogDetailViewController.isModal = YES;
	blogDetailViewController.mode	= 0;

	[[self navigationController] presentModalViewController:navigationController animated:YES];
	[navigationController release];
	[blogDetailViewController refreshBlogCompose];
	blogDetailViewController.removeBlogButton.hidden = YES;
	
}

- (void)blogsRefreshNotificationReceived:(id)notification
{
	WPLog(@"blogsTableView reloadData .......");
	
	[blogsTableView reloadData];
}

//- (void)syncAllBlogs:(id)sender
//{
//	WPLog(@"syncAllBlogs .......");
//	[[BlogDataManager sharedDataManager] syncPostsForAllBlogsToQueue:nil];
//}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	
	return ([[BlogDataManager sharedDataManager] countOfBlogs]);
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	//WordPressAppDelegate *appController = [[UIApplication sharedApplication] delegate];
	//	NSString *blogTableRowCell = @"blogTableRowCell";
	
	//	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:blogTableRowCell];
	//	if (cell == nil) {
	//		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero  reuseIdentifier:blogTableRowCell] autorelease];
	//	}
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero] autorelease];
	// Set up the cell
	cell.text = [[[BlogDataManager sharedDataManager] blogAtIndex:(indexPath.row)] valueForKey:@"blogName"];
	
	if( [[[[BlogDataManager sharedDataManager] blogAtIndex:(indexPath.row)] valueForKey:@"kIsSyncProcessRunning"] intValue] == 1 )
	{
		UIActivityIndicatorView *ai = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
		CGRect frame = [ai frame];
		frame.origin.x = [cell.contentView bounds].size.width - frame.size.width-40.0;
		frame.origin.y += 12;//(kPictRowHeight - frame.size.height)/2;
		
		[ai startAnimating];
		[ai setFrame:frame];
		[cell.contentView addSubview:ai];
		[cell.contentView bringSubviewToFront:ai];
		
		[ai release];
	} 
	
	// click this indicator to edit the blog data - selecting the row will navigate to posts list for blog
	cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	
	return cell;
	
}

// Show PostList when row is selected
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if( [[[[BlogDataManager sharedDataManager] blogAtIndex:indexPath.row] valueForKey:@"kIsSyncProcessRunning"] intValue] == 1 )
	{
		[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
		return;
	}
	
	[[BlogDataManager sharedDataManager] makeBlogAtIndexCurrent:(indexPath.row)];	
	
	
	NSString *url = [[BlogDataManager sharedDataManager].currentBlog valueForKey:@"url"];
	if( url != nil && [url length] >= 7 && [url hasPrefix:@"http://"] )
	{
		url = [url substringFromIndex:7];
	}
	
	if( url != nil && [url length] )
	{
		url = @"wordpress.com";
	}

	WPLog(@"url %@", url );
	[Reachability sharedReachability].hostName = url;
	
	
	if (self.postsListController == nil) {
		self.postsListController = [[PostsListController alloc] initWithNibName:@"PostsListController" bundle:nil];
	}
	
	[[self navigationController] pushViewController:postsListController animated:YES];
	
	
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
	// Set current blog to blog at the index which was clicked
	// Detail view will bind data into this instance and call save
	
	[[BlogDataManager sharedDataManager] copyBlogAtIndexCurrent:(indexPath.row)];
	
	
	
//	WPLog(@"current blog is : %@",[[[BlogDataManager sharedDataManager] currentBlog] valueForKey:@"blogName"]);
	
	
	if (self.blogDetailViewController == nil) {
		self.blogDetailViewController = [[BlogDetailModalViewController alloc] initWithNibName:@"WPBlogDetailViewController" bundle:nil];
	}
	
	blogDetailViewController.removeBlogButton.hidden = NO;
	blogDetailViewController.isModal = NO;
	blogDetailViewController.mode	= 1;
	[[self navigationController] pushViewController:blogDetailViewController animated:YES];
	[blogDetailViewController refreshBlogEdit];
}



/*
 Override if you support editing the list
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
 
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
 }	
 if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }	
 }
 */


/*
 Override if you support conditional editing of the list
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */


/*
 Override if you support rearranging the list
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */


/*
 Override if you support conditional rearranging of the list
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */ 


- (void)viewWillAppear:(BOOL)animated {
	
	WPLog(@"Root:viewWillAppear");
	
	// this UIViewController is about to re-appear, make sure we remove the current selection in our table view
	NSIndexPath *tableSelection = [blogsTableView indexPathForSelectedRow];
	[blogsTableView deselectRowAtIndexPath:tableSelection animated:NO];
	
	// reload the table data
	// may need to optimize this with a flag to indicate if reload is needed
	[blogsTableView reloadData];
	
	[super viewWillAppear:animated];
	
	
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	WPLog(@"Root: viewDidAppear");
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)viewDidDisappear:(BOOL)animated {
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return NO;
}


- (void)didReceiveMemoryWarning {
		WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


@end
