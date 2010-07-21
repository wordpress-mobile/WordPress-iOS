    //
//  WelcomeViewController.m
//  WordPress
//
//  Created by Dan Roundhill on 5/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "WelcomeViewController.h"

@implementation WelcomeViewController

@synthesize tableView;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
	self.navigationItem.title = @"Welcome";
	
	if([[BlogDataManager sharedDataManager] countOfBlogs] == 0)
		self.navigationItem.backBarButtonItem = nil;
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
	UIView *headerView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)] autorelease];
	UIImageView *logo = [[UIImageView alloc] initWithFrame:CGRectMake(56, 20, 206, 128)];
	logo.image = [UIImage imageNamed:@"logo_stacked.png"];
	[headerView addSubview:logo];
	
	UILabel *headerText = [[UILabel alloc] initWithFrame:CGRectMake(20, 135, 280, 72)];
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
	return 200;
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
			cell.textLabel.text = @"Add an existing WP.com blog";
			break;
		case 2:
			cell.textLabel.text = @"Add an existing WP.org self-hosted site";
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
	int dummy = 0;
	switch (indexPath.row) {
		case 0:
			dummy = indexPath.row;
			WebSignupViewController *webSignup = [[WebSignupViewController alloc] initWithNibName:@"WebSignupViewController" bundle:[NSBundle mainBundle]];
			[super.navigationController pushViewController:webSignup animated:YES];
			break;
		case 1:
			dummy = indexPath.row;
			AddUsersBlogsViewController *addBlogs = [[AddUsersBlogsViewController alloc] initWithNibName:@"AddUsersBlogsViewController" bundle:nil];
			[super.navigationController pushViewController:addBlogs animated:YES];
			break;
		case 2:
			dummy = indexPath.row;
			EditBlogViewController *editBlog = [[EditBlogViewController alloc] initWithNibName:@"EditBlogViewController" bundle:nil];
			[super.navigationController pushViewController:editBlog animated:YES];
			break;
		default:
			break;
	}
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
	[tableView release];
    [super dealloc];
}

@end
