//
//  AddUsersBlogsViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/19/10.
//

#import <QuartzCore/QuartzCore.h>
#import "AddUsersBlogsViewController.h"
#import "SFHFKeychainUtils.h"
#import "NSString+XMLExtensions.h"
#import "WordPressComApi.h"
#import "UIBarButtonItem+Styled.h"
#import "ReachabilityUtils.h"
#import "WebSignupViewController.h"
#import "UIImageView+Gravatar.h"

@interface AddUsersBlogsViewController()

@property (nonatomic, strong) UIView *noblogsView;

- (void)showNoBlogsView;
- (void)hideNoBlogsView;
- (void)wpcomSignupNotificationReceived:(NSNotification *)notification;
- (void)maskImageView:(UIImageView *)imageView corner:(UIRectCorner)corner;

@end

@implementation AddUsersBlogsViewController {
    UIAlertView *failureAlertView;
}

@synthesize usersBlogs, isWPcom, selectedBlogs, tableView, buttonAddSelected, buttonSelectAll, hasCompletedGetUsersBlogs;
@synthesize topAddSelectedButton, geolocationEnabled;
@synthesize username = _username, password = _password, url = _url;
@synthesize noblogsView;

#pragma mark -
#pragma mark View lifecycle

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    failureAlertView.delegate = nil;
}

