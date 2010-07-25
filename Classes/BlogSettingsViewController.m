//
//  BlogSettingsViewController.m
//  WordPress
//
//  Created by Chris Boyd on 7/25/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "BlogSettingsViewController.h"


@implementation BlogSettingsViewController


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationItem.title = @"Settings";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	NSLog(@"Editing settings for appDelegate.currentBlog: %@", appDelegate.currentBlog);
	
	if([appDelegate.currentBlog.settings objectForKey:@"geotagging"] != nil)
		geotaggingSetting = [appDelegate.currentBlog.settings objectForKey:@"geotagging"];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
	int result = 0;
	
	switch (section) {
		case 0:
			result = 3;
			break;
		case 1:
			result = 2;
		default:
			break;
	}
	
	return result;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	switch (indexPath.section) {
		case 0:
			switch (indexPath.row) {
				case 0:
					cell.textLabel.text = @"Resize Photos";
					break;
				case 1:
					cell.textLabel.text = @"Geotagging";
					break;
				case 2:
					cell.textLabel.text = @"Recent Items";
					break;
				default:
					break;
			}
			break;
		case 1:
			switch (indexPath.row) {
				case 0:
					cell.textLabel.text = @"Username";
					break;
				case 1:
					cell.textLabel.text = @"Password";
					break;
				default:
					break;
			}
		default:
			break;
	}
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *result;
	
	switch (section) {
		case 0:
			result = @"General";
			break;
		case 1:
			result = @"HTTP Authentication";
			break;
		default:
			break;
	}
	
	return result;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tv deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
}

- (void)dealloc {
	[tableView release];
	[picker release];
	[recentItems release];
	[geotaggingSetting release];
    [super dealloc];
}


@end

