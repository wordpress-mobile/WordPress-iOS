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
#import "SidebarSectionHeaderView.h"
#import "SectionInfo.h"
#import "PostsViewController.h"
#import "PagesViewController.h"
#import "CommentsViewController.h"
#import "StatsTableViewController.h"
#import "WPReaderViewController.h"
#import "WPTableViewController.h"

// Number of items before blogs list */
#define SIDEBAR_BLOGS_OFFSET 0
// Height for reader/notification/blog cells
#define SIDEBAR_CELL_HEIGHT 51.0f
// Height for secondary cells (posts/pages/comments/... inside a blog)
#define SIDEBAR_CELL_SECONDARY_HEIGHT 38.0f
#define SIDEBAR_BGCOLOR [UIColor colorWithWhite:0.921875f alpha:1.0f];
#define HEADER_HEIGHT 47
#define DEFAULT_ROW_HEIGHT 48
#define NUM_ROWS 4

@interface SidebarViewController () <NSFetchedResultsControllerDelegate>
@property (nonatomic, retain) NSFetchedResultsController *resultsController;
@property (nonatomic, assign) NSInteger openSectionIndex;
@property (nonatomic, strong) NSMutableArray* sectionInfoArray;
@property (nonatomic, assign) NSInteger topSectionRowCount;
@end

@implementation SidebarViewController
@synthesize resultsController = _resultsController, openSectionIndex=openSectionIndex_, sectionInfoArray=sectionInfoArray_;
@synthesize topSectionRowCount = topSectionRowCount_;
@synthesize tableView, footerButton;

- (void)dealloc {
    self.resultsController.delegate = nil;
    self.resultsController = nil;
    [selectedIndex release];
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.view.backgroundColor = SIDEBAR_BGCOLOR;
    openSectionIndex_ = NSNotFound;
    
    // Depending on what we want to add here (quick video? etc) created a variable for the row count
    topSectionRowCount_ = 2;
    
    // create the sectionInfoArray, stores data for collapsing/expanding sections in the tableView
	if ((self.sectionInfoArray == nil) || ([self.sectionInfoArray count] != [self numberOfSectionsInTableView:self.tableView])) {
		
        // For each play, set up a corresponding SectionInfo object to contain the default height for each row.
		NSMutableArray *infoArray = [[NSMutableArray alloc] init];
		
		for (Blog *blog in [self.resultsController fetchedObjects]) {
			
			SectionInfo *sectionInfo = [[SectionInfo alloc] init];			
			sectionInfo.blog = blog;
			sectionInfo.open = NO;
			
            NSNumber *defaultRowHeight = [NSNumber numberWithInteger:DEFAULT_ROW_HEIGHT];
			for (NSInteger i = 0; i < NUM_ROWS; i++) {
				[sectionInfo insertObject:defaultRowHeight inRowHeightsAtIndex:i];
			}
			
			[infoArray addObject:sectionInfo];
		}
		
		self.sectionInfoArray = infoArray;
        [infoArray release];
	}
    
    // Select the Reader row
    NSIndexPath *path = [NSIndexPath indexPathForRow:1 inSection:0];
    [self.tableView selectRowAtIndexPath: path animated:NO scrollPosition:UITableViewScrollPositionNone];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [tableView release];
    [footerButton release];
    selectedIndex = nil;
    
    self.sectionInfoArray = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)viewWillAppear:(BOOL)animated {
	
	[super viewWillAppear:animated]; 
	
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of blogs + the top section
    return [[self.resultsController fetchedObjects] count] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return self.topSectionRowCount;
    } else {
        SectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:section - 1];
        return sectionInfo.open ? NUM_ROWS : 0;
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return 0;
    else 
        return HEADER_HEIGHT;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return SIDEBAR_CELL_SECONDARY_HEIGHT;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0)
        return nil;
    Blog *blog = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:(section - 1) inSection:0]];
    SectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:section - 1];
    if (!sectionInfo.headerView) {
        sectionInfo.headerView = [[SidebarSectionHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.tableView.bounds.size.width, HEADER_HEIGHT) blog:blog section:section delegate:self];
    }
    
    return sectionInfo.headerView;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    NSString *title = nil;
    
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                title = NSLocalizedString(@"Quick Photo", @"");
                break;
            case 1:
                title = NSLocalizedString(@"Read", @"");
                break;
        }
    } else {
        switch (indexPath.row) {
            case 0:
                title = NSLocalizedString(@"Posts", @"");
                break;
            case 1:
                title = NSLocalizedString(@"Pages", @"");
                break;
            case 2:
                title = NSLocalizedString(@"Comments", @"");
                break;
            case 3:
                title = NSLocalizedString(@"Stats", @"");
                break;
            default:
                break;
        }
    }
    
    
    cell.textLabel.text = title;
    cell.backgroundColor = SIDEBAR_BGCOLOR;
    cell.textLabel.backgroundColor = SIDEBAR_BGCOLOR;
    
    return cell;
}

#pragma mark Section header delegate

