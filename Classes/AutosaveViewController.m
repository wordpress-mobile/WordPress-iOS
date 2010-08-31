//
//  AutosaveViewController.m
//  WordPress
//
//  Created by Chris Boyd on 8/12/10.
//  Copyright 2010 WordPress. All rights reserved.
//

#import "AutosaveViewController.h"

@class PostViewController;
@implementation AutosaveViewController
@synthesize tableView, autosaves, appDelegate, postID, buttonView, restorePost, contentView, postDetailViewController, autosaveManager;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
	self.navigationItem.title = @"Autosaves";
	self.tableView.backgroundColor = [UIColor clearColor];
	self.tableView.backgroundView = nil;
	
	appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
	contentView = [[AutosaveContentViewController alloc] initWithNibName:@"AutosaveContentViewController" bundle:nil];
	autosaveManager = [[AutosaveManager alloc] init];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	[super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	autosaveManager = [[AutosaveManager alloc] init];
	return self;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
	if(autosaves.count > 6)
		return 6;
	else
		return autosaves.count;
}

- (NSString *)tableView:(UITableView *)tv titleForHeaderInSection:(NSInteger)section {
	return @"Autosaves";
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	NSDateFormatter *df = [[NSDateFormatter alloc] init];
	[df setDateStyle:NSDateFormatterShortStyle];
	[df setTimeStyle:NSDateFormatterShortStyle];
	
	Post *post = [autosaves objectAtIndex:indexPath.row];
	if(post != nil) {
		cell.textLabel.text = [df stringFromDate:post.dateCreated];
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	}
	
	[df release];
    return cell;
}

- (void)tableView:(UITableView *)tv accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	int topOfViewStack = appDelegate.navigationController.viewControllers.count - 1;
	[contentView setAutosavePost:[autosaves objectAtIndex:indexPath.row]];
	UINavigationController *myController = [[appDelegate.navigationController.viewControllers objectAtIndex:topOfViewStack] navigationController];
	[myController pushViewController:contentView animated:YES];
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	restorePost = [autosaves objectAtIndex:indexPath.row];
	UIAlertView *restoreAlert = [[UIAlertView alloc] initWithTitle:@"Restore from Autosave"
														   message:@"Are you sure you want to overwrite the current post with content from this autosave? This action cannot be undone."
														  delegate:self 
												 cancelButtonTitle:@"Cancel"
												 otherButtonTitles:@"Restore",nil];
	[restoreAlert show];
	[restoreAlert release];
	
	[tv deselectRowAtIndexPath:indexPath animated:YES];
}

-(void)tableView:(UITableView*)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	// If row is deleted, remove it from the list.
	if (editingStyle == UITableViewCellEditingStyleDelete)
	{
		Post *post = [autosaves objectAtIndex:indexPath.row];
		[autosaveManager remove:post];
		[autosaves removeObjectAtIndex:indexPath.row];
		
		[tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
		[self refreshTable];
	}
}

#pragma mark -
#pragma mark UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		NSMutableDictionary *postData = [[NSMutableDictionary alloc] init];
		[postData setObject:restorePost.uniqueID forKey:@"uniqueID"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"RestoreFromAutosaveNotification" object:nil userInfo:postData];
		[postData release];
	}
}

#pragma mark -
#pragma mark Custom methods

- (void)refreshTable {
	[tableView reloadData];
}

- (void)resetAutosaves {
	self.autosaves = [autosaveManager getForPostID:postID];
	[self doAutosaveReport];
	[self refreshTable];
}

- (void)doAutosaveReport {
	//NSLog(@"Total of %d autosaves on this device.", [autosaveManager totalAutosavesOnDevice]);
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
}

#pragma mark -
#pragma mark Dealloc

- (void)dealloc {
	[postID release];
	[autosaveManager release];
	[postDetailViewController release];
	[contentView release];
	[restorePost release];
	[buttonView release];
	[autosaves release];
	[tableView release];
    [super dealloc];
}


@end

