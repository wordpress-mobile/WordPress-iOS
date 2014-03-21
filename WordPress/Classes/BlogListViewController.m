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
#import "WPBlogTableViewCell.h"
#import "ContextManager.h"
#import "Blog.h"
#import "WPAccount.h"
#import "WPTableViewSectionHeaderView.h"

static NSString *const AddSiteCellIdentifier = @"AddSiteCell";
static NSString *const BlogCellIdentifier = @"BlogCell";
CGFloat const blavatarImageSize = 50.f;
NSString * const WPBlogListRestorationID = @"WPBlogListID";

@interface BlogListViewController ()

@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) UIBarButtonItem *settingsButton;
@end

@implementation BlogListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        self.restorationIdentifier = WPBlogListRestorationID;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSString *)modelIdentifierForElementAtIndexPath:(NSIndexPath *)indexPath inView:(UIView *)view {
    if (!indexPath || !view)
        return nil;
    
    // Preserve objectID
    NSManagedObject *managedObject = [self.resultsController objectAtIndexPath:indexPath];
    return [[managedObject.objectID URIRepresentation] absoluteString];
}

- (NSIndexPath *)indexPathForElementWithModelIdentifier:(NSString *)identifier inView:(UIView *)view {
    if (!identifier || !view)
        return nil;

    // Map objectID back to indexPath
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    NSManagedObjectID *objectID = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:[NSURL URLWithString:identifier]];
    if (!objectID)
        return nil;
    
    NSError *error = nil;
    NSManagedObject *managedObject = [context existingObjectWithID:objectID error:&error];
    if (error || !managedObject) {
        return nil;
    }
    
    NSIndexPath *indexPath = [self.resultsController indexPathForObject:managedObject];
    
    return indexPath;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.settingsButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Settings", nil)
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(showSettings:)];
    self.navigationItem.rightBarButtonItem = self.settingsButton;

    // Remove one-pixel gap resulting from a top-aligned grouped table view
    if (IS_IPHONE) {
        UIEdgeInsets tableInset = [self.tableView contentInset];
        tableInset.top = -1;
        self.tableView.contentInset = tableInset;
    }
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];

    [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:AddSiteCellIdentifier];
    [self.tableView registerClass:[WPBlogTableViewCell class] forCellReuseIdentifier:BlogCellIdentifier];
    self.tableView.allowsSelectionDuringEditing = YES;
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    // Trigger the blog sync when loading the view, which should more or less be once when the app launches
    // We could do this on the app delegate, but the blogs list feels like a better place for it.
    [[WPAccount defaultWordPressComAccount] syncBlogsWithSuccess:nil failure:nil];

    // Remove extra separator lines
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
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

- (BOOL)shouldBypassBlogListViewControllerWhenSelectedFromTabBar
{
    return [self numSites] == 1;
}

- (void)bypassBlogListViewController
{
    if ([self shouldBypassBlogListViewControllerWhenSelectedFromTabBar]) {
        // We do a delay of 0.0 so that way this doesn't kick off until the next run loop.
        [self performSelector:@selector(selectFirstSite) withObject:nil afterDelay:0.0];
    }
}

- (void)selectFirstSite
{
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}


#pragma mark - Notifications

- (void)wordPressComApiDidLogin:(NSNotification *)notification {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)wordPressComApiDidLogout:(NSNotification *)notification {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
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
    return [self sectionForDotCom] >= 0? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    id<NSFetchedResultsSectionInfo> sectionInfo;
    NSInteger numberOfRows = 0;
    if ([self.resultsController sections].count > section) {
        sectionInfo = [[self.resultsController sections] objectAtIndex:section];
        numberOfRows = sectionInfo.numberOfObjects;
    }
    
    if (section == [self sectionForSelfHosted]) {
        // This is for the "Add a Site" row
        numberOfRows++;
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell;
    if ([indexPath isEqual:[self indexPathForAddSite]]) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:AddSiteCellIdentifier];
    } else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:BlogCellIdentifier];
    }

    [self configureCell:cell atIndexPath:indexPath];
    
    if ([indexPath isEqual:[self indexPathForAddSite]]) {
        [WPStyleGuide configureTableViewActionCell:cell];
    } else {
        [WPStyleGuide configureTableViewSmallSubtitleCell:cell];
    }

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (![self hasDotComAndSelfHosted]) {
        return nil;
    }
    return [[self.resultsController sectionIndexTitles] objectAtIndex:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NSLocalizedString(@"Remove", @"Button label when removing a blog");
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == [self sectionForSelfHosted] && ![indexPath isEqual:[self indexPathForAddSite]];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == [self sectionForSelfHosted] && tableView.editing) {
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
                [self setEditing:NO animated:NO];

                // No blogs and  signed out, show NUX
                if (![WPAccount defaultWordPressComAccount]) {
                    [[WordPressAppDelegate sharedWordPressApplicationDelegate] showWelcomeScreenIfNeededAnimated:YES];
                }
            });
        }
    }
}

