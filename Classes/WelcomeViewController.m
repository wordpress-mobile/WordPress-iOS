//
//  WelcomeViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 5/5/10.
//

#import "WelcomeViewController.h"

@implementation WelcomeViewController

@synthesize tableView, addUsersBlogsView, addSiteView, appDelegate
;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	
	addUsersBlogsView = [[AddUsersBlogsViewController alloc] initWithNibName:@"AddUsersBlogsViewController" bundle:nil];
	addUsersBlogsView.isWPcom = YES;
	NSString *addSiteNibName = @"AddSiteViewController";
	if(DeviceIsPad() == YES)
		addSiteNibName = @"AddSiteViewController-iPad";
	addSiteView = [[AddSiteViewController alloc] initWithNibName:addSiteNibName bundle:nil];
	
	self.tableView.backgroundColor = [UIColor clearColor];
	if(DeviceIsPad()) {
		self.tableView.backgroundView = nil;
		UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] 
										 initWithTitle:@"Cancel" 
										 style:UIBarButtonItemStylePlain 
										 target:self action:@selector(cancel:)];
		self.navigationItem.leftBarButtonItem = cancelButton;
	}
}

- (void)viewWillAppear:(BOOL)animated {
	if([[BlogDataManager sharedDataManager] countOfBlogs] == 0) {
		self.navigationItem.title = @"Welcome";
		[self.navigationItem setHidesBackButton:YES animated:YES];
	}
	else {
		self.navigationItem.title = @"Add Blog";
		[self.navigationItem setHidesBackButton:NO animated:YES];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	BOOL result = NO;
	if(DeviceIsPad()) {
		result = YES;
	}
	
	return result;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 3;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	CGRect headerViewFrame = CGRectMake(0, 0, 320, 252);
	CGRect logoViewFrame = CGRectMake(82, 15, 150, 150);
	CGRect headerTextFrame = CGRectMake(20, 145, 280, 105);
	NSString *logoName = @"logo_welcome";
	
	if(DeviceIsPad() == YES) {
		headerViewFrame = CGRectMake(0, 0, 500, 252);
		logoViewFrame = CGRectMake(175, 15, 150, 150);
		headerTextFrame = CGRectMake(25, 80, 450, 252);
		logoName = @"logo_welcome.png";
	}
	
	if([[UIDevice currentDevice] platformString] == IPHONE_1G_NAMESTRING)
		logoName = @"logo_welcome.png";
	
		
	UIView *headerView = [[[UIView alloc] initWithFrame:headerViewFrame] autorelease];
	UIImageView *logo = [[UIImageView alloc] initWithFrame:logoViewFrame];
	logo.image = [UIImage imageNamed:logoName];
	[headerView addSubview:logo];
	[logo release];
	
	UILabel *headerText = [[UILabel alloc] initWithFrame:headerTextFrame];
	headerText.backgroundColor = [UIColor clearColor];
	headerText.textColor = [UIColor darkGrayColor];
	headerText.font = [UIFont fontWithName:@"Georgia" size:22];
	headerText.numberOfLines = 0;
	headerText.textAlignment = UITextAlignmentCenter;
	headerText.text = [NSString stringWithFormat:@"Start blogging from your %@ in seconds.", 
					   [[UIDevice currentDevice] model]];
	[headerView addSubview:headerText];
	[headerText release];
	
	return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 235;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 55;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	
	switch (indexPath.row) {
		case 0:
			cell.textLabel.text = @"Start a new blog at WordPress.com";
			break;
		case 1:
			cell.textLabel.text = @"Add existing WordPress.com blog";
			break;
		case 2:
			cell.textLabel.text = @"Add existing WordPress.org site";
			break;
		default:
			break;
	}
	//cell.textLabel.textAlignment = UITextAlignmentCenter;
	cell.textLabel.numberOfLines = 0;
	cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
	if(DeviceIsPad() == YES)
		cell.textLabel.font = [UIFont boldSystemFontOfSize:20];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if(indexPath.row == 0) {
		NSString *newNibName = @"WebSignupViewController";
		if(DeviceIsPad() == YES)
			newNibName = @"WebSignupViewController-iPad";
		WebSignupViewController *webSignup = [[WebSignupViewController alloc] initWithNibName:newNibName bundle:[NSBundle mainBundle]];
		[self.navigationController pushViewController:webSignup animated:YES];
		[webSignup release];
	}
	else if(indexPath.row == 1) {
		if(appDelegate.isWPcomAuthenticated)
			[self.navigationController pushViewController:addUsersBlogsView animated:YES];
		else if(DeviceIsPad() == YES) {
			WPcomLoginViewController *wpLoginView = [[WPcomLoginViewController alloc] initWithNibName:@"WPcomLoginViewController-iPad" bundle:nil];
			[self.navigationController pushViewController:wpLoginView animated:YES];
			[wpLoginView release];
		}
		else {
			WPcomLoginViewController *wpLoginView = [[WPcomLoginViewController alloc] initWithNibName:@"WPcomLoginViewController" bundle:nil];
			[self.navigationController presentModalViewController:wpLoginView animated:YES];
			[self.navigationController pushViewController:addUsersBlogsView animated:YES];
			[wpLoginView release];
		}
	}
	else if(indexPath.row == 2) {
		//EditBlogViewController *editBlog = [[EditBlogViewController alloc] initWithNibName:@"EditBlogViewController" bundle:nil];
		[self.navigationController pushViewController:addSiteView animated:YES];
	}
	
	[tv deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark Custom methods

- (IBAction)cancel:(id)sender {
	[super dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)dealloc {
	[addSiteView release];
	[addUsersBlogsView release];
	[tableView release];
    [super dealloc];
}

@end
