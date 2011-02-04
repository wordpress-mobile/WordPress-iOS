//
//  AutosaveContentViewController.m
//  WordPress
//
//  Created by Chris Boyd on 8/13/10.
//

#import "AutosaveContentViewController.h"

#define FONT_SIZE 14.0f
#define CELL_CONTENT_WIDTH 320.0f
#define CELL_CONTENT_MARGIN 10.0f

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
	UILabel *label = nil;
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		
		label = [[UILabel alloc] initWithFrame:CGRectZero];
		[label setLineBreakMode:UILineBreakModeWordWrap];
		[label setMinimumFontSize:FONT_SIZE];
		[label setNumberOfLines:0];
		[label setFont:[UIFont systemFontOfSize:FONT_SIZE]];
		[label setTag:1];
		
		[[cell contentView] addSubview:label];
		[label release];
	}
	if (!label)
		label = (UILabel*)[cell viewWithTag:1];
    
	switch (indexPath.section) {
		case 0:
			label.text = autosavePost.postTitle;
			break;
		case 1:
			label.text = autosavePost.tags;
			break;
		case 2:
			label.text = autosavePost.categories;
			break;
		case 3:
			label.text = autosavePost.status;
			break;
		case 4:
			label.text = autosavePost.content;
			break;
		default:
			label.text = nil;
			break;
	}
	CGSize constraint = CGSizeMake(CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN * 2), 20000.0f);
	CGSize size = [label.text sizeWithFont:[UIFont systemFontOfSize:FONT_SIZE] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
	
	[label setFrame:CGRectMake(CELL_CONTENT_MARGIN, CELL_CONTENT_MARGIN, CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN * 2), MAX(size.height, 44.0f))];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath; {
	NSString *text = @"";
	switch (indexPath.section) {
		case 0:
			text = autosavePost.postTitle;
			break;
		case 1:
			text = autosavePost.tags;
			break;
		case 2:
			text = autosavePost.categories;
			break;
		case 3:
			text = autosavePost.status;
			break;
		case 4:
			text = autosavePost.content;
			break;
	}
	
	CGSize constraint = CGSizeMake(CELL_CONTENT_WIDTH - (CELL_CONTENT_MARGIN * 2), 20000.0f);
	CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:FONT_SIZE] constrainedToSize:constraint lineBreakMode:UILineBreakModeWordWrap];
	CGFloat height = MAX(size.height, 44.0f);
	
	return height + (CELL_CONTENT_MARGIN * 2);
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

