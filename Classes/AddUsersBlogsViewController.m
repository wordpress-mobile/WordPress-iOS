//
//  AddUsersBlogsViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/19/10.
//

#import "AddUsersBlogsViewController.h"
#import "SFHFKeychainUtils.h"
#import "NSString+XMLExtensions.h"
#import "WordPressComApi.h"
#import "UIBarButtonItem+Styled.h"

@implementation AddUsersBlogsViewController
@synthesize usersBlogs, isWPcom, selectedBlogs, tableView, buttonAddSelected, buttonSelectAll, hasCompletedGetUsersBlogs;
@synthesize spinner, topAddSelectedButton, geolocationEnabled;
@synthesize username = _username, password = _password, url = _url;

#pragma mark -
#pragma mark View lifecycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	self.username = nil;
    self.password = nil;
	[_url release];
	[usersBlogs release];
	[selectedBlogs release];
	[tableView release];
	[buttonAddSelected release];
	[buttonSelectAll release];
	[topAddSelectedButton release];
    [super dealloc];
}

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];

	self.navigationItem.title = NSLocalizedString(@"Select Blogs", @"");
	selectedBlogs = [[NSMutableArray alloc] init];
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	// Setup WP logo table header
	NSString *logoFile = @"logo_wporg";
	if(isWPcom == YES) {
        logoFile = @"logo_wpcom@2x.png";
	}
    
    UIImageView *logoImage = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:logoFile]] autorelease];
    logoImage.frame = CGRectMake(0.0f, 0.0f, 320.0f, 70.0f);
    logoImage.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    logoImage.contentMode = UIViewContentModeCenter;
    tableView.tableHeaderView = logoImage;
    
    if (isWPcom) {
        logoImage.contentScaleFactor = 2.0f;
    }
	
