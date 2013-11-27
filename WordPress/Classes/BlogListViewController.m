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
#import "WelcomeViewController.h"
#import "BlogDetailsViewController.h"
#import "WPTableViewCell.h"
#import "ContextManager.h"
#import "Blog.h"

CGFloat const blavatarImageSize = 50.f;

@interface BlogListViewController ()
@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) UIBarButtonItem *settingsButton;

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
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
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
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.resultsController.delegate = self;
    [self.resultsController performFetch:nil];
    [self.tableView reloadData];

    self.editButtonItem.enabled = ([self numSites] > 0);
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.resultsController.delegate = nil;
}

- (NSUInteger)numSites {
    return [[self.resultsController fetchedObjects] count];
}


#pragma mark - Actions

- (void)showSettings:(id)sender {
    [WPMobileStats incrementProperty:StatsPropertySidebarClickedSettings forEvent:StatsEventAppClosed];
    
    SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UINavigationController *aNavigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    aNavigationController.navigationBar.translucent = NO;
    if (IS_IPAD)
        aNavigationController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    aNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self.navigationController presentViewController:aNavigationController animated:YES completion:nil];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger numRows = [self numSites];
    
    // Plus an extra row for 'Add a Site' (when not editing)
    if (![tableView isEditing])
        numRows += 1;
    
    return numRows;
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

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return NSLocalizedString(@"Remove", @"Button label when removing a blog");
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.row != [self rowForAddSite];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    // And the "Add a Site" row too
    NSArray *rowsToChange = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:[self rowForAddSite] inSection:0]];
    
    UITableViewRowAnimation rowAnimation = animated ? UITableViewRowAnimationFade : UITableViewRowAnimationNone;
    [self.tableView beginUpdates];
    if (editing) {
        [self.tableView deleteRowsAtIndexPaths:rowsToChange withRowAnimation:rowAnimation];
        [self.navigationItem setRightBarButtonItem:nil animated:animated];
    } else {
        [self.tableView insertRowsAtIndexPaths:rowsToChange withRowAnimation:rowAnimation];
        [self.navigationItem setRightBarButtonItem:self.settingsButton animated:animated];
    }
    [self.tableView endUpdates];
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [WPMobileStats trackEventForWPCom:StatsEventSettingsRemovedBlog];
        
        Blog *blog = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
        [blog remove];
        
        // Count won't be updated yet; if this is the last site (count 1), exit editing mode
        if ([self numSites] == 1) {
            // Update the UI in the next run loop after the resultsController has updated
            // (otherwise row insertion/deletion logic won't work)
            dispatch_async(dispatch_get_main_queue(), ^{
                self.editButtonItem.enabled = NO;
                [self setEditing:NO animated:YES];
            });
        }
    }
}

- (NSInteger)rowForAddSite {
    return [self numSites];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    
    if (indexPath.row < [self rowForAddSite]) {
        Blog *blog = [self.resultsController objectAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:0]];
        if ([blog.blogName length] != 0) {
            cell.textLabel.text = blog.blogName;
        } else {
            cell.textLabel.text = blog.url;
        }
        
        [cell.imageView setImageWithBlavatarUrl:blog.blavatarUrl isWPcom:blog.isWPcom];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
//        if (indexPath.row == 0) {
//            [self maskImageView:cell.imageView corner:UIRectCornerTopLeft];
//        } else if (indexPath.row == ([self.tableView numberOfRowsInSection:indexPath.section] -1)) {
//            [self maskImageView:cell.imageView corner:UIRectCornerBottomLeft];
//        } else {
//            cell.imageView.layer.mask = NULL;
//        }
    } else {
        cell.textLabel.text = NSLocalizedString(@"Add a Site", @"");
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        // To align the label, create and add a blank image
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(blavatarImageSize, blavatarImageSize), NO, 0.0);
        UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [cell.imageView setImage:blank];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    // No top margin on iPhone
    if (IS_IPHONE)
        return 1;
    
    return 40;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row < [self rowForAddSite]) {
        [WPMobileStats trackEventForWPCom:StatsEventSettingsClickedEditBlog];
        
        Blog *blog = [self.resultsController objectAtIndexPath:indexPath];
        
        BlogDetailsViewController *blogDetailsViewController = [[BlogDetailsViewController alloc] init];
        blogDetailsViewController.blog = blog;
        [self.navigationController pushViewController:blogDetailsViewController animated:YES];
    } else {
        [WPMobileStats trackEventForWPCom:StatsEventSettingsClickedAddBlog];
        
        WelcomeViewController *welcomeViewController = [[WelcomeViewController alloc] initWithStyle:UITableViewStyleGrouped];
        welcomeViewController.title = NSLocalizedString(@"Add a Site", nil);
        [self.navigationController pushViewController:welcomeViewController animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54;
}


#pragma mark -
#pragma mark NSFetchedResultsController

- (NSFetchedResultsController *)resultsController {
    if (_resultsController) {
        return _resultsController;
    }
    
    NSManagedObjectContext *moc = [[ContextManager sharedInstance] mainContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Blog"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"blogName" ascending:YES]];
    
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
        DDLogError(@"Couldn't fetch blogs: %@", [error localizedDescription]);
        _resultsController = nil;
    }
    return _resultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:BlogChangedNotification object:nil];
}


@end
