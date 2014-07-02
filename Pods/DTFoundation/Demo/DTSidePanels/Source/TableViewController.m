//
//  TableViewController.m
//  DTSidePanelController
//
//  Created by Oliver Drobnik on 15.05.13.
//  Copyright (c) 2013 Cocoanetics. All rights reserved.
//

#import "TableViewController.h"

@interface TableViewController ()

@end

@implementation TableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - Appearance Notifications

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	DTLogInfo(@"%@ %s animated:%d", self, __PRETTY_FUNCTION__, animated);
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	DTLogInfo(@"%@ %s animated:%d", self, __PRETTY_FUNCTION__, animated);
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	DTLogInfo(@"%@ %s animated:%d", self, __PRETTY_FUNCTION__, animated);
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	DTLogInfo(@"%@ %s animated:%d", self, __PRETTY_FUNCTION__, animated);
}

- (void)willMoveToParentViewController:(UIViewController *)parent
{
	[super willMoveToParentViewController:parent];
	DTLogInfo(@"%@ %s", self, __PRETTY_FUNCTION__);
}

- (void)didMoveToParentViewController:(UIViewController *)parent
{
	[super didMoveToParentViewController:parent];
	DTLogInfo(@"%@ %s", self, __PRETTY_FUNCTION__);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	DTLogInfo(@"%@ %s", self, __PRETTY_FUNCTION__);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	DTLogInfo(@"%@ %s", self, __PRETTY_FUNCTION__);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	DTLogInfo(@"%@ %s", self, __PRETTY_FUNCTION__);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
	
    // Configure the cell...
    cell.textLabel.text = @"Menu";
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	TableViewController *newTableViewController = [[TableViewController alloc] initWithStyle:UITableViewStylePlain];
	[self.navigationController pushViewController:newTableViewController animated:YES];
}

- (NSString *)description
{
	NSMutableString *description = [NSMutableString stringWithFormat:@"<%@: ", NSStringFromClass([self class])];
	if (self.navigationItem.title) {
		[description appendString:self.navigationItem.title];
	}
	[description appendString:@">"];
	return description;
}


@end