//    // Setup WPcom table header
//	CGRect headerFrame = CGRectMake(0.0f, 0.0f, 320.0f, 70.0f);
//	CGRect logoFrame = CGRectMake(40.0f, 20.0f, 229.0f, 43.0f);
//	if(IS_IPAD == YES) {
//		logoFrame = CGRectMake(150.0f, 20.0f, 229.0f, 43.0f);
//	}
//	UIView *headerView = [[[UIView alloc] initWithFrame:headerFrame] autorelease];
//	UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:logoFile]];
//	logo.frame = logoFrame;
//	[headerView addSubview:logo];
//	[logo release];
//	self.tableView.tableHeaderView = headerView;
    
	if(IS_IPAD)
		self.tableView.backgroundView = nil;
	
    self.tableView.backgroundColor = [UIColor clearColor];
	self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"welcome_bg_pattern.png"]];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelAddWPcomBlogs) 
												 name:@"didCancelWPcomLogin" object:nil];
    
    if ([[UIBarButtonItem class] respondsToSelector:@selector(appearance)])
        [UIBarButtonItem styleButtonAsPrimary:buttonAddSelected];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	if((isWPcom) && (!appDelegate.isWPcomAuthenticated)) {
        WPcomLoginViewController *wpComLogin = [[WPcomLoginViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [self.navigationController presentModalViewController:wpComLogin animated:YES];
        [wpComLogin release];
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
	
	if(IS_IPAD == YES) {
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return usersBlogs.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	CGRect footerFrame = CGRectMake(0, 0, self.view.frame.size.width, 50);
	UIView *footerView = [[[UIView alloc] initWithFrame:footerFrame] autorelease];
	if(section == 0) {
		CGRect footerSpinnerFrame = CGRectMake(0, 26.0f, 20, 20);
		CGRect footerTextFrame = CGRectMake(0, 0, self.view.frame.size.width, 20);
		if((usersBlogs.count == 0) && (!hasCompletedGetUsersBlogs)) {
			UIActivityIndicatorView *footerSpinner = [[UIActivityIndicatorView alloc] initWithFrame:footerSpinnerFrame];
			footerSpinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
			[footerSpinner startAnimating];
            footerSpinner.center = CGPointMake(self.view.center.x, footerSpinner.center.y);
			[footerView addSubview:footerSpinner];
			[footerSpinner release];
			
			UILabel *footerText = [[UILabel alloc] initWithFrame:footerTextFrame];
            footerText.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
            footerText.textAlignment = UITextAlignmentCenter;
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

- (void)refreshBlogs {
    NSURL *xmlrpc;
    NSString *username, *password;
    if (isWPcom) {
        NSError *error = nil;
        xmlrpc = [NSURL URLWithString:@"https://wordpress.com/xmlrpc.php"];
        username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
        password = [SFHFKeychainUtils getPasswordForUsername:username
                                              andServiceName:@"WordPress.com"
                                                       error:&error];
    } else {
        xmlrpc = [NSURL URLWithString:_url];
        username = self.username;
        password = self.password;
    }
    AFXMLRPCClient *api = [AFXMLRPCClient clientWithXMLRPCEndpoint:xmlrpc];
    [api callMethod:@"wp.getUsersBlogs"
         parameters:[NSArray arrayWithObjects:username, password, nil]
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                usersBlogs = [responseObject retain];
                hasCompletedGetUsersBlogs = YES;
                if(usersBlogs.count > 0) {
                    // TODO: Store blog list in Core Data
                    //[[NSUserDefaults standardUserDefaults] setObject:usersBlogs forKey:@"WPcomUsersBlogs"];
                    [usersBlogs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        NSString *title = [obj valueForKey:@"blogName"];
                        title = [title stringByDecodingXMLCharacters];
                        [obj setValue:title forKey:@"blogName"];
                    }];
                    
                    [self.tableView reloadData];
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                WPFLog(@"Failed getting user blogs: %@", [error localizedDescription]);
                hasCompletedGetUsersBlogs = YES; 
                [self.tableView reloadData];
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry, can't log in", @"")
                                                                    message:[error localizedDescription]
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"Need Help?", @"")
                                                          otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
                [alertView show];
                [alertView release];   
            }];
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex { 
	switch(buttonIndex) {
		case 0: {
			HelpViewController *helpViewController = [[HelpViewController alloc] init];
						
			if (IS_IPAD) {
				helpViewController.isBlogSetup = YES;
				[self.navigationController pushViewController:helpViewController animated:YES];
			}
			else
				[appDelegate.navigationController presentModalViewController:helpViewController animated:YES];
			
			[helpViewController release];
			break;
		}
		case 1:
			//ok
			break;
		default:
			break;
	}
}

- (IBAction)saveSelectedBlogs:(id)sender {
	[[NSUserDefaults standardUserDefaults] setBool:true forKey:@"refreshCommentsRequired"];
	
    NSError *error = nil;
    if (isWPcom) {
        self.username = [[NSUserDefaults standardUserDefaults] objectForKey:@"wpcom_username_preference"];
        self.password = [SFHFKeychainUtils getPasswordForUsername:_username
                                              andServiceName:@"WordPress.com"
                                                       error:&error];
        NSLog(@"saveSelectedBlogs. username: %@, usersBlogs: %@", _username, usersBlogs);
    } else {
        NSLog(@"saveSelectedBlogs. username: %@, usersBlogs: %@", _username, usersBlogs);
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
    [self.navigationController popToRootViewControllerAnimated:YES];
    [appDelegate sendPushNotificationBlogsList]; 
}

- (void)createBlog:(NSDictionary *)blogInfo {
    NSMutableDictionary *newBlog = [NSMutableDictionary dictionaryWithDictionary:blogInfo];
    [newBlog setObject:self.username forKey:@"username"];
    [newBlog setObject:self.password forKey:@"password"];
    WPLog(@"creating blog: %@", newBlog);
    Blog *blog = [Blog createFromDictionary:newBlog withContext:appDelegate.managedObjectContext];
	blog.geolocationEnabled = self.geolocationEnabled;
	[blog dataSave];
    [blog syncBlogWithSuccess:nil failure:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
}

- (void)cancelAddWPcomBlogs {
	UIViewController *controller = [self.navigationController.viewControllers objectAtIndex:1];
	[self.navigationController popToViewController:controller animated:NO];
}

-(void)checkAddSelectedButtonStatus {
	//disable the 'Add Selected' button if they have selected 0 blogs, trac #521
	if (selectedBlogs.count == 0) {
		buttonAddSelected.enabled = FALSE;
		if (IS_IPAD)
			topAddSelectedButton.enabled = FALSE;
	}
	else {
		buttonAddSelected.enabled = TRUE;
		if (IS_IPAD)
			topAddSelectedButton.enabled = TRUE;
	}
	
}

@end