- (void)viewDidLoad {
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidLoad];

	self.navigationItem.title = NSLocalizedString(@"Select Blogs", @"");
	self.selectedBlogs = [NSMutableArray array];
    
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	// Setup WP logo table header
	NSString *logoFile = @"logo_wporg";
	if(isWPcom == YES) {
        logoFile = @"logo_wpcom@2x.png";
	}
    
    UIImageView *logoImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:logoFile]];
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

	if (usersBlogs.count == 0) {
		buttonSelectAll.enabled = FALSE;
	}

	if((isWPcom) && (!appDelegate.isWPcomAuthenticated)) {
        WPcomLoginViewController *wpComLogin = [[WPcomLoginViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [self.navigationController presentModalViewController:wpComLogin animated:YES];
	}
	else if(isWPcom) {
		if((usersBlogs == nil) && ([[NSUserDefaults standardUserDefaults] objectForKey:@"WPcomUsersBlogs"] != nil)) {
			usersBlogs = [[NSUserDefaults standardUserDefaults] objectForKey:@"WPcomUsersBlogs"];
		}
		else if(usersBlogs == nil) {
			[self refreshBlogs];
		} else if([usersBlogs count] == 0){
            [self refreshBlogs]; //Maybe just returning from creating a blog
            [self hideNoBlogsView];
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

- (void)viewDidUnload {
    [super viewDidUnload];
    
    self.tableView = nil;
    self.buttonAddSelected = nil;
    self.buttonSelectAll = nil;
    self.topAddSelectedButton = nil;
    self.noblogsView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (isWPcom && [Blog countWithContext:[appDelegate managedObjectContext]] == 0) {
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
	CGRect footerFrame = CGRectMake(0, 0, self.view.frame.size.width, 50);
	UIView *footerView = [[UIView alloc] initWithFrame:footerFrame];
	if(section == 0) {
		CGRect footerSpinnerFrame = CGRectMake(0, 26.0f, 20, 20);
		CGRect footerTextFrame = CGRectMake(0, 0, self.view.frame.size.width, 20);
		if((usersBlogs.count == 0) && (!hasCompletedGetUsersBlogs)) {
			UIActivityIndicatorView *footerSpinner = [[UIActivityIndicatorView alloc] initWithFrame:footerSpinnerFrame];
			footerSpinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
			[footerSpinner startAnimating];
            footerSpinner.center = CGPointMake(self.view.center.x, footerSpinner.center.y);
			[footerView addSubview:footerSpinner];
			
			UILabel *footerText = [[UILabel alloc] initWithFrame:footerTextFrame];
            footerText.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
            footerText.textAlignment = UITextAlignmentCenter;
			footerText.backgroundColor = [UIColor clearColor];
			footerText.textColor = [UIColor darkGrayColor];
			footerText.text = NSLocalizedString(@"Loading blogs...", @"");
			[footerView addSubview:footerText];
		}
		else if((usersBlogs.count == 0) && (hasCompletedGetUsersBlogs)) {
            if (!isWPcom) {
                UILabel *footerText = [[UILabel alloc] initWithFrame:CGRectMake(110, 0, 200, 20)];
                footerText.backgroundColor = [UIColor clearColor];
                footerText.textColor = [UIColor darkGrayColor];
                footerText.text = NSLocalizedString(@"No blogs found.", @"");
                [footerView addSubview:footerText];
            } else {
                //User has no blogs at WPCom but has signed in successfully, lets finish and take them to the reader
                [[NSNotificationCenter defaultCenter] postNotificationName:@"BlogsRefreshNotification" object:nil];
            }
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
	
	switch (indexPath.section) {
		case 0:
        {
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
            NSURL *blogURL = [NSURL URLWithString:[blog valueForKey:@"url"]];
            [cell.imageView setImageWithBlavatarUrl:[blogURL host] isWPcom:isWPcom];
            
            if (indexPath.row == 0) {
                [self maskImageView:cell.imageView corner:UIRectCornerTopLeft];
            } else if (indexPath.row == ([self.tableView numberOfRowsInSection:indexPath.section] -1)) {
                [self maskImageView:cell.imageView corner:UIRectCornerBottomLeft];
            } else {
                cell.imageView.layer.mask = NULL;
            }
            
			break;
        }
        case 1:
        {
            cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.accessoryType = UITableViewCellAccessoryNone; 
            cell.textLabel.text = NSLocalizedString(@"Sign Out", @"");
            cell.imageView.image = nil;
            break;
        }
		default:
        {
			break;
        }
	}
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		
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
	} else if(indexPath.section == 1) { 
        [self signOut]; 
    }
	
	[self checkAddSelectedButtonStatus];

	[tv deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark Custom methods

- (void)maskImageView:(UIImageView *)imageView corner:(UIRectCorner)corner {
    CGRect frame = CGRectMake(0.0, 0.0, 43.0, 43.0);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:frame
                                               byRoundingCorners:corner cornerRadii:CGSizeMake(7.0f, 7.0f)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = frame;
    maskLayer.path = path.CGPath;
    imageView.layer.mask = maskLayer;
}

- (NSArray *)usersBlogs {
    return [usersBlogs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        NSNumber *hidden = [evaluatedObject objectForKey:@"hidden"];
        return ((hidden == nil) || [hidden boolValue]);
    }]];
}

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
        [[WordPressComApi sharedApi] signOut]; 
    } 
    [self.navigationController popViewControllerAnimated:YES]; 
}

- (void)refreshBlogs {
    
    if(![ReachabilityUtils isInternetReachable]) {
        [ReachabilityUtils showAlertNoInternetConnectionWithDelegate:self];
        hasCompletedGetUsersBlogs = YES; 
        [self.tableView reloadData];
        return;
    }
    
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
    WPXMLRPCClient *api = [WPXMLRPCClient clientWithXMLRPCEndpoint:xmlrpc];
    [api callMethod:@"wp.getUsersBlogs"
         parameters:[NSArray arrayWithObjects:username, password, nil]
            success:^(AFHTTPRequestOperation *operation, id responseObject) {
                usersBlogs = responseObject;
                hasCompletedGetUsersBlogs = YES;
                if(usersBlogs.count > 0) {
                    buttonSelectAll.enabled = TRUE;
                    [usersBlogs enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                        NSString *title = [obj valueForKey:@"blogName"];
                        title = [title stringByDecodingXMLCharacters];
                        [obj setValue:title forKey:@"blogName"];
                    }];
                    
                    if(usersBlogs.count > 1) {
                        [self hideNoBlogsView];
                        [self.tableView reloadData];
                    } else {
                        [selectedBlogs removeAllObjects];
                        for(NSDictionary *blog in usersBlogs) {
                            [selectedBlogs addObject:[blog valueForKey:@"blogid"]];
                        }
                        [self saveSelectedBlogs];
                    }
                } else {
                    
                    // User blogs count == 0.  Prompt the user to create a blog.
                    [self showNoBlogsView];
                    [self.tableView reloadData];
                    
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                WPFLog(@"Failed getting user blogs: %@", [error localizedDescription]);
                [self hideNoBlogsView];
                hasCompletedGetUsersBlogs = YES; 
                [self.tableView reloadData];
                if (failureAlertView == nil) {
                    failureAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Sorry, can't log in", @"")
                                                                  message:[error localizedDescription]
                                                                 delegate:self
                                                        cancelButtonTitle:NSLocalizedString(@"Need Help?", @"")
                                                        otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
                    failureAlertView.tag = 1;
                    [failureAlertView show];
                }
            }];
}


- (void)showNoBlogsView {
    if(!self.noblogsView) {
        CGFloat width = 282.0f;
        CGFloat height = 160.0f;
        CGFloat x = (self.view.frame.size.width / 2.0f) - (width / 2.0f);
        CGFloat y = (self.view.frame.size.height / 2.0f) - (height / 2.0f);
        self.noblogsView = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
        self.noblogsView.backgroundColor = [UIColor clearColor];

        self.noblogsView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin |
                                            UIViewAutoresizingFlexibleRightMargin |
                                            UIViewAutoresizingFlexibleTopMargin |
                                            UIViewAutoresizingFlexibleBottomMargin;

        UIColor *textColor = [UIColor colorWithRed:33.0f/255.0f green:33.0f/255.0f blue:33.0f/255.0f alpha:1.0];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.backgroundColor = [UIColor clearColor];
        label.numberOfLines = 0;
        label.lineBreakMode = UILineBreakModeWordWrap;
        label.font = [UIFont fontWithName:@"Georgia" size:16.0f];
        label.shadowOffset = CGSizeMake(0.0f, 1.0f);
        label.textColor = textColor;
        label.shadowColor = [UIColor whiteColor];
        label.textAlignment = UITextAlignmentCenter;

        if ([WordPressComApi sharedApi].username) {
            label.text = NSLocalizedString(@"You do not seem to have any blogs. Would you like to create one now?", @"");
        } else {
            label.text = NSLocalizedString(@"You do not seem to have any blogs.", @"");
        }

        label.frame = CGRectMake(0.0, 0.0, width, 38.0);
        [self.noblogsView addSubview:label];
        
        if ([WordPressComApi sharedApi].username) {            
            width = 282.0f;
            height = 44.0f;
            x = (noblogsView.frame.size.width / 2.0f) - (width / 2.0f);
            y = label.frame.size.height + 10.0f;

            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.frame = CGRectMake(x, y, width, height);
            button.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:15.0];
            [button setTitleColor:textColor forState:UIControlStateNormal];
            [button setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
            button.titleLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
            [button setImage:[UIImage imageNamed:@"welcome_button_asterisk.png"] forState:UIControlStateNormal];
            [button setContentEdgeInsets:UIEdgeInsetsMake(0.0f, 15.0f, 0.0f, 0.0f)];
            [button setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 10.0f, 0.0f, 0.0f)];
            [button setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            [button setBackgroundImage:[UIImage imageNamed:@"welcome_button_bg_full"] forState:UIControlStateNormal];
            [button setBackgroundImage:[UIImage imageNamed:@"welcome_button_bg_full_highlighted.png"] forState:UIControlStateHighlighted];
            [button setTitle:NSLocalizedString(@"Create WordPress.com Blog", @"") forState:UIControlStateNormal];
            [button addTarget:self action:@selector(handleCreateBlogTapped:) forControlEvents:UIControlEventTouchUpInside];

            [self.noblogsView addSubview:button];
        }
        
        [self.view addSubview:noblogsView];
    }
    self.buttonSelectAll.enabled = NO;
    self.noblogsView.alpha = 0.0;
    self.noblogsView.hidden = NO;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.noblogsView.alpha = 1.0f;
    }];
}


- (void)hideNoBlogsView {
    if(!self.noblogsView) return;
    self.noblogsView.hidden = YES;
    self.buttonSelectAll.enabled = YES;
}


- (void)handleCreateBlogTapped:(id)sender {
    NSString *newNibName = @"WebSignupViewController";
    if(IS_IPAD == YES)
        newNibName = @"WebSignupViewController-iPad";
    WebSignupViewController *webSignup = [[WebSignupViewController alloc] initWithNibName:newNibName bundle:[NSBundle mainBundle]];
    [self.navigationController pushViewController:webSignup animated:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wpcomSignupNotificationReceived:) name:@"wpcomSignupNotification" object:nil];

   
}

- (void)wpcomSignupNotificationReceived:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"wpcomSignupNotification" object:nil];
    [self.navigationController popToViewController:self animated:YES]; // Discard the create blog view controller. 
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        if (alertView.tag == 1) {
            HelpViewController *helpViewController = [[HelpViewController alloc] init];
            
            if (IS_IPAD) {
                helpViewController.isBlogSetup = YES;
                [self.navigationController pushViewController:helpViewController animated:YES];
            }
            else
                [appDelegate.navigationController presentModalViewController:helpViewController animated:YES];
            
        }
    } else {
        if (alertView.tag == 1) {
            //OK
        } else {
            // Retry
            hasCompletedGetUsersBlogs = NO; 
            [self.tableView reloadData];
            [self performSelector:@selector(refreshBlogs) withObject:nil afterDelay:0.1]; // Short delay so tableview can redraw.
        }
    }

    if (failureAlertView == alertView) {
        failureAlertView = nil;
    }
}

- (IBAction)saveSelectedBlogs:(id)sender {
    [self saveSelectedBlogs];
}

- (void)saveSelectedBlogs {
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
    [[WordPressComApi sharedApi] syncPushNotificationInfo];
}

- (void)createBlog:(NSDictionary *)blogInfo {
    NSMutableDictionary *newBlog = [NSMutableDictionary dictionaryWithDictionary:blogInfo];
    [newBlog setObject:self.username forKey:@"username"];
    [newBlog setObject:self.password forKey:@"password"];
    WPLog(@"creating blog: %@", newBlog);
    Blog *blog = [Blog createFromDictionary:newBlog withContext:appDelegate.managedObjectContext];
	blog.geolocationEnabled = self.geolocationEnabled;
	[blog dataSave];
    [blog syncBlogWithSuccess:^{
        if( ! [blog isWPcom] )
            [[WordPressComApi sharedApi] syncPushNotificationInfo];
    }
                      failure:nil];
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
