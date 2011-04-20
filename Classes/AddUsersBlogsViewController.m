//
//  AddUsersBlogsViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/19/10.
//

#import "AddUsersBlogsViewController.h"

@implementation AddUsersBlogsViewController
@synthesize usersBlogs, isWPcom, selectedBlogs, tableView, buttonAddSelected, buttonSelectAll, hasCompletedGetUsersBlogs;
@synthesize spinner, username, password, url, topAddSelectedButton, geolocationEnabled;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];

    [FlurryAPI logEvent:@"AddUsersBlogs"];
	self.navigationItem.title = NSLocalizedString(@"Select Blogs", @"");
	selectedBlogs = [[NSMutableArray alloc] init];
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	// Setup WP logo table header
	NSString *logoFile = @"logo_wporg.png";
	if(isWPcom == YES) {
		if (DeviceIsPad())
			logoFile = @"logo_wpcom@2x.png";
		else
			logoFile = @"logo_wpcom.png";
	}
	
	
    // Setup WPcom table header
	CGRect headerFrame = CGRectMake(0, 0, 320, 70);
	CGRect logoFrame = CGRectMake(40, 20, 229, 43);
	if(DeviceIsPad() == YES) {
		logoFrame = CGRectMake(150, 20, 229, 43);
	}
	UIView *headerView = [[[UIView alloc] initWithFrame:headerFrame] autorelease];
	UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:logoFile]];
	logo.frame = logoFrame;
	[headerView addSubview:logo];
	[logo release];
	self.tableView.tableHeaderView = headerView;
    
	if(DeviceIsPad())
		self.tableView.backgroundView = nil;
	self.tableView.backgroundColor = [UIColor clearColor];
	
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
		if((usersBlogs == nil) && ([[NSUserDefaults standardUserDefaults] objectForKey:@"WPcomUsersBlogs"] != nil)) {
			usersBlogs = [[NSUserDefaults standardUserDefaults] objectForKey:@"WPcomUsersBlogs"];
		}
		else if(usersBlogs == nil) {
			[self refreshBlogs];
		}
	}
	else {
        if (usersBlogs == nil) {
            [self refreshBlogs];
        }
	}
	
	if(DeviceIsPad() == YES) {
		topAddSelectedButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add Selected", @"") 
																				 style:UIBarButtonItemStyleDone 
																				target:self 
																				action:@selector(saveSelectedBlogs:)];
		self.navigationItem.rightBarButtonItem = topAddSelectedButton;
		topAddSelectedButton.enabled = FALSE;
	}
	
    buttonAddSelected.title = NSLocalizedString(@"Add Selected", @"");
    buttonSelectAll.title = NSLocalizedString(@"Select All", @"");
	buttonAddSelected.enabled = FALSE;
	
	[self checkAddSelectedButtonStatus];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if((DeviceIsPad() == YES) || (interfaceOrientation == UIInterfaceOrientationPortrait))
		return YES;
	else
		return NO;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (isWPcom) {
        return 2;
    }
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	int result = 0;
	switch (section) {
		case 0:
			result = usersBlogs.count;
			break;
		case 1:
			result = 1;
			break;
		default:
			break;
	}
	return result;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	CGRect footerFrame = CGRectMake(0, 0, 320, 50);
	UIView *footerView = [[[UIView alloc] initWithFrame:footerFrame] autorelease];
	if(section == 0) {
		CGRect footerSpinnerFrame = CGRectMake(80, 0, 20, 20);
		CGRect footerTextFrame = CGRectMake(110, 0, 200, 20);
		if(DeviceIsPad() == YES) {
			footerSpinnerFrame = CGRectMake(190, 0, 20, 20);
			footerTextFrame = CGRectMake(220, 0, 200, 20);
		}
		if((usersBlogs.count == 0) && (!hasCompletedGetUsersBlogs)) {
			UIActivityIndicatorView *footerSpinner = [[UIActivityIndicatorView alloc] initWithFrame:footerSpinnerFrame];
			footerSpinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
			[footerSpinner startAnimating];
			[footerView addSubview:footerSpinner];
			[footerSpinner release];
			
			UILabel *footerText = [[UILabel alloc] initWithFrame:footerTextFrame];
			footerText.backgroundColor = [UIColor clearColor];
			footerText.textColor = [UIColor darkGrayColor];
			footerText.text = NSLocalizedString(@"Loading blogs...", @"");
			[footerView addSubview:footerText];
			[footerText release];
		}
		else if((usersBlogs.count == 0) && (hasCompletedGetUsersBlogs)) {
			UILabel *footerText = [[UILabel alloc] initWithFrame:CGRectMake(110, 0, 200, 20)];
			footerText.backgroundColor = [UIColor clearColor];
			footerText.textColor = [UIColor darkGrayColor];
			footerText.text = NSLocalizedString(@"No blogs found.", @"");
			[footerView addSubview:footerText];
			[footerText release];
		}
	}

	return footerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	if((section == 0) && (usersBlogs.count == 0))
		return 60;
	else if(section == 1)
		return 100;
	else
		return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	
	switch (indexPath.section) {
		case 0:
			cell.textLabel.textAlignment = UITextAlignmentLeft;
			
			NSDictionary *blog = [usersBlogs objectAtIndex:indexPath.row];
			if([selectedBlogs containsObject:[blog valueForKey:@"blogid"]])
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			else
				cell.accessoryType = UITableViewCellAccessoryNone;
			cell.textLabel.text = [blog valueForKey:@"blogName"];
            if (!cell.textLabel.text || [cell.textLabel.text isEqualToString:@""]) {
                cell.textLabel.text = [blog valueForKey:@"url"];
            }
			break;
		case 1:
			cell.textLabel.textAlignment = UITextAlignmentCenter;
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.text = NSLocalizedString(@"Sign Out", @"");
			break;
		default:
			break;
	}
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.section == 0) {
		
		NSDictionary *selectedBlog = [usersBlogs objectAtIndex:indexPath.row];
		
		if(![selectedBlogs containsObject:[selectedBlog valueForKey:@"blogid"]]) {
			[selectedBlogs addObject:[selectedBlog valueForKey:@"blogid"]];
		}
		else {
			int indexToRemove = -1;
			int count = 0;
			for (NSString *blogID in selectedBlogs) {
				if([blogID isEqual:[selectedBlog valueForKey:@"blogid"]]) {
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
	}
	else if(indexPath.section == 1) {
		[self signOut];
	}
	
	[self checkAddSelectedButtonStatus];

	[tv deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark Custom methods
									   
- (void)selectAllBlogs:(id)sender {
	[selectedBlogs removeAllObjects];
	for(NSDictionary *blog in usersBlogs) {
		[selectedBlogs addObject:[blog valueForKey:@"blogid"]];
	}
	[self.tableView reloadData];
	buttonSelectAll.title = NSLocalizedString(@"Deselect All", @"");
	buttonSelectAll.action = @selector(deselectAllBlogs:);
	[self checkAddSelectedButtonStatus];
}

- (void)deselectAllBlogs:(id)sender {
	[selectedBlogs removeAllObjects];
	[self.tableView reloadData];
	buttonSelectAll.title = NSLocalizedString(@"Select All", @"");
	buttonSelectAll.action = @selector(selectAllBlogs:);
	[self checkAddSelectedButtonStatus];
}

- (void)signOut {
    if (isWPcom) {
        appDelegate.isWPcomAuthenticated = NO;
       /* NSError *error = nil;
        [SFHFKeychainUtils deleteItemForUsername:[[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"]
                                  andServiceName:@"WordPress.com"
                                           error:&error];*/
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_username_preference"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"wpcom_authenticated_flag"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)refreshBlogs {
	[self performSelectorInBackground:@selector(refreshBlogsInBackground) withObject:nil];
}

- (void)refreshBlogsInBackground {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
	
	if(isWPcom) {
        NSError *error = nil;
        NSString *wpcom_password = [SFHFKeychainUtils getPasswordForUsername:[[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"]
                                                        andServiceName:@"WordPress.com"
                                                                 error:&error];

		usersBlogs = [[[WPDataController sharedInstance] getBlogsForUrl:@"https://wordpress.com/xmlrpc.php"
							  username:[[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"]
							  password:wpcom_password] retain];
	}
	else {
		usersBlogs = [[[WPDataController sharedInstance] getBlogsForUrl:url username:self.username password:self.password] retain];
	}

    NSLog(@"usersBlogs: %@", usersBlogs);
	hasCompletedGetUsersBlogs = YES;
	if(usersBlogs.count > 0) {
		// TODO: Store blog list in Core Data
		//[[NSUserDefaults standardUserDefaults] setObject:usersBlogs forKey:@"WPcomUsersBlogs"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"didUpdateTableData" object:nil];
	}
	[self performSelectorInBackground:@selector(updateFavicons) withObject:nil];
	
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	
	[pool release];
}

- (IBAction)saveSelectedBlogs:(id)sender {
	[[NSUserDefaults standardUserDefaults] setBool:true forKey:@"refreshCommentsRequired"];
	
    NSError *error = nil;
    if (isWPcom) {
        NSLog(@"saveSelectedBlogs. username: %@, usersBlogs: %@", username, usersBlogs);
        self.username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
        self.password = [SFHFKeychainUtils getPasswordForUsername:username
                                              andServiceName:@"WordPress.com"
                                                       error:&error];
        NSLog(@"saveSelectedBlogs. username: %@, usersBlogs: %@", username, usersBlogs);
    } else {
        NSLog(@"saveSelectedBlogs. username: %@, usersBlogs: %@", username, usersBlogs);
    }

    for (NSDictionary *blog in usersBlogs) {
		if([selectedBlogs containsObject:[blog valueForKey:@"blogid"]]) {
			[self createBlog:blog];
		}
	}

    [appDelegate.managedObjectContext save:&error];
    if (error != nil) {
        NSLog(@"Error adding blogs: %@", [error localizedDescription]);
    }
    [self didSaveSelectedBlogsInBackground];
}

- (void)didSaveSelectedBlogsInBackground {	
	if(DeviceIsPad() == YES) {
		[appDelegate.navigationController popToRootViewControllerAnimated:YES];
		[appDelegate.splitViewController dismissModalViewControllerAnimated:YES];
	}
	else {
		[appDelegate.navigationController popToRootViewControllerAnimated:YES];
	}
}

- (void)createBlog:(NSDictionary *)blogInfo {
    NSMutableDictionary *newBlog = [NSMutableDictionary dictionaryWithDictionary:blogInfo];
    [newBlog setObject:self.username forKey:@"username"];
    [newBlog setObject:self.password forKey:@"password"];
    WPLog(@"creating blog: %@", newBlog);
    Blog *blog = [Blog createFromDictionary:newBlog withContext:appDelegate.managedObjectContext];
	blog.geolocationEnabled = self.geolocationEnabled;
	[blog dataSave];
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
	[self reloadData];
}
												
- (void)reloadData {
	[self.tableView reloadData];
}

- (void)cancelAddWPcomBlogs {
	UIViewController *controller = [self.navigationController.viewControllers objectAtIndex:1];
	[self.navigationController popToViewController:controller animated:NO];
}

-(void)checkAddSelectedButtonStatus {
	//disable the 'Add Selected' button if they have selected 0 blogs, trac #521
	if (selectedBlogs.count == 0) {
		buttonAddSelected.enabled = FALSE;
		if (DeviceIsPad())
			topAddSelectedButton.enabled = FALSE;
	}
	else {
		buttonAddSelected.enabled = TRUE;
		if (DeviceIsPad())
			topAddSelectedButton.enabled = TRUE;
	}
	
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	self.username = nil;
    self.password = nil;
	[url release];
	[usersBlogs release];
	[selectedBlogs release];
	[tableView release];
	[buttonAddSelected release];
	[buttonSelectAll release];
	[topAddSelectedButton release];
    [super dealloc];
}


@end