- (NSInteger)sectionForDotCom {
    
    if ([self.resultsController sections].count > 0) {
        id<NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:0];
        if ([[sectionInfo name] isEqualToString:@"1"]) {
            return 0;
        }
    }
    
    return -1;
}

- (NSInteger)sectionForSelfHosted {
    
    if ([self sectionForDotCom] >= 0) {
        return 1;
    } else {
        return 0;
    }
}

- (NSIndexPath *)indexPathForAddSite {
    NSInteger section = [self sectionForSelfHosted];
    return [NSIndexPath indexPathForRow:([self.tableView numberOfRowsInSection:section] - 1) inSection:section];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    cell.imageView.image = nil;

    if ([indexPath isEqual:[self indexPathForAddSite]]) {
        cell.textLabel.text = NSLocalizedString(@"Add a Site", @"");
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    } else {

        Blog *blog = [self.resultsController objectAtIndexPath:indexPath];
        if ([blog.blogName length] != 0) {
            cell.textLabel.text = blog.blogName;
            cell.detailTextLabel.text = [blog displayURL];
        } else {
            cell.textLabel.text = [blog displayURL];
            cell.detailTextLabel.text = @"";
        }
        
        [cell.imageView setImageWithBlavatarUrl:blog.blavatarUrl isWPcom:blog.isWPcom];
        if ([self.tableView isEditing] && blog.isWPcom) {
            UISwitch *visibilitySwitch = [UISwitch new];
            visibilitySwitch.on = blog.visible;
            visibilitySwitch.tag = indexPath.row;
            [visibilitySwitch addTarget:self action:@selector(visibilitySwitchAction:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = visibilitySwitch;
            
            // Make textLabel light gray if blog is not-visible
            if (!visibilitySwitch.on) {
                [cell.textLabel setTextColor:[WPStyleGuide readGrey]];
            }
            
        } else {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        cell.selectionStyle = self.tableView.isEditing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleBlue;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    // The first section is the segmenter controller (A-Z / Z-A)
    if(section == 0) {

        UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 40)];
        [headerView setBackgroundColor:[[WPStyleGuide itsEverywhereGrey] colorWithAlphaComponent:0.4f]];

        NSArray *buttonNames = [NSArray arrayWithObjects:NSLocalizedString(@"A-Z", @"A-Z segment for reordering blogs)"), NSLocalizedString(@"Z-A", @"Z-A segment for reordering blogs)"), nil];
        UISegmentedControl* segmentedControl = [[UISegmentedControl alloc] initWithItems:buttonNames];
        [segmentedControl addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
        segmentedControl.frame = CGRectMake(0, 0, 150, 25);
        segmentedControl.center = CGPointMake(self.view.bounds.size.width/2, headerView.frame.size.height/2);

        NSUInteger selectedIndex = 0;
        if([[NSUserDefaults standardUserDefaults] objectForKey:@"blog_order_preference"] != nil)
            selectedIndex = [[[NSUserDefaults standardUserDefaults] objectForKey:@"blog_order_preference"] integerValue];

        segmentedControl.selectedSegmentIndex = selectedIndex;

        [headerView addSubview:segmentedControl];

        return headerView;
    }

    NSString *title = [self tableView:self.tableView titleForHeaderInSection:section];
    if (title.length > 0) {
        WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 0)];
        header.title = title;
        return header;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    //Height for the segmented controller (A-Z / Z-A)
    if(section == 0)
        return 40.;

    NSString *title = [self tableView:self.tableView titleForHeaderInSection:section];
    if (title.length > 0) {
        return [WPTableViewSectionHeaderView heightForTitle:title andWidth:CGRectGetWidth(self.view.bounds)];
    }
    return IS_IPHONE ? 1.0 : 40.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // Use the standard dimension on the last section
    return section == [tableView numberOfSections] - 1 ? UITableViewAutomaticDimension : 0.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([indexPath isEqual:[self indexPathForAddSite]]) {
        [self setEditing:NO animated:NO];
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
    } else if (self.tableView.isEditing) {
        return;
    }else {
        [WPMobileStats trackEventForWPCom:StatsEventSettingsClickedEditBlog];
        
        Blog *blog = [self.resultsController objectAtIndexPath:indexPath];
        [blog flagAsLastUsed];
        BlogDetailsViewController *blogDetailsViewController = [[BlogDetailsViewController alloc] init];
        blogDetailsViewController.blog = blog;
        [self.navigationController pushViewController:blogDetailsViewController animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    // Animate view to editing mode
    __block UIView *snapshot;
    if (animated) {
        snapshot = [self.view snapshotViewAfterScreenUpdates:NO];
        snapshot.frame = [self.view convertRect:self.view.frame fromView:self.view.superview];
        [self.view addSubview:snapshot];
    }
    
    // Update results controller to show hidden blogs
    [self updateFetchRequest];
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:^{
            snapshot.alpha = 0.0;
        } completion:^(BOOL finished) {
            [snapshot removeFromSuperview];
            snapshot = nil;
        }];
    }
}

- (void)visibilitySwitchAction:(id)sender {
    UISwitch *switcher = (UISwitch *)sender;
    Blog *blog = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:switcher.tag inSection:0]];
    if (switcher.on != blog.visible) {
        blog.visible = switcher.on;
        [blog dataSave];
    }
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)resultsController {
    if (_resultsController) {
        return _resultsController;
    }
    
    NSManagedObjectContext *moc = [[ContextManager sharedInstance] mainContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Blog"];
    [fetchRequest setSortDescriptors:[self fetchRequestSortDescriptor]];
    [fetchRequest setPredicate:[self fetchRequestPredicate]];
    
    _resultsController = [[NSFetchedResultsController alloc]
                          initWithFetchRequest:fetchRequest
                          managedObjectContext:moc
                          sectionNameKeyPath:@"isWPcom"
                          cacheName:nil];
    _resultsController.delegate = self;
    
    NSError *error = nil;
    if (![_resultsController performFetch:&error]) {
        DDLogError(@"Couldn't fetch sites: %@", [error localizedDescription]);
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

- (NSArray *) fetchRequestSortDescriptor {
    BOOL ascendingOrder = YES;
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"blog_order_preference"] != nil)
        ascendingOrder = [[[NSUserDefaults standardUserDefaults] objectForKey:@"blog_order_preference"] boolValue];
    return @[[NSSortDescriptor sortDescriptorWithKey:@"account.isWpcom" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"blogName" ascending:!ascendingOrder selector:@selector(localizedCaseInsensitiveCompare:)]];
}

- (void)updateFetchRequest {
    self.resultsController.fetchRequest.predicate = [self fetchRequestPredicate];
    self.resultsController.fetchRequest.sortDescriptors = [self fetchRequestSortDescriptor];
    
    NSError *error = nil;
    if (![self.resultsController performFetch:&error]) {
        DDLogError(@"Couldn't fetch sites: %@", [error localizedDescription]);
    }
    
    [self.tableView reloadData];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView reloadData];
}

- (NSString *)controller:(NSFetchedResultsController *)controller sectionIndexTitleForSectionName:(NSString *)sectionName {
    if ([sectionName isEqualToString:@"1"]) {
        return [NSString stringWithFormat:NSLocalizedString(@"%@'s sites", @"Section header for WordPress.com blogs"), [[WPAccount defaultWordPressComAccount] username]];
    }
    return NSLocalizedString(@"Self Hosted", @"Section header for self hosted blogs");
}

- (void) segmentAction:(UISegmentedControl*) sender {
    [WPMobileStats trackEventForWPCom:StatsEventSettingsClickedBlogsOrder];
    [[NSUserDefaults standardUserDefaults] setInteger:sender.selectedSegmentIndex forKey:@"blog_order_preference"];
    [self updateFetchRequest];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.tableView reloadData];
}
@end
