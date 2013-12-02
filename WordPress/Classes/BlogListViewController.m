//
//  BlogListViewController.m
//  WordPress
//
//  Created by Michael Johnston on 11/8/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "BlogListViewController.h"
#import "WordPressAppDelegate.h"
#import "UIImageView+Gravatar.h"
#import "WordPressComApi.h"
#import "SettingsViewController.h"
#import "LoginViewController.h"
#import "BlogDetailsViewController.h"
#import "WPTableViewCell.h"
#import "ContextManager.h"
#import "Blog.h"
#import "WPAccount.h"

CGFloat const blavatarImageSize = 50.f;

@interface BlogListViewController ()
@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) UIBarButtonItem *settingsButton;
@property (nonatomic) BOOL controllerDidDeleteSection;
@end

@implementation BlogListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.settingsButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", nil)
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(showSettings:)];
    self.navigationItem.rightBarButtonItem = self.settingsButton;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:WordPressComApiDidLoginNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:WordPressComApiDidLogoutNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    }];

    // Remove one-pixel gap resulting from a top-aligned grouped table view
    if (IS_IPHONE) {
        UIEdgeInsets tableInset = [self.tableView contentInset];
        tableInset.top = -1;
        self.tableView.contentInset = tableInset;
    }
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
 
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:animated];
    self.resultsController.delegate = self;
    [self.resultsController performFetch:nil];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.resultsController.delegate = nil;
}

- (NSUInteger)numSites {
    return [[self.resultsController fetchedObjects] count];
}

- (BOOL)hasDotComAndSelfHosted {
    return ([[self.resultsController sections] count] > 1);
}

#pragma mark - Actions

- (void)showSettings:(id)sender {
    [WPMobileStats incrementProperty:StatsPropertySidebarClickedSettings forEvent:StatsEventAppClosed];
    
    SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    aNavigationController.navigationBar.translucent = NO;
    aNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self.navigationController presentViewController:aNavigationController animated:YES completion:nil];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.resultsController.sections count] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == [self sectionForAddSite]) {
        return tableView.isEditing ? 0 : 1;
    }
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return sectionInfo.numberOfObjects;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"BlogCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[WPTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    [WPStyleGuide configureTableViewCell:cell];
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (![self hasDotComAndSelfHosted]) {
        return nil;
    }

    if (section < [self sectionForAddSite]) {
        return [[self.resultsController sectionIndexTitles] objectAtIndex:section];
    }

    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NSLocalizedString(@"Remove", @"Button label when removing a blog");
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == [self sectionForSelfHosted]) {
        return YES;
    } else {
        return NO;
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == [self sectionForSelfHosted] && tableView.editing   ) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [WPMobileStats trackEventForWPCom:StatsEventSettingsRemovedBlog];
        
        Blog *blog = [self.resultsController objectAtIndexPath:indexPath];
        if (blog.isWPcom) {
            DDLogWarn(@"Tried to remove a WordPress.com blog. This shouldn't happen but just in case, let's hide it");
            blog.visible = NO;
            [blog dataSave];
        } else {
            [blog remove];
        }
        
        // Count won't be updated yet; if this is the last site (count 1), exit editing mode
        if ([self numSites] == 1) {
            // Update the UI in the next run loop after the resultsController has updated
            // (otherwise row insertion/deletion logic won't work)
            dispatch_async(dispatch_get_main_queue(), ^{
                self.editButtonItem.enabled = NO;
                [self setEditing:NO animated:YES];

                // No blogs and  signed out, show NUX
                if (![WPAccount defaultWordPressComAccount]) {
                    [[WordPressAppDelegate sharedWordPressApplicationDelegate] showWelcomeScreenIfNeededAnimated:YES];
                }
            });
        }
    }
}

- (NSInteger)sectionForAddSite {
    return [self.resultsController.sections count];
}

- (NSInteger)sectionForDotCom {
    
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:0];
    if ([[sectionInfo name] isEqualToString:@"1"]) {
        return 0;
    } else {
        return -1;
    }
}