-(void)sectionHeaderView:(SidebarSectionHeaderView*)sectionHeaderView sectionOpened:(NSInteger)sectionOpened {
    
	SectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:sectionOpened - 1];
	
	sectionInfo.open = YES;
    NSIndexPath *currentIndex = [self.tableView indexPathForSelectedRow];
    if (currentIndex) {
        selectedIndex = [[NSIndexPath indexPathForRow:currentIndex.row inSection:currentIndex.section] retain];
    }
    
    /*
     Create an array containing the index paths of the rows to insert: These correspond to the rows for each quotation in the current section.
     */
    NSMutableArray *indexPathsToInsert = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < NUM_ROWS; i++) {
        [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:i inSection:sectionOpened]];
    }
    
    /*
     Create an array containing the index paths of the rows to delete: These correspond to the rows for each quotation in the previously-open section, if there was one.
     */
    NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
    
    NSInteger previousOpenSectionIndex = self.openSectionIndex;
    if (previousOpenSectionIndex != NSNotFound) {
        SectionInfo *previousOpenSection = [self.sectionInfoArray objectAtIndex:previousOpenSectionIndex - 1];
        previousOpenSection.open = NO;
        [previousOpenSection.headerView toggleOpenWithUserAction:NO];
        for (NSInteger i = 0; i < NUM_ROWS; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:previousOpenSectionIndex]];
        }
    }
    
    // Style the animation so that there's a smooth flow in either direction.
    UITableViewRowAnimation insertAnimation;
    UITableViewRowAnimation deleteAnimation;
    if (previousOpenSectionIndex == NSNotFound || sectionOpened < previousOpenSectionIndex) {
        insertAnimation = UITableViewRowAnimationTop;
        deleteAnimation = UITableViewRowAnimationBottom;
    }
    else {
        insertAnimation = UITableViewRowAnimationBottom;
        deleteAnimation = UITableViewRowAnimationTop;
    }
    
    // Apply the updates.
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:insertAnimation];
    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:deleteAnimation];
    [self.tableView endUpdates];
    self.openSectionIndex = sectionOpened;
    //select the first row in the section
    //[self.tableView selectRowAtIndexPath:[indexPathsToInsert objectAtIndex:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    //[self processRowSelectionAtIndexPath:[indexPathsToInsert objectAtIndex:0] closingSidebar:NO];
    
}


-(void)sectionHeaderView:(SidebarSectionHeaderView*)sectionHeaderView sectionClosed:(NSInteger)sectionClosed {
    
    SectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:sectionClosed - 1];
	
	sectionInfo.open = NO;
    
    NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < NUM_ROWS; i++) {
        [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:sectionClosed]];
    }
    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationTop];
    self.openSectionIndex = NSNotFound;
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

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSIndexPath *currentIndex = [self.tableView indexPathForSelectedRow];
    if (currentIndex) {
        selectedIndex = [[NSIndexPath indexPathForRow:currentIndex.row inSection:currentIndex.section] retain];
    }
    return indexPath;
}

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
    
    [self processRowSelectionAtIndexPath: indexPath];
}

- (void) processRowSelectionAtIndexPath: (NSIndexPath *) indexPath {
    [self processRowSelectionAtIndexPath:indexPath closingSidebar:YES];
}

- (void) processRowSelectionAtIndexPath: (NSIndexPath *) indexPath closingSidebar:(BOOL)closingSidebar {
    UIViewController *detailViewController = nil;  
    
    if (indexPath.section != 0) {
        Blog *blog = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:(indexPath.section - 1) inSection:0]];
        
        //did user select the same item, but for a different blog? If so then just update the data in the view controller.
        if (selectedIndex != nil) {
            if (indexPath.row == selectedIndex.row) {
                switch (indexPath.row) {
                    case 0:
                        [(PostsViewController*) self.panelNavigationController.detailViewController setBlog: blog];
                        break;
                    case 1:
                        [(PagesViewController*) self.panelNavigationController.detailViewController setBlog: blog];
                        break; 
                    case 2:
                        [(CommentsViewController*) self.panelNavigationController.detailViewController setBlog: blog];
                        break;
                    case 3:
                        [(StatsTableViewController*) self.panelNavigationController.detailViewController setBlog: blog];
                        break;
                }
            [self.panelNavigationController popToRootViewControllerAnimated:NO];
            if (!DeviceIsPad())
                [self.panelNavigationController closeSidebar];
            return;
            }
        }

        if (indexPath.row == 0) {
            PostsViewController *postsViewController = [[[PostsViewController alloc] init] autorelease];
            postsViewController.blog = blog;
            detailViewController = postsViewController;
        }
        if (indexPath.row == 1) {
            PagesViewController *pagesViewController = [[[PagesViewController alloc] init] autorelease];
            pagesViewController.blog = blog;
            detailViewController = pagesViewController;
        }
        if (indexPath.row == 2) {
            CommentsViewController *commentsViewController = [[[CommentsViewController alloc] init] autorelease];
            commentsViewController.blog = blog;
            detailViewController = commentsViewController;
        }
        if (indexPath.row == 3) {
            StatsTableViewController *statsTableViewController = [[[StatsTableViewController alloc] init] autorelease];
            statsTableViewController.blog = blog;
            detailViewController = statsTableViewController;
        }
    } else {
        if (indexPath.row == 1) {
            // Reader
            WPReaderViewController *readerViewController = [[[WPReaderViewController alloc] init] autorelease];
            detailViewController = readerViewController;
        }
    }

    if (detailViewController) {
        [self.panelNavigationController setDetailViewController:detailViewController closingSidebar:closingSidebar];
    }
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
