/*
 * BlogSelectorViewController.h
 *
 * Copyright (c) 2013 WordPress. All rights reserved.
 *
 * Licensed under GNU General Public License 2.0.
 * Some rights reserved. See license.txt
 */

#import "BlogSelectorViewController.h"
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
#import "WPTableViewSectionHeaderView.h"

static NSString *const BlogCellIdentifier = @"BlogCell";
static CGFloat const blavatarImageSize = 50.f;

@interface BlogSelectorViewController ()

@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic) BOOL sectionDeletedByController;

@property (nonatomic, strong) NSManagedObjectID *selectedObjectID;
@property (nonatomic, copy) void (^selectedCompletionHandler)(NSManagedObjectID *selectedObjectID, BOOL finished);
@property (nonatomic, copy) void (^cancelCompletionHandler)(void);

@end

@implementation BlogSelectorViewController

- (id)initWithSelectedBlogObjectID:(NSManagedObjectID *)objectID
                selectedCompletion:(void (^)(NSManagedObjectID *, BOOL))selected
                  cancelCompletion:(void (^)())cancel {
    self = [super initWithStyle:UITableViewStylePlain];
    
    if (self) {
        _selectedObjectID = objectID;
        _selectedCompletionHandler = selected;
        _cancelCompletionHandler = cancel;
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                      target:self
                                                                                      action:@selector(cancelButtonTapped:)];
    
    self.navigationItem.leftBarButtonItem = cancelButtonItem;
    
    UIBarButtonItem *selectButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Select", @"")
                                                                         style:UIBarButtonItemStylePlain
                                                                        target:self
                                                                        action:@selector(selectButtonTapped:)];
    
    self.navigationItem.rightBarButtonItem = selectButtonItem;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wordPressComApiDidLogin:) name:WordPressComApiDidLoginNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wordPressComApiDidLogout:) name:WordPressComApiDidLogoutNotification object:nil];

    // Remove one-pixel gap resulting from a top-aligned grouped table view
    if (IS_IPHONE) {
        UIEdgeInsets tableInset = [self.tableView contentInset];
        tableInset.top = -1;
        self.tableView.contentInset = tableInset;
    }
    
    [WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
 
    // If we're inside of a UIPopoverController, use a standard cell
    if (self.parentViewController && [self.parentViewController valueForKey:@"_popoverController"]) {
        [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:BlogCellIdentifier];
    } else {
        [self.tableView registerClass:[WPTableViewCell class] forCellReuseIdentifier:BlogCellIdentifier];
    }
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


#pragma mark - Notifications

- (void)wordPressComApiDidLogin:(NSNotification *)notification {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)wordPressComApiDidLogout:(NSNotification *)notification {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}


#pragma mark - Actions

- (IBAction)cancelButtonTapped:(id)sender {
    if (self.cancelCompletionHandler) {
        self.cancelCompletionHandler();
    }
}

- (IBAction)selectButtonTapped:(id)sender {
    if (self.selectedCompletionHandler) {
        self.selectedCompletionHandler(self.selectedObjectID, YES);
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.resultsController sections].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo;
    NSInteger numberOfRows = 0;
    if ([self.resultsController sections].count > section) {
        sectionInfo = [[self.resultsController sections] objectAtIndex:section];
        numberOfRows = sectionInfo.numberOfObjects;
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:BlogCellIdentifier];
    
    [WPStyleGuide configureTableViewCell:cell];
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (![self hasDotComAndSelfHosted]) {
        return nil;
    }
    return [[self.resultsController sectionIndexTitles] objectAtIndex:section];
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

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    
    Blog *blog = [self.resultsController objectAtIndexPath:indexPath];
    if ([blog.blogName length] != 0) {
        cell.textLabel.text = blog.blogName;
    } else {
        cell.textLabel.text = blog.url;
    }
    
    [cell.imageView setImageWithBlavatarUrl:blog.blavatarUrl isWPcom:blog.isWPcom];

    cell.accessoryType = blog.objectID == self.selectedObjectID ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 0)];
    header.title = [self tableView:self.tableView titleForHeaderInSection:section];
    if (IS_IPAD) {
        header.fixedWidth = WPTableViewFixedWidth;
    }
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *title = [self tableView:self.tableView titleForHeaderInSection:section];
    return [WPTableViewSectionHeaderView heightForTitle:title andWidth:CGRectGetWidth(self.view.bounds)];
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    // Use the standard dimension on the last section
    return section == [tableView numberOfSections] - 1 ? UITableViewAutomaticDimension : 0.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSIndexPath *previousIndexPath;
    if (self.selectedObjectID) {
        for (Blog *blog in self.resultsController.fetchedObjects) {
            if (blog.objectID == self.selectedObjectID) {
                previousIndexPath = [self.resultsController indexPathForObject:blog];
                break;
            }
        }
        
        if ([previousIndexPath compare:indexPath] == NSOrderedSame) {
            // Do nothing
            return;
        }
    }
    
    Blog *selectedBlog = [self.resultsController objectAtIndexPath:indexPath];
    self.selectedObjectID = selectedBlog.objectID;
    [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    
    if (previousIndexPath) {
        [tableView reloadRowsAtIndexPaths:@[previousIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    }

    if (self.selectedCompletionHandler) {
        self.selectedCompletionHandler(self.selectedObjectID, NO);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54;
}

#pragma mark - NSFetchedResultsController

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

    if (self.sectionDeletedByController) {
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
        self.sectionDeletedByController = NO;
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
            self.sectionDeletedByController = YES;
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
