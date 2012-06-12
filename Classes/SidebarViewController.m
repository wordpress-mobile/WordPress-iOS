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
#import "SidebarTableViewCell.h"
#import "SectionInfo.h"
#import "PostsViewController.h"
#import "PagesViewController.h"
#import "CommentsViewController.h"
#import "StatsTableViewController.h"
#import "WPReaderViewController.h"
#import "WPTableViewController.h"
#import "SettingsViewController.h"
#import "StatsWebViewController.h"
#import "PanelNavigationConstants.h"
#import "WPWebViewController.h"
#import "WordPressComApi.h"
#import "WelcomeViewController.h"

// Height for reader/notification/blog cells
#define SIDEBAR_CELL_HEIGHT 51.0f
// Height for secondary cells (posts/pages/comments/... inside a blog)
#define SIDEBAR_CELL_SECONDARY_HEIGHT 38.0f
#define SIDEBAR_BGCOLOR [UIColor colorWithWhite:0.921875f alpha:1.0f];
#define HEADER_HEIGHT 47
#define DEFAULT_ROW_HEIGHT 48
#define NUM_ROWS 5

@interface SidebarViewController () <NSFetchedResultsControllerDelegate>
@property (nonatomic, retain) NSFetchedResultsController *resultsController;
@property (nonatomic, assign) SectionInfo *openSection;
@property (nonatomic, strong) NSMutableArray *sectionInfoArray;
@property (readonly) NSInteger topSectionRowCount;
- (SectionInfo *)sectionInfoForBlog:(Blog *)blog;
- (void)addSectionInfoForBlog:(Blog *)blog;
- (void)insertSectionInfoForBlog:(Blog *)blog atIndex:(NSUInteger)index;
- (void)showWelcomeScreenIfNeeded;
- (void)selectFirstAvailableItem;
@end

@implementation SidebarViewController
@synthesize resultsController = _resultsController, openSection=_openSection, sectionInfoArray=_sectionInfoArray;
@synthesize tableView, footerButton;

- (void)dealloc {
    self.resultsController.delegate = nil;
    self.resultsController = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.view.backgroundColor = SIDEBAR_BGCOLOR;
    self.openSection = nil;
    
    // create the sectionInfoArray, stores data for collapsing/expanding sections in the tableView
	if (self.sectionInfoArray == nil) {
        self.sectionInfoArray = [[NSMutableArray alloc] initWithCapacity:[[self.resultsController fetchedObjects] count]];
        // For each play, set up a corresponding SectionInfo object to contain the default height for each row.
		for (Blog *blog in [self.resultsController fetchedObjects]) {
            [self addSectionInfoForBlog:blog];
		}
	}
    
    void (^wpcomNotificationBlock)(NSNotification *) = ^(NSNotification *note) {
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        if (selectedIndexPath == nil || (selectedIndexPath.section == 0 && selectedIndexPath.row == 1)) {
            [self selectFirstAvailableItem];
        }
    };
    [[NSNotificationCenter defaultCenter] addObserverForName:WordPressComApiDidLoginNotification object:nil queue:nil usingBlock:wpcomNotificationBlock];
    [[NSNotificationCenter defaultCenter] addObserverForName:WordPressComApiDidLogoutNotification object:nil queue:nil usingBlock:wpcomNotificationBlock];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [tableView release];
    [footerButton release];
    
    self.sectionInfoArray = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated]; 	
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated]; 
    [self showWelcomeScreenIfNeeded];
    [self selectFirstAvailableItem];    
}

#pragma mark - Custom methods

- (NSInteger)topSectionRowCount {
    if ([WordPressComApi sharedApi].username) {
        return 2;
    } else {
        return 1;
    }
}

- (SectionInfo *)sectionInfoForBlog:(Blog *)blog {
    SectionInfo *sectionInfo = [[SectionInfo alloc] init];			
    sectionInfo.blog = blog;
    sectionInfo.open = NO;

    NSNumber *defaultRowHeight = [NSNumber numberWithInteger:DEFAULT_ROW_HEIGHT];
    for (NSInteger i = 0; i < NUM_ROWS; i++) {
        [sectionInfo insertObject:defaultRowHeight inRowHeightsAtIndex:i];
    }

    return sectionInfo;
}

- (void)addSectionInfoForBlog:(Blog *)blog {    
    [self.sectionInfoArray addObject:[self sectionInfoForBlog:blog]];
}

- (void)insertSectionInfoForBlog:(Blog *)blog atIndex:(NSUInteger)index {
    [self.sectionInfoArray insertObject:[self sectionInfoForBlog:blog] atIndex:index];
}

