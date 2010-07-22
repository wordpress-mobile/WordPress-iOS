    //
//  WelcomeViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 5/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "WelcomeViewController.h"

@implementation WelcomeViewController

@synthesize tableView, appDelegate, addUsersBlogsView;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	appDelegate = [WordPressAppDelegate sharedWordPressApp];
	addUsersBlogsView = [[AddUsersBlogsViewController alloc] initWithNibName:@"AddUsersBlogsViewController" bundle:nil];
	
	if([[BlogDataManager sharedDataManager] countOfBlogs] == 0) {
		self.navigationItem.backBarButtonItem = nil;
		self.navigationItem.title = @"Welcome";
	}
	else {
		self.navigationItem.title = @"Add Blog";
	}
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
	UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 252)] autorelease];
	UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake(70, 15, 180, 180)];
	logo.image = [UIImage imageNamed:@"logo_welcome"];
	[headerView addSubview:logo];
	
	UILabel *headerText = [[UILabel alloc] initWithFrame:CGRectMake(20, 175, 280, 72)];
	headerText.backgroundColor = [UIColor clearColor];
	headerText.textColor = [UIColor darkGrayColor];
	headerText.font = [UIFont fontWithName:@"Georgia" size:14];
	headerText.numberOfLines = 0;
	headerText.textAlignment = UITextAlignmentCenter;
	headerText.text = [NSString stringWithFormat:@"Start blogging from your %@ in seconds.", 
					   [[UIDevice currentDevice] model]];
	[headerView addSubview:headerText];
	
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
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"inside didSelectRowAtIndexPath...");
	
	if(indexPath.row == 0) {
		WebSignupViewController *webSignup = [[WebSignupViewController alloc] initWithNibName:@"WebSignupViewController" bundle:[NSBundle mainBundle]];
		[super.navigationController pushViewController:webSignup animated:YES];
	}
	else if(indexPath.row == 1) {
		NSLog(@"inside didSelectRowAtIndexPath case:1...");
		if(appDelegate.isWPcomAuthenticated) {
			NSLog(@"addUsersBlogsView animated:YES...");
			[super.navigationController pushViewController:addUsersBlogsView animated:YES];
		}
		else {
			NSLog(@"addUsersBlogsView animated:NO...");
			[super.navigationController pushViewController:addUsersBlogsView animated:YES];
		}
	}
	else if(indexPath.row == 2) {
		EditBlogViewController *editBlog = [[EditBlogViewController alloc] initWithNibName:@"EditBlogViewController" bundle:nil];
		[super.navigationController pushViewController:editBlog animated:YES];
	}
	
	NSLog(@"about to call deselectRowAtIndexPath...");
	[tv deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark Custom methods

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)dealloc {
	[addUsersBlogsView release];
	[tableView release];
	[appDelegate release];
    [super dealloc];
}

@end
