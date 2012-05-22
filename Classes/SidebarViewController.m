//
//  SidebarViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 5/21/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "SidebarViewController.h"
#import "WordPressAppDelegate.h"
#import "UIImageView+Gravatar.h"

// Number of items before blogs list */
#define SIDEBAR_BLOGS_OFFSET 2
// Height for reader/notification/blog cells
#define SIDEBAR_CELL_HEIGHT 51.0f
// Height for secondary cells (posts/pages/comments/... inside a blog)
#define SIDEBAR_CELL_SECONDARY_HEIGHT 38.0f
#define SIDEBAR_BGCOLOR [UIColor colorWithWhite:0.921875f alpha:1.0f];

@interface SidebarViewController () <NSFetchedResultsControllerDelegate>
@property (nonatomic, retain) NSFetchedResultsController *resultsController;
@end

@implementation SidebarViewController
@synthesize resultsController = _resultsController;

- (void)dealloc {
    self.resultsController.delegate = nil;
    self.resultsController = nil;

    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = SIDEBAR_BGCOLOR;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return SIDEBAR_BLOGS_OFFSET + [[self.resultsController fetchedObjects] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section < SIDEBAR_BLOGS_OFFSET) {
        return 0;
    } else {
        /* Posts, Pages, Comments, Stats */
        return 4;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return SIDEBAR_CELL_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return SIDEBAR_CELL_SECONDARY_HEIGHT;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, SIDEBAR_CELL_HEIGHT)];
    headerView.backgroundColor = SIDEBAR_BGCOLOR;
    headerView.opaque = YES;
    UILabel *titleLabel = [[[UILabel alloc] initWithFrame:CGRectMake(51, 7, 220, 21)] autorelease];
    UIImageView *blavatarView = [[[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 35, 35)] autorelease];
    if (section >= SIDEBAR_BLOGS_OFFSET) {
        Blog *blog = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:(section - SIDEBAR_BLOGS_OFFSET) inSection:0]];
        [blavatarView setImageWithBlavatarUrl:blog.blavatarUrl isWPcom:blog.isWPcom];
        UILabel *urlLabel = [[[UILabel alloc] initWithFrame:CGRectMake(51, 28, 220, 18)] autorelease];
        urlLabel.adjustsFontSizeToFitWidth = YES;
        urlLabel.text = blog.hostURL;
        urlLabel.font = [UIFont systemFontOfSize:14.0f];
        urlLabel.textColor = [UIColor darkGrayColor];
        urlLabel.backgroundColor = SIDEBAR_BGCOLOR;
        [headerView addSubview:urlLabel];
        titleLabel.text = blog.blogName;
    } else {
        if (section == 0) {
            titleLabel.text = @"Read";
            blavatarView.image = [UIImage imageNamed:@"read"];
        } else {
            titleLabel.text = @"Notifications";
            blavatarView.image = [UIImage imageNamed:@"comments"];
        }
    }

    titleLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    titleLabel.backgroundColor = SIDEBAR_BGCOLOR;
    titleLabel.adjustsFontSizeToFitWidth = YES;
    [headerView addSubview:titleLabel];
    blavatarView.layer.cornerRadius = 4.0f;
    blavatarView.layer.masksToBounds = NO;
    blavatarView.layer.shadowOpacity = 0.33f;
    blavatarView.layer.shadowRadius = 2.0f;
    blavatarView.layer.shadowOffset = CGSizeZero;
    blavatarView.opaque = YES;
    [headerView addSubview:blavatarView];

    return [headerView autorelease];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:CellIdentifier];
    }
    
    // Configure the cell...
    NSString *title = nil;
    switch (indexPath.row) {
        case 0:
            title = @"Posts";
            break;
        case 1:
            title = @"Pages";
            break;
        case 2:
            title = @"Comments";
            break;
        case 3:
            title = @"Stats";
            break;
        default:
            break;
    }
    cell.textLabel.text = title;
    cell.backgroundColor = SIDEBAR_BGCOLOR;
    cell.textLabel.backgroundColor = SIDEBAR_BGCOLOR;
    
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
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
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
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

#pragma mark - Accessor methods

- (NSFetchedResultsController *)resultsController {
    if (_resultsController != nil) return _resultsController;

    NSManagedObjectContext *moc = [[WordPressAppDelegate sharedWordPressApp] managedObjectContext];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:moc]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"blogName" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // For some reasons, the cache sometimes gets corrupted
    // Since we don't really use sections we skip the cache here
    _resultsController = [[NSFetchedResultsController alloc]
                          initWithFetchRequest:fetchRequest
                          managedObjectContext:moc
                          sectionNameKeyPath:nil
                          cacheName:nil];
    _resultsController.delegate = self;

    [sortDescriptors release];
    [sortDescriptor release];
    [fetchRequest release];

    NSError *error = nil;
    if (![_resultsController performFetch:&error]) {
        WPFLog(@"Couldn't fecth blogs: %@", [error localizedDescription]);
        [_resultsController release];
        _resultsController = nil;
    }
    
    return _resultsController;
}

@end