- (void)showWelcomeScreenIfNeeded {
     WPFLogMethod();
    if ( [[self.resultsController fetchedObjects] count] == 0 ) {
        //ohh poor boy, no blogs yet?
        if ( ! [WordPressComApi sharedApi].username ) {
            //ohh auch! no .COM account? 
            WelcomeViewController *welcomeViewController = nil;
            
            if ( IS_IPAD ) {
                welcomeViewController = [[WelcomeViewController alloc] initWithNibName:@"WelcomeViewController-iPad" bundle:nil];
            } else {
                welcomeViewController = [[WelcomeViewController alloc] initWithNibName:@"WelcomeViewController" bundle:[NSBundle mainBundle]];
            }
            
            [welcomeViewController automaticallyDismissOnLoginActions];
            
            UINavigationController *aNavigationController = [[[UINavigationController alloc] initWithRootViewController:welcomeViewController] autorelease];
            aNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            aNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;

            [self.panelNavigationController presentModalViewController:aNavigationController animated:YES];
            [welcomeViewController release];
        }
    }
}

- (void)selectFirstAvailableItem {
    if ([self.tableView numberOfRowsInSection:0] > 1) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
        [self processRowSelectionAtIndexPath:indexPath];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    } else if ([self.sectionInfoArray count] > 0) {
        SectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:0];
        if (!sectionInfo.open) {
            [sectionInfo.headerView toggleOpenWithUserAction:YES];
        }
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
        [self processRowSelectionAtIndexPath:indexPath closingSidebar:NO];
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
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
        sectionInfo.headerView = [[SidebarSectionHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, SIDEBAR_WIDTH, HEADER_HEIGHT) blog:blog sectionInfo:sectionInfo delegate:self];
    }
    
    return sectionInfo.headerView;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SideBarCell";
    SidebarTableViewCell *cell = (SidebarTableViewCell *) [aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[SidebarTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
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
                Blog *blog = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:(indexPath.section - 1) inSection:0]];
                cell.blog = blog;
                break;
            case 3:
                title = NSLocalizedString(@"Stats", @"");
                break;
            case 4:
                title = NSLocalizedString(@"Dashboard", @"Button to load the dashboard in a web view");
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

-(void)sectionHeaderView:(SidebarSectionHeaderView*)sectionHeaderView sectionOpened:(SectionInfo *)sectionOpened {    
	sectionOpened.open = YES;
    NSUInteger sectionNumber = [self.sectionInfoArray indexOfObject:sectionOpened] + 1;
    
    /*
     Create an array containing the index paths of the rows to insert: These correspond to the rows for each quotation in the current section.
     */
    NSMutableArray *indexPathsToInsert = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < NUM_ROWS; i++) {
        [indexPathsToInsert addObject:[NSIndexPath indexPathForRow:i inSection:sectionNumber]];
    }
    
    /*
     Create an array containing the index paths of the rows to delete: These correspond to the rows for each quotation in the previously-open section, if there was one.
     */
    NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
    
    SectionInfo *previousOpenSection = self.openSection;
    NSUInteger previousOpenSectionIndex = NSNotFound;
    if (previousOpenSection) {
        previousOpenSection.open = NO;
        [previousOpenSection.headerView toggleOpenWithUserAction:NO];
        previousOpenSectionIndex = [self.sectionInfoArray indexOfObject:previousOpenSection] + 1;
        for (NSInteger i = 0; i < NUM_ROWS; i++) {
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:previousOpenSectionIndex]];
        }
    }
    
    // Style the animation so that there's a smooth flow in either direction.
    UITableViewRowAnimation insertAnimation;
    UITableViewRowAnimation deleteAnimation;
    if (previousOpenSectionIndex == NSNotFound || sectionNumber < previousOpenSectionIndex) {
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
    self.openSection = sectionOpened;
    // select the first row in the section
    // if we don't, a) you lose the current selection, b) the sidebar doesn't open on iPad
    [self.tableView selectRowAtIndexPath:[indexPathsToInsert objectAtIndex:0] animated:NO scrollPosition:UITableViewScrollPositionNone];    
    [self processRowSelectionAtIndexPath:[indexPathsToInsert objectAtIndex:0] closingSidebar:NO];
}


-(void)sectionHeaderView:(SidebarSectionHeaderView*)sectionHeaderView sectionClosed:(SectionInfo *)sectionClosed {    
    NSUInteger sectionNumber = [self.sectionInfoArray indexOfObject:sectionClosed] + 1;
	sectionClosed.open = NO;

    NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < NUM_ROWS; i++) {
        [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:sectionNumber]];
    }
    [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationTop];
    self.openSection = nil;
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
    
    [self processRowSelectionAtIndexPath: indexPath];
}

