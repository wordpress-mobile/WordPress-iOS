//
//  AddUsersBlogsViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/19/10.
//

#import "AddUsersBlogsViewController.h"

@implementation AddUsersBlogsViewController
@synthesize usersBlogs, isWPcom, selectedBlogs, tableView, buttonAddSelected, buttonSelectAll, hasCompletedGetUsersBlogs;
@synthesize spinner, username, password, url;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	self.navigationItem.title = @"Select Blogs";
	selectedBlogs = [[NSMutableArray alloc] init];
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	// Setup WPcom table header
	CGRect headerFrame = CGRectMake(0, 0, 320, 70);
	CGRect logoFrame = CGRectMake(40, 20, 229, 43);
	NSString *logoFile = @"logo_wporg";
	if(isWPcom == YES)
		logoFile = @"logo_wpcom";
	if(DeviceIsPad() == YES) {
		logoFile = [NSString stringWithFormat:@"%@@2x.png", logoFile];
		logoFrame = CGRectMake(150, 20, 229, 43);
	}
	else if([UIDevice currentDevice].model == IPHONE_1G_NAMESTRING) {
		logoFile = [NSString stringWithFormat:@"%@.png", logoFile];
	}
	UIView *headerView = [[[UIView alloc] initWithFrame:headerFrame] autorelease];
	UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:logoFile]];
	logo.frame = logoFrame;
	[headerView addSubview:logo];
	[logo release];
	self.tableView.tableHeaderView = headerView;
	self.tableView.backgroundColor = [UIColor clearColor];
	
	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTableView:) 
	//											 name:@"didUpdateFavicons" object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTableView:) 
												 name:@"didUpdateTableData" object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelAddWPcomBlogs) 
												 name:@"didCancelWPcomLogin" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	if((isWPcom) && (!appDelegate.isWPcomAuthenticated)) {
		if(DeviceIsPad() == YES) {
			WPcomLoginViewController *wpComLogin = [[WPcomLoginViewController alloc] initWithNibName:@"WPcomLoginViewController-iPad" bundle:nil];	
			[self.navigationController pushViewController:wpComLogin animated:YES];
			[wpComLogin release];
		}
		else {
			WPcomLoginViewController *wpComLogin = [[WPcomLoginViewController alloc] initWithNibName:@"WPcomLoginViewController" bundle:nil];	
			[self.navigationController presentModalViewController:wpComLogin animated:YES];
			[wpComLogin release];
		}

	}
	else if(isWPcom) {
		if((usersBlogs == nil) && ([[NSUserDefaults standardUserDefaults] objectForKey:@"WPcomUsersBlogs"] != nil))
			usersBlogs = [[NSUserDefaults standardUserDefaults] objectForKey:@"WPcomUsersBlogs"];
		else if(usersBlogs == nil)
			[self refreshBlogs];
			//[self performSelectorInBackground:@selector(refreshBlogs) withObject:nil];
	}
	else {
		[self refreshBlogs];
		//[self performSelectorInBackground:@selector(refreshBlogs) withObject:nil];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	//	if(DeviceIsPad()) {
	//		switch (interfaceOrientation) {
	//			case UIInterfaceOrientationPortrait:
	//				[appDelegate.navigationController presentModalViewController:self animated:YES];
	//				break;
	//			case UIInterfaceOrientationPortraitUpsideDown:
	//				[appDelegate.navigationController presentModalViewController:self animated:YES];
	//				break;
	//			case UIInterfaceOrientationLandscapeLeft:
	//				[appDelegate.splitViewController presentModalViewController:self animated:YES];
	//				break;
	//			case UIInterfaceOrientationLandscapeRight:
	//				[appDelegate.splitViewController presentModalViewController:self animated:YES];
	//				break;
	//		}
	//	}
	return YES;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return usersBlogs.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	CGRect footerFrame = CGRectMake(0, 0, 320, 50);
	CGRect footerSpinnerFrame = CGRectMake(80, 0, 20, 20);
	CGRect footerTextFrame = CGRectMake(110, 0, 200, 20);
	if(DeviceIsPad() == YES) {
		footerFrame = CGRectMake(0, 0, 550, 50);
		footerSpinnerFrame = CGRectMake(190, 0, 20, 20);
		footerTextFrame = CGRectMake(220, 0, 200, 20);
	}
	UIView *footerView = [[[UIView alloc] initWithFrame:footerFrame] autorelease];
	if((usersBlogs.count == 0) && (!hasCompletedGetUsersBlogs)) {
		UIActivityIndicatorView *footerSpinner = [[UIActivityIndicatorView alloc] initWithFrame:footerSpinnerFrame];
		footerSpinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
		[footerSpinner startAnimating];
		[footerView addSubview:footerSpinner];
		[footerSpinner release];
		
		UILabel *footerText = [[UILabel alloc] initWithFrame:footerTextFrame];
		footerText.backgroundColor = [UIColor clearColor];
		footerText.textColor = [UIColor darkGrayColor];
		footerText.text = @"Loading blogs...";
		[footerView addSubview:footerText];
		[footerText release];
	}
	else if((usersBlogs.count == 0) && (hasCompletedGetUsersBlogs)) {
		UILabel *footerText = [[UILabel alloc] initWithFrame:CGRectMake(110, 0, 200, 20)];
		footerText.backgroundColor = [UIColor clearColor];
		footerText.textColor = [UIColor darkGrayColor];
		footerText.text = @"No blogs found.";
		[footerView addSubview:footerText];
		[footerText release];
	}

	return footerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 60;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	
	cell.textLabel.textAlignment = UITextAlignmentLeft;
	
	Blog *blog = [usersBlogs objectAtIndex:indexPath.row];
	if([selectedBlogs containsObject:blog.blogID])
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	else
		cell.accessoryType = UITableViewCellAccessoryNone;
	cell.textLabel.text = blog.blogName;
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	Blog *selectedBlog = [usersBlogs objectAtIndex:indexPath.row];
	
	if(![selectedBlogs containsObject:selectedBlog.blogID]) {
		[selectedBlogs addObject:selectedBlog.blogID];
	}
	else {
		int indexToRemove = -1;
		int count = 0;
		for (NSString *blogID in selectedBlogs) {
			if([blogID isEqualToString:selectedBlog.blogID]) {
				indexToRemove = count;
				break;
			}
			count++;
		}
		if(indexToRemove > -1)
			[selectedBlogs removeObjectAtIndex:indexToRemove];
	}
	[tv reloadData];
	
	if(selectedBlogs.count == usersBlogs.count)
		[self selectAllBlogs:self];
	else if(selectedBlogs.count == 0)
		[self deselectAllBlogs:self];

	[tv deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark Custom methods
									   
- (void)selectAllBlogs:(id)sender {
	[selectedBlogs removeAllObjects];
	for(Blog *blog in usersBlogs) {
		[selectedBlogs addObject:blog.blogID];
	}
	[self.tableView reloadData];
	buttonSelectAll.title = @"Deselect All";
	buttonSelectAll.action = @selector(deselectAllBlogs:);
}

- (void)deselectAllBlogs:(id)sender {
	[selectedBlogs removeAllObjects];
	[self.tableView reloadData];
	buttonSelectAll.title = @"Select All";
	buttonSelectAll.action = @selector(selectAllBlogs:);
}

- (void)refreshBlogs {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	if(isWPcom) {
		usersBlogs = [[WPDataController sharedInstance] getBlogsForUrl:@"https://wordpress.com/xmlrpc.php" 
							  username:[[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"]
							  password:[[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_password_preference"]];
	}
	else {
		usersBlogs = [[WPDataController sharedInstance] getBlogsForUrl:url username:username password:password];
	}

	hasCompletedGetUsersBlogs = YES;
	if(usersBlogs.count > 0) {
		//self.tableView.tableFooterView = nil;
		self.navigationItem.rightBarButtonItem.enabled = YES;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"didUpdateTableData" object:nil];
	}
	[self performSelectorInBackground:@selector(updateFavicons) withObject:nil];
	
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (IBAction)saveSelectedBlogs:(id)sender {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	spinner = [[WPProgressHUD alloc] initWithLabel:@"Saving..."];
	[spinner show];
	
	[self performSelectorInBackground:@selector(saveSelectedBlogsInBackground) withObject:nil];
}

- (void)saveSelectedBlogsInBackground {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	for (Blog *blog in usersBlogs) {
		if([selectedBlogs containsObject:blog.blogID]) {
			[self createBlog:blog];
		}
	}
	
	[self performSelectorOnMainThread:@selector(didSaveSelectedBlogsInBackground) withObject:nil waitUntilDone:NO];
	
	[pool release];
}

- (void)didSaveSelectedBlogsInBackground {
	[spinner dismissWithClickedButtonIndex:0 animated:YES];
    [spinner release];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[appDelegate syncBlogCategoriesAndStatuses];
	[appDelegate syncBlogs];
	
	if(DeviceIsPad() == YES) {
		[appDelegate.navigationController popToRootViewControllerAnimated:YES];
		[appDelegate.splitViewController dismissModalViewControllerAnimated:YES];
	}
	else {
		[appDelegate.navigationController popToRootViewControllerAnimated:YES];
	}
}

- (void)createBlog:(Blog *)blog {
	blog.url = [blog.url stringByReplacingOccurrencesOfString:@"http://" withString:@""];
	if([blog.url hasSuffix:@"/"])
		blog.url = [blog.url substringToIndex:blog.url.length-1];
	//blog.url = [blog.url stringByReplacingOccurrencesOfString:@".wordpress.com" withString:@""];
	url= [blog.url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	username = blog.username;
	password = blog.password;
	NSNumber *value = [NSNumber numberWithBool:NO];
	NSString *authUsername = blog.username;
	NSString *authPassword = blog.password;
	NSNumber *authEnabled = [NSNumber numberWithBool:YES];
	NSString *authBlogURL = [NSString stringWithFormat:@"%@_auth", blog.url];
	
	NSMutableDictionary *newBlog = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 username, @"username", 
									 url, @"url", 
									 authEnabled, @"authEnabled", 
									 authUsername, @"authUsername", 
									 nil];
    if (![[BlogDataManager sharedDataManager] doesBlogExist:newBlog]) {
		[[BlogDataManager sharedDataManager] resetCurrentBlog];
		
		[newBlog setValue:blog.url forKey:@"url"];
		[newBlog setValue:blog.xmlrpc forKey:@"xmlrpc"];
		[newBlog setValue:blog.blogID forKey:kBlogId];
		[newBlog setValue:blog.hostURL forKey:kBlogHostName];
		[newBlog setValue:blog.blogName forKey:@"blogName"];
		[newBlog setValue:username forKey:@"username"];
		[newBlog setValue:authEnabled forKey:@"authEnabled"];
		[[BlogDataManager sharedDataManager] updatePasswordInKeychain:password andUserName:username andBlogURL:url];
		
		[newBlog setValue:authUsername forKey:@"authUsername"];
		[[BlogDataManager sharedDataManager] updatePasswordInKeychain:authPassword
														  andUserName:authUsername
														   andBlogURL:authBlogURL];
		[newBlog setValue:value forKey:kResizePhotoSetting];
		[newBlog setValue:[NSNumber numberWithBool:YES] forKey:kSupportsPagesAndComments];
		
		[BlogDataManager sharedDataManager].isProblemWithXMLRPC = NO;
        [newBlog setObject:[NSNumber numberWithInt:1] forKey:@"kIsSyncProcessRunning"];
        [[BlogDataManager sharedDataManager] wrapperForSyncPostsAndGetTemplateForBlog:[BlogDataManager sharedDataManager].currentBlog];
        [newBlog setObject:[NSNumber numberWithInt:0] forKey:@"kIsSyncProcessRunning"];
		[[BlogDataManager sharedDataManager] setCurrentBlog:newBlog];
		[BlogDataManager sharedDataManager].currentBlogIndex = -1;
        [[BlogDataManager sharedDataManager] saveCurrentBlog];
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
}

- (void)updateFavicons {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	for(Blog *blog in usersBlogs) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"didUpdateFavicons" object:@"Completed."];
	}
	
	[pool release];
}

- (void)refreshTableView:(NSNotification *)notifcation {
	[self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
}
												
- (void)reloadData {
	[self.tableView reloadData];
}

- (void)cancelAddWPcomBlogs {
	UIViewController *controller = [self.navigationController.viewControllers objectAtIndex:1];
	[self.navigationController popToViewController:controller animated:NO];
}

#pragma mark -
#pragma mark HTTPHelper methods

- (void)httpSuccessWithDataString:(NSString *)data {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)httpFailWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
}

- (void)dealloc {
	[url release];
	[username release];
	[password release];
	[usersBlogs release];
	[selectedBlogs release];
	[tableView release];
	[buttonAddSelected release];
	[buttonSelectAll release];
    [super dealloc];
}


@end

