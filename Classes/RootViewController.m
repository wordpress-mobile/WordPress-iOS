#import "RootViewController.h"
#import "PostsListController.h"
#import "BlogDetailModalViewController.h"
#import "BlogDataManager.h"
#import "Reachability.h"

@interface RootViewController (private)

- (void) addBlogsToolbarItems;
- (void) showAddBlogView:(id)sender;

@end


@implementation RootViewController

@synthesize postsListController;

- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"BlogsRefreshNotification" object:nil];

	[postsListController release];
	[super dealloc];
}


/*
 
 Note: the navigation bar should be set here in loadView rather than in viewWillAppear or viewDidLoad because
 it affects how the subviews are laid out.
 
 */
- (void)viewDidLoad {
	[blogsTableView setSectionHeaderHeight:0.0f];
	
	self.title = NSLocalizedString(@"Blogs", @"RootViewController_Title");
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(blogsRefreshNotificationReceived:) name:@"BlogsRefreshNotification" object:nil];
}

- (void) showAddBlogView:(id)sender {
	
	// Set current blog to a new blog
	// Detail view will bind data into this instance and call save
	
	[[BlogDataManager sharedDataManager] makeNewBlogCurrent];
	
	
	BlogDetailModalViewController *blogDetailViewController = [[BlogDetailModalViewController alloc] initWithNibName:@"WPBlogDetailViewController" bundle:nil];
	
//	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:blogDetailViewController];
	blogDetailViewController.isModal = YES;
	blogDetailViewController.mode	= 0;

	[self.navigationController presentModalViewController:blogDetailViewController animated:YES];
//	[navigationController release];
	[blogDetailViewController refreshBlogCompose];
	blogDetailViewController.removeBlogButton.hidden = YES;
	[blogDetailViewController release];
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
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0)
		return ([[BlogDataManager sharedDataManager] countOfBlogs]+1);
	return 1;

}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
//	return 56.0f;
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell *cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero] autorelease];
//	NSString *rootviewcell = @"rootviewcell";
//	
//	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:rootviewcell];
//	if (cell == nil) {
//		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:rootviewcell] autorelease];
//	}
	
	if (indexPath.section == 0) 
	{
		if ([[BlogDataManager sharedDataManager] countOfBlogs] == indexPath.row) {
			cell.text = @"Add another blog...";
			if ([[BlogDataManager sharedDataManager] countOfBlogs] == 0)
				cell.text = @"Set up your blog";
		} else {
			if( [[[[BlogDataManager sharedDataManager] blogAtIndex:(indexPath.row)] valueForKey:@"kIsSyncProcessRunning"] intValue] == 1)
			{
				UIActivityIndicatorView *ai = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
				CGRect frame = [ai frame];
				frame.origin.x = [cell.contentView bounds].size.width - frame.size.width-55.0;
				frame.origin.y += 12;//(kPictRowHeight - frame.size.height)/2;
				
				[ai startAnimating];
				[ai setFrame:frame];
				ai.tag = 5919;	//some number
				[cell.contentView addSubview:ai];
				[cell.contentView bringSubviewToFront:ai];
				
				[ai release];
			}else
			{
				UIView *aView = [cell.contentView viewWithTag:5919];
				if( aView )
					[aView removeFromSuperview];
			}
			
			cell.text = [[[BlogDataManager sharedDataManager] blogAtIndex:(indexPath.row)] valueForKey:@"blogName"];
		}
		
		if ([[BlogDataManager sharedDataManager] countOfBlogs] == indexPath.row)
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		else
			cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	}
	else
	{
		cell.text = @"About WordPress for iPhone";
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	

	return cell;
}