- (IBAction)showSettings:(id)sender {
    SettingsViewController *settingsViewController = [[[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
    UINavigationController *aNavigationController = [[[UINavigationController alloc] initWithRootViewController:settingsViewController] autorelease];
    aNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    aNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;

    [self.panelNavigationController presentModalViewController:aNavigationController animated:YES];
}

- (void) processRowSelectionAtIndexPath: (NSIndexPath *) indexPath {
    [self processRowSelectionAtIndexPath:indexPath closingSidebar:YES];
}

- (void) processRowSelectionAtIndexPath: (NSIndexPath *) indexPath closingSidebar:(BOOL)closingSidebar {
    UIViewController *detailViewController = nil;  
    if (indexPath.section == 0) { //Reader, QuickPhoto
        if (indexPath.row == 1) {
            if ([self.panelNavigationController.detailViewController isMemberOfClass:[WPReaderViewController class]]) {
                // Reader was already selected
                if (IS_IPAD) {
                    [self.panelNavigationController showSidebar];
                } else {
                    [self.panelNavigationController popToRootViewControllerAnimated:NO];
                    [self.panelNavigationController closeSidebar];
                }
                return;
            }
            // Reader
            WPReaderViewController *readerViewController = [[[WPReaderViewController alloc] init] autorelease];
            detailViewController = readerViewController;
        }
    } else {
        Blog *blog = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:(indexPath.section - 1) inSection:0]];

        Class controllerClass = nil;
        //did user select the same item, but for a different blog? If so then just update the data in the view controller.
        switch (indexPath.row) {
            case 0:
                 controllerClass = [PostsViewController class];
                break;
            case 1:
                controllerClass = [PagesViewController class];
                break;
            case 2:
                controllerClass = [CommentsViewController class];
                break;
            case 3:
                controllerClass =  IS_IPAD ? [StatsWebViewController class] : [StatsTableViewController class];
                break;
            case 4:
                controllerClass = [WPWebViewController class];
                //dashboard already selected
                if ([self.panelNavigationController.detailViewController isMemberOfClass:[WPWebViewController class]]) {
                    if (IS_IPAD) {
                        [self.panelNavigationController showSidebar];
                    } else {
                        [self.panelNavigationController popToRootViewControllerAnimated:NO];
                        [self.panelNavigationController closeSidebar];
                    }
                } else {
                    
                    WPWebViewController *webViewController;
                    if ( IS_IPAD ) {
                        webViewController = [[[WPWebViewController alloc] initWithNibName:@"WPWebViewController-iPad" bundle:nil] autorelease];
                    }
                    else {
                        webViewController = [[[WPWebViewController alloc] initWithNibName:@"WPWebViewController" bundle:nil] autorelease];
                    }
                    NSString *dashboardUrl = [blog.xmlrpc stringByReplacingOccurrencesOfString:@"xmlrpc.php" withString:@"wp-admin/"];
                    [webViewController setUrl:[NSURL URLWithString:dashboardUrl]];
                    
                    [webViewController setUsername:blog.username];
                    [webViewController setPassword:[blog fetchPassword]];
                    [webViewController setWpLoginURL:[NSURL URLWithString:blog.loginURL]];
                    [self.panelNavigationController setDetailViewController:webViewController closingSidebar:closingSidebar];
                }                
                return;
            default:
                controllerClass = [PostsViewController class];
                break;
        }
        
        //Check if the controller is already on the screen
        if ([self.panelNavigationController.detailViewController isMemberOfClass:controllerClass] && [self.panelNavigationController.detailViewController respondsToSelector:@selector(setBlog:)]) {
            [self.panelNavigationController.detailViewController performSelector:@selector(setBlog:) withObject:blog];
            if (IS_IPAD) {
                [self.panelNavigationController showSidebar];
            } else {
                [self.panelNavigationController popToRootViewControllerAnimated:NO];
                if ( closingSidebar )
                    [self.panelNavigationController closeSidebar];
            }
            return;
        } else {
            detailViewController = (UIViewController *)[[[controllerClass alloc] init] autorelease];
            if ([detailViewController respondsToSelector:@selector(setBlog:)]) {
                [detailViewController performSelector:@selector(setBlog:) withObject:blog];
            }
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

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
    if ([self.tableView indexPathForSelectedRow] == nil) {
        [self selectFirstAvailableItem];
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    if (NSFetchedResultsChangeUpdate == type && newIndexPath != nil) {
        // Seriously, Apple?
        // http://developer.apple.com/library/ios/#releasenotes/iPhone/NSFetchedResultsChangeMoveReportedAsNSFetchedResultsChangeUpdate/_index.html
        type = NSFetchedResultsChangeMove;
    }
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            NSLog(@"Inserting row %d: %@", newIndexPath.row, anObject);
            [self insertSectionInfoForBlog:anObject atIndex:newIndexPath.row];
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:newIndexPath.row + 1] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            NSLog(@"Deleting row %d: %@", indexPath.row, anObject);
            SectionInfo *sectionInfo = [self.sectionInfoArray objectAtIndex:indexPath.row];
            if (sectionInfo.open) {
                NSMutableArray *indexPathsToDelete = [[NSMutableArray alloc] init];                
                for (NSInteger i = 0; i < NUM_ROWS; i++) {
                    [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:i inSection:indexPath.row + 1]];
                }
                [self.tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationFade];
                [indexPathsToDelete release];
            }
            if (self.openSection == sectionInfo) {
                self.openSection = nil;
            }
            [self.sectionInfoArray removeObjectAtIndex:indexPath.row];
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.row + 1] withRowAnimation:UITableViewRowAnimationFade];
            [self showWelcomeScreenIfNeeded];
            break;
    }
}

@end
