//
//  AutosaveContentViewController.m
//  WordPress
//
//  Created by Chris Boyd on 8/13/10.
//

#import "AutosaveContentViewController.h"

@implementation AutosaveContentViewController
@synthesize autosavePost;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationItem.title = @"Autosave";
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self refreshTable];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 5;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	NSString *headerText;
	switch (section) {
		case 0:
			headerText = @"Title";
			break;
		case 1:
			headerText = @"Tags";
			break;
		case 2:
			headerText = @"Categories";
			break;
		case 3:
			headerText = @"Status";
			break;
		case 4:
			headerText = @"Content";
			break;
		default:
			headerText = nil;
			break;
	}
	return headerText;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.textLabel.font = [UIFont systemFontOfSize:14.0];
	}
    
	switch (indexPath.section) {
		case 0:
			cell.textLabel.text = autosavePost.postTitle;
			break;
		case 1:
			cell.textLabel.text = autosavePost.tags;
			break;
		case 2:
			cell.textLabel.text = autosavePost.categories;
			break;
		case 3:
			cell.textLabel.text = autosavePost.status;
			break;
		case 4:
			cell.textLabel.text = autosavePost.content;
			break;
		default:
			cell.textLabel.text = nil;
			break;
	}
    
    return cell;
}


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {}

#pragma mark -
#pragma mark Custom methods

- (void)refreshTable {
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[autosavePost release];
    [super dealloc];
}


@end