// Show PostList when row is selected
- (void)tableView:(UITableView *)atableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	BlogDataManager *dataManager = [BlogDataManager sharedDataManager];
	if (indexPath.section == 0) {		
		if ([dataManager countOfBlogs] == indexPath.row || [dataManager countOfBlogs] == 0) {
			[dataManager makeNewBlogCurrent];
			BlogDetailModalViewController *blogDetailModalViewController = [[BlogDetailModalViewController alloc] initWithNibName:@"WPBlogDetailViewController" bundle:nil];
			UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:blogDetailModalViewController];
			[self.navigationController pushViewController:nc animated:YES];
			blogDetailModalViewController.removeBlogButton.hidden = YES;
			blogDetailModalViewController.isModal = NO;
			blogDetailModalViewController.mode = 0;
			[blogDetailModalViewController refreshBlogCompose];
			[nc release];
			[blogDetailModalViewController release];			
		} else {
			if( [[[dataManager blogAtIndex:indexPath.row] valueForKey:@"kIsSyncProcessRunning"] intValue] == 1 ) {
				[blogsTableView deselectRowAtIndexPath:[blogsTableView indexPathForSelectedRow] animated:YES];
				return;
			}
			[dataManager makeBlogAtIndexCurrent:(indexPath.row)];	
			NSString *url = [dataManager.currentBlog valueForKey:@"url"];
			
			if(url != nil && [url length] >= 7 && [url hasPrefix:@"http://"]) {
				url = [url substringFromIndex:7];
			}
			
			if(url != nil && [url length]) {
				url = @"wordpress.com";
			}
			
			[Reachability sharedReachability].hostName = url;
			
			if (self.postsListController == nil) {
				self.postsListController = [[PostsListController alloc] initWithNibName:@"PostsListController" bundle:nil];
			}
			
			UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:postsListController];
			postsListController.title = [[dataManager currentBlog] valueForKey:@"blogName"];
			UIBarButtonItem *blogsButton = [[UIBarButtonItem alloc] initWithTitle:@"Blogs" style:UIBarButtonItemStyleBordered target:self action:@selector(cancel:)];
			postsListController.navigationItem.leftBarButtonItem = blogsButton;
			[blogsButton release];
			[[self navigationController] pushViewController:nc animated:YES];
			[nc release];
		}
	} else 
	{
		AboutViewController *aboutViewController = [[AboutViewController alloc] initWithNibName:@"AboutWordpress" bundle:nil];
		[self.navigationController pushViewController:aboutViewController animated:YES];
		[aboutViewController release];

//		if ([dataManager countOfBlogs]) {
//			WPBlogsListController *blogsListController = [[WPBlogsListController alloc] initWithNibName:@"WPBlogsListController" bundle:nil];
//			UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:blogsListController];
//			[self.navigationController pushViewController:nc animated:YES];
//			[nc release];
//		} else {
//			[dataManager makeNewBlogCurrent];
//			BlogDetailModalViewController *blogDetailModalViewController = [[BlogDetailModalViewController alloc] initWithNibName:@"WPBlogDetailViewController" bundle:nil];
//			UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:blogDetailModalViewController];
//			[self.navigationController pushViewController:nc animated:YES];
//			blogDetailModalViewController.removeBlogButton.hidden = YES;
//			blogDetailModalViewController.isModal = NO;
//			blogDetailModalViewController.mode = 0;
//			[blogDetailModalViewController refreshBlogCompose];
//			[nc release];
//			[blogDetailModalViewController release];
//		}
	}
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
	// Set current blog to blog at the index which was clicked
	// Detail view will bind data into this instance and call save
	
	[[BlogDataManager sharedDataManager] copyBlogAtIndexCurrent:(indexPath.row)];
	
	
	
//	WPLog(@"current blog is : %@",[[[BlogDataManager sharedDataManager] currentBlog] valueForKey:@"blogName"]);
	
	
	BlogDetailModalViewController *blogDetailViewController = [[BlogDetailModalViewController alloc] initWithNibName:@"WPBlogDetailViewController" bundle:nil];
	
	blogDetailViewController.removeBlogButton.hidden = NO;
	blogDetailViewController.isModal = NO;
	blogDetailViewController.mode	= 1;

	UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:blogDetailViewController];

	[[self navigationController] pushViewController:nc animated:YES];
	[blogDetailViewController release];
	[nc release];
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
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)viewDidDisappear:(BOOL)animated {
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
		WPLog(@"%@ %@", self, NSStringFromSelector(_cmd));
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

- (void)cancel:(id)sender {
	[self.navigationController popViewControllerAnimated:YES];
}
@end

