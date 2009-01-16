#import "RootViewController.h"
#import "BlogMainViewController.h"
#import "BlogDetailModalViewController.h"
#import "BlogDataManager.h"
#import "Reachability.h"
#import "PostsListController.h"
#import "WordPressAppDelegate.h"
#import "UIViewController+WPAnimation.h"
#import <QuartzCore/QuartzCore.h>
#import "WPLogoView.h"

@interface RootViewController (private)

- (void) addBlogsToolbarItems;
- (void) showAddBlogView:(id)sender;

@end


@implementation RootViewController

- (void)dealloc {
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"BlogsRefreshNotification" object:nil];
	
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
	blogDetailViewController.isModal = YES;
	blogDetailViewController.mode	= 0;
	[self pushTransition:blogDetailViewController];
//	[self.navigationController presentModalViewController:blogDetailViewController animated:YES];
	[blogDetailViewController refreshBlogCompose];
	blogDetailViewController.removeBlogButton.hidden = YES;
	[blogDetailViewController release];
}

- (void)blogsRefreshNotificationReceived:(id)notification
{
	[blogsTableView reloadData];
}

//- (void)syncAllBlogs:(id)sender
//{
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
	UIActivityIndicatorView *activityView = (UIActivityIndicatorView*)[cell viewWithTag:5919];
	
	activityView.hidden = YES;
	if([activityView isAnimating]){
		[activityView stopAnimating];
	}
	
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
			
			UILabel *blogName=[[UILabel alloc] initWithFrame:CGRectMake(10, 2 , 230, 50)];
			blogName.text=[[[BlogDataManager sharedDataManager] blogAtIndex:(indexPath.row)] valueForKey:@"blogName"];
			blogName.font = [UIFont boldSystemFontOfSize:18.0];
			[cell.contentView addSubview:blogName];
			[blogName release];
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
			[self pushTransition:blogDetailModalViewController];
			self.navigationController.navigationBarHidden = NO;
			blogDetailModalViewController.removeBlogButton.hidden = YES;
			blogDetailModalViewController.isModal = NO;
			blogDetailModalViewController.mode = 0;
			[blogDetailModalViewController refreshBlogCompose];
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
			
			NSDictionary *currentBlog = dataManager.currentBlog;
			
			if ( [[currentBlog valueForKey:kSupportsPagesAndComments] boolValue] ) {
				BlogMainViewController  *blogMainViewController = [[BlogMainViewController alloc] initWithNibName:@"WPBlogMainViewController" bundle:nil];
				self.title=@"Blogs";
				[self pushTransition:blogMainViewController];
				self.navigationController.navigationBarHidden = NO;
				[blogMainViewController release];
				if([[currentBlog valueForKey:kSupportsPagesAndCommentsServerCheck] boolValue])
				{
					UIAlertView *supportedWordpress = [[UIAlertView alloc] initWithTitle:@"New features available!"
																				   message:@"WordPress for iPhone now supports page editing and comment moderation.Refresh Pages and Comments in the respective screens to access the features."
																				  delegate:[[UIApplication sharedApplication] delegate]
																		 cancelButtonTitle:nil
																		 otherButtonTitles:@"OK", nil];
					[supportedWordpress show];
					WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
					[delegate setAlertRunning:YES];
					[supportedWordpress release];
					
					[currentBlog setValue:[NSNumber numberWithBool:NO]   forKey:kSupportsPagesAndCommentsServerCheck];
					[dataManager saveCurrentBlog];
				}
				
			} else {
				
				if ( [[currentBlog valueForKey:kVersionAlertShown] boolValue] == NO || [currentBlog valueForKey:kVersionAlertShown] ==NULL )
				{
					//changed the alert message  as per ticket 71
					UIAlertView *unsupportedWordpress = [[UIAlertView alloc] initWithTitle:@"New features available!"
																				   message:@"WordPress for iPhone now supports page editing and comment moderation. However, to use these features you must be running your site on WordPress 2.7+ or WordPress.com."
																				  delegate:[[UIApplication sharedApplication] delegate]
																		 cancelButtonTitle:nil
																		 otherButtonTitles:@"OK", nil];
					[unsupportedWordpress show];
					WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
					[delegate setAlertRunning:YES];
					[unsupportedWordpress release];
					[currentBlog setValue:[NSNumber numberWithBool:YES]   forKey:kVersionAlertShown];
					[dataManager saveCurrentBlog];
				}
				PostsListController *postsListController = [[PostsListController alloc] initWithNibName:@"PostsListController" bundle:nil];
				postsListController.title = [[dataManager currentBlog] valueForKey:@"blogName"];
				[self pushTransition:postsListController];
				self.navigationController.navigationBarHidden = NO;
				[postsListController release];
			}
		}
		
	}else {
		AboutViewController *aboutViewController = [[AboutViewController alloc] initWithNibName:@"AboutWordpress" bundle:nil];
		self.title=@"Home";
		[self pushTransition:aboutViewController];
		self.navigationController.navigationBarHidden = NO;
		[aboutViewController release];
	}	
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if(section == 0)
	{
		WPLogoView *img = [[[WPLogoView alloc] initWithFrame:CGRectMake(tableView.tableHeaderView.frame.origin.x, tableView.tableHeaderView.frame.origin.y, tableView.tableHeaderView.frame.size.width,tableView.tableHeaderView.frame.size.height)] autorelease];
		return img;
	}
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if(section == 0)
		return 100.0f;
	return 0.0f;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	
	// Set current blog to blog at the index which was clicked
	// Detail view will bind data into this instance and call save
	
	[[BlogDataManager sharedDataManager] copyBlogAtIndexCurrent:(indexPath.row)];
	BlogDetailModalViewController *blogDetailViewController = [[BlogDetailModalViewController alloc] initWithNibName:@"WPBlogDetailViewController" bundle:nil];
	blogDetailViewController.removeBlogButton.hidden = NO;
	blogDetailViewController.isModal = NO;
	blogDetailViewController.mode	= 1;
	[self pushTransition:blogDetailViewController];
	[blogDetailViewController refreshBlogEdit];
	[blogDetailViewController release];
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
	
	self.navigationController.navigationBarHidden= YES;
	
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
	WordPressAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
	if([delegate isAlertRunning] == YES)
		return NO;
	
	// Return YES for supported orientations
	if(self.interfaceOrientation!=interfaceOrientation) {
		self.navigationController.navigationBarHidden = NO;
		return YES;
	} else {
		return NO;
	}
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	self.navigationController.navigationBarHidden = YES;
	[blogsTableView reloadData];
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

