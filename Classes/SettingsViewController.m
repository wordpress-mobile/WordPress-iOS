//
//  SettingsViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 6/1/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

/*
 
 Settings contents:
 
 - Blogs list
    - Add blog
    - Edit/Delete
 - WordPress.com account
    - Sign out / Sign in
 - Media Settings
    - Image Resize
    - Video API
    - Video Quality
    - Video Content
 - Info
    - Version
    - About
    - Extra debug

 */

#import "SettingsViewController.h"
#import "WordPressAppDelegate.h"
#import "EditSiteViewController.h"
#import "WelcomeViewController.h"
#import "WPcomLoginViewController.h"
#import "UIImageView+Gravatar.h"
#import "WordPressComApi.h"

typedef enum {
    SettingsSectionBlogs = 0,
    SettingsSectionBlogsAdd,
    SettingsSectionWpcom,
//    SettingsSectionMedia,
//    SettingsSectionInfo,
    
    SettingsSectionCount
} SettingsSection;

@interface SettingsViewController () <NSFetchedResultsControllerDelegate,WPcomLoginViewControllerDelegate>
@property (readonly) NSFetchedResultsController *resultsController;
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)cellForIndexPath:(NSIndexPath *)indexPath;
- (void)checkCloseButton;
@end

@implementation SettingsViewController {
    NSFetchedResultsController *_resultsController;
}

- (void)dealloc
{
    [_resultsController release];

    [super dealloc];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Settings", @"App Settings");
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"") style:UIBarButtonItemStyleBordered target:self action:@selector(dismiss)] autorelease];
    [[NSNotificationCenter defaultCenter] addObserverForName:WordPressComApiDidLoginNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SettingsSectionWpcom] withRowAnimation:UITableViewRowAnimationFade];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:WordPressComApiDidLogoutNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SettingsSectionWpcom] withRowAnimation:UITableViewRowAnimationFade];
    }];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self checkCloseButton];
    self.editButtonItem.enabled = ([[self.resultsController fetchedObjects] count] > 0); // Disable if we have no blogs.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Custom methods

- (void)dismiss {
    [self dismissModalViewControllerAnimated:NO];
}

- (void)checkCloseButton {
    if ([[self.resultsController fetchedObjects] count] == 0 && [WordPressComApi sharedApi].username == nil) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SettingsSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case SettingsSectionBlogs:
            return [[self.resultsController fetchedObjects] count];
        case SettingsSectionBlogsAdd:
            return 1;
        case SettingsSectionWpcom:
            return [WordPressComApi sharedApi].username ? 2 : 1;
        default:
            return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SettingsSectionBlogs) {
        return NSLocalizedString(@"Remove", @"Button label when removing a blog");
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == SettingsSectionBlogs) {
        return NSLocalizedString(@"Blogs", @"");
    } else if (section == SettingsSectionWpcom) {
        return NSLocalizedString(@"WordPress.com", @"");
    }
    return nil;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    if (indexPath.section == SettingsSectionBlogs) {
        Blog *blog = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
        cell.textLabel.text = blog.blogName;
        cell.detailTextLabel.text = blog.hostURL;
        [cell.imageView setImageWithBlavatarUrl:blog.blavatarUrl isWPcom:blog.isWPcom];
    } else if (indexPath.section == SettingsSectionBlogsAdd) {
        cell.textLabel.text = NSLocalizedString(@"Add a blog", @"");
        cell.textLabel.textAlignment = UITextAlignmentCenter;
    } else if (indexPath.section == SettingsSectionWpcom) {
        if ([WordPressComApi sharedApi].username) {
            if (indexPath.row == 0) {
                cell.textLabel.text = NSLocalizedString(@"Username:", @"");
                cell.detailTextLabel.text = [WordPressComApi sharedApi].username;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            } else {
                cell.textLabel.textAlignment = UITextAlignmentCenter;
                cell.textLabel.text = NSLocalizedString(@"Sign out", @"Sign out from WordPress.com");
            }
        } else {
            cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.textLabel.text = NSLocalizedString(@"Sign in", @"Sign into WordPress.com");
        }
    }
}

- (UITableViewCell *)cellForIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"Cell";
    UITableViewCellStyle cellStyle = UITableViewCellStyleDefault;
    
    switch (indexPath.section) {
        case SettingsSectionBlogs:
            cellIdentifier = @"BlogCell";
            cellStyle = UITableViewCellStyleSubtitle;
            break;
        case SettingsSectionWpcom:
            cellIdentifier = @"WpcomCell";
            cellStyle = UITableViewCellStyleValue1;
    }
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:cellIdentifier] autorelease];
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self cellForIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return (indexPath.section == SettingsSectionBlogs);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Blog *blog = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
        [blog remove];
        
        if([[self.resultsController fetchedObjects] count] == 0) {
            [self setEditing:NO];
            self.editButtonItem.enabled = NO;
        }
    }   
}

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
    if (indexPath.section == SettingsSectionBlogs) {
        Blog *blog = [self.resultsController objectAtIndexPath:indexPath];

		EditSiteViewController *editSiteViewController = [[[EditSiteViewController alloc] init] autorelease];
        editSiteViewController.blog = blog;
        [self.navigationController pushViewController:editSiteViewController animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if (indexPath.section == SettingsSectionBlogsAdd) {
        WelcomeViewController *welcomeViewController;
        if (IS_IPAD) {
            welcomeViewController = [[[WelcomeViewController alloc] initWithNibName:@"WelcomeViewController-iPad" bundle:nil] autorelease];
        } else {
            welcomeViewController = [[[WelcomeViewController alloc] init] autorelease];
        }
        [self.navigationController pushViewController:welcomeViewController animated:YES];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    } else if (indexPath.section == SettingsSectionWpcom) {
        if ([WordPressComApi sharedApi].username) {
            if (indexPath.row == 1) {
                // Sign out
                [[WordPressComApi sharedApi] signOut];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SettingsSectionWpcom] withRowAnimation:UITableViewRowAnimationFade];
                [self checkCloseButton];
            }
        } else {
            WPcomLoginViewController *loginViewController = [[WPcomLoginViewController alloc] initWithStyle:UITableViewStyleGrouped];
            loginViewController.delegate = self;
            [self.navigationController pushViewController:loginViewController animated:YES];
        }
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)resultsController {
    if (_resultsController) {
        return _resultsController;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *moc = [[WordPressAppDelegate sharedWordPressApp] managedObjectContext];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:moc]];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"blogName" ascending:YES]]];
    
    // For some reasons, the cache sometimes gets corrupted
    // Since we don't really use sections we skip the cache here
    _resultsController = [[NSFetchedResultsController alloc]
                                                      initWithFetchRequest:fetchRequest
                                                      managedObjectContext:moc
                                                      sectionNameKeyPath:nil
                                                      cacheName:nil];
    _resultsController.delegate = self;

    NSError *error = nil;
    if (![_resultsController performFetch:&error]) {
        WPFLog(@"Couldn't fetch blogs: %@", [error localizedDescription]);
        [_resultsController release];
        _resultsController = nil;
    }
    [fetchRequest release];
    return _resultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
    [self checkCloseButton];
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
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[self.tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray
                                                    arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray
                                                    arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

#pragma mark - WPComLoginViewControllerDelegate

- (void)loginController:(WPcomLoginViewController *)loginController didAuthenticateWithUsername:(NSString *)username {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SettingsSectionWpcom] withRowAnimation:UITableViewRowAnimationFade];
    [self.navigationController popToRootViewControllerAnimated:YES];
    [self checkCloseButton];
}

- (void)loginControllerDidDismiss:(WPcomLoginViewController *)loginController {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