- (NSInteger)sectionForSelfHosted {
    
    NSInteger sectionsCount = [self.resultsController sections].count;
    if (sectionsCount > 1) {
        return 1;
    } else if (sectionsCount > 0 && [[[[self.resultsController sections] objectAtIndex:0] name] isEqualToString:@"0"]) {
        return 0;
    } else {
        return -1;
    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    
    if (indexPath.section == [self sectionForAddSite]) {
        cell.textLabel.text = NSLocalizedString(@"Add a Site", @"");
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

        // To align the label, create and add a blank image
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(blavatarImageSize, blavatarImageSize), NO, 0.0);
        UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [cell.imageView setImage:blank];
    } else {

        Blog *blog = [self.resultsController objectAtIndexPath:indexPath];
        if ([blog.blogName length] != 0) {
            cell.textLabel.text = blog.blogName;
        } else {
            cell.textLabel.text = blog.url;
        }
        
        [cell.imageView setImageWithBlavatarUrl:blog.blavatarUrl isWPcom:blog.isWPcom];
        if ([self.tableView isEditing] && blog.isWPcom) {
            UISwitch *visibilitySwitch = [UISwitch new];
            visibilitySwitch.on = blog.visible;
            visibilitySwitch.tag = indexPath.row;
            [visibilitySwitch addTarget:self action:@selector(switchDidChange:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = visibilitySwitch;
            
            // Make textLabel light gray if blog is not-visible
            if (!visibilitySwitch.on) {
                [cell.textLabel setTextColor:[WPStyleGuide readGrey]];
            }
            
        } else {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    // No top margin on iPhone
    if ([self hasDotComAndSelfHosted]) {
        return 40.0;
    } else {
        return 20.0;
    }
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == [self sectionForAddSite]) {
        return UITableViewAutomaticDimension;
    } else {
        return 1.0;        
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section < [self sectionForAddSite]) {
        [WPMobileStats trackEventForWPCom:StatsEventSettingsClickedEditBlog];
        
        Blog *blog = [self.resultsController objectAtIndexPath:indexPath];
        
        BlogDetailsViewController *blogDetailsViewController = [[BlogDetailsViewController alloc] init];
        blogDetailsViewController.blog = blog;
        [self.navigationController pushViewController:blogDetailsViewController animated:YES];
    } else {
        [WPMobileStats trackEventForWPCom:StatsEventSettingsClickedAddBlog];

        LoginViewController *loginViewController = [[LoginViewController alloc] init];
        if (![WPAccount defaultWordPressComAccount]) {
            
            loginViewController.prefersSelfHosted = YES;
        }
        loginViewController.dismissBlock = ^{
            [self dismissViewControllerAnimated:YES completion:nil];
        };
        UINavigationController *loginNavigationController = [[UINavigationController alloc] initWithRootViewController:loginViewController];
        [self presentViewController:loginNavigationController animated:YES completion:nil];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    [self updateFetchRequest];
}

- (void)switchDidChange:(id)sender {

    UISwitch *switcher = (UISwitch *)sender;
    Blog *blog = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:switcher.tag inSection:0]];
    if (switcher.on != blog.visible) {
        blog.visible = switcher.on;
        [blog dataSave];
    }
}

#pragma mark -
#pragma mark NSFetchedResultsController

- (NSFetchedResultsController *)resultsController {
    if (_resultsController) {
        return _resultsController;
    }
    
    NSManagedObjectContext *moc = [[ContextManager sharedInstance] mainContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Blog"];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"account.isWpcom" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"blogName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
    [fetchRequest setPredicate:[self fetchRequestPredicate]];
    
    _resultsController = [[NSFetchedResultsController alloc]
                          initWithFetchRequest:fetchRequest
                          managedObjectContext:moc
                          sectionNameKeyPath:@"isWPcom"
                          cacheName:nil];
    _resultsController.delegate = self;
    
    NSError *error = nil;
    if (![_resultsController performFetch:&error]) {
        DDLogError(@"Couldn't fetch blogs: %@", [error localizedDescription]);
        _resultsController = nil;
    }
    return _resultsController;
}

- (NSPredicate *)fetchRequestPredicate {
    if ([self.tableView isEditing]) {
        return nil;
    } else {
        return [NSPredicate predicateWithFormat:@"visible = YES"];
    }
}

- (void)updateFetchRequest {
    self.resultsController.fetchRequest.predicate = [self fetchRequestPredicate];
    
    NSError *error = nil;
    if (![self.resultsController performFetch:&error]) {
        DDLogError(@"Couldn't fetch blogs: %@", [error localizedDescription]);
    }
    
    [self.tableView reloadData];
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];

    if (self.controllerDidDeleteSection) {
        /*
         This covers the corner case when the only self hosted blog is removed and
         there's a WordPress.com account.
         
         Since we only show the section title if there are multiple blog sections,
         the section header wouldn't change when the section count changed, and it
         would still display the wordpress.com header.
         
         It's not a big deal but it wouldn't be consistent with future appearances
         of the same view.
         */
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
        self.controllerDidDeleteSection = NO;
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

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            self.controllerDidDeleteSection = YES;
            break;

        default:
            break;
    }
}

- (NSString *)controller:(NSFetchedResultsController *)controller sectionIndexTitleForSectionName:(NSString *)sectionName {
    if ([sectionName isEqualToString:@"1"]) {
        return [NSString stringWithFormat:NSLocalizedString(@"%@'s blogs", @"Section header for WordPress.com blogs"), [[WPAccount defaultWordPressComAccount] username]];
    }
    return NSLocalizedString(@"Self Hosted", @"Section header for self hosted blogs");
}

@end
