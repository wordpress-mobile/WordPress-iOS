//
//  NewSidebarMenuViewController.m
//  WordPress
//
//  Created by Sendhil Panchadsaram on 8/12/13.
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import "NewSidebarMenuViewController.h"
#import "SidebarTopLevelView.h"
#import "NewSidebarCell.h"
#import "WordPressAppDelegate.h"
#import "WordPressComApi.h"

@interface NewSidebarMenuViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;

@end

@implementation NewSidebarMenuViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    self.resultsController.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor UIColorFromHex:0x2a2a2a];
    self.tableView.backgroundColor = [UIColor UIColorFromHex:0x2a2a2a];
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 100)];
    footerView.backgroundColor = [UIColor clearColor];
    self.tableView.tableFooterView = footerView;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (NSFetchedResultsController *)resultsController {
    if (_resultsController != nil) return _resultsController;
    
    NSManagedObjectContext *moc = [[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:moc]];
    [fetchRequest setPropertiesToFetch:@[@"blogName", @"xmlrpc", @"url"]];
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
    
    
    NSError *error = nil;
    if (![_resultsController performFetch:&error]) {
        WPFLog(@"Couldn't fecth blogs: %@", [error localizedDescription]);
        _resultsController = nil;
    }
    
    return _resultsController;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // TODO : Update for not .com
    return [[self.resultsController fetchedObjects] count] + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self isLastSection:section])
        return 30.0;
    else
        return 44.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([self isLastSection:section]) {
        UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), 30.0)];
        spacerView.backgroundColor = [UIColor clearColor];
        return spacerView;
    }
    
    SidebarTopLevelView *headerView = [[SidebarTopLevelView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 44)];
    Blog *blog = [[self.resultsController fetchedObjects] objectAtIndex:section];
    headerView.blogTitle = blog.blogName;
    headerView.blavatarUrl = blog.blavatarUrl;
    return headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ([self isLastSection:section])
        return 3;
    else
        return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isLastSection:indexPath.section]) {
        static NSString *CellIdentifier = @"OtherCell";
        NewSidebarCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[NewSidebarCell alloc] init];
        }
        
        NSUInteger row = indexPath.row;
        NSString *text;
        UIImage *image;
        UIImage *selectedImage;
        if (row == 0) {
            text = @"Settings";
            image = [UIImage imageNamed:@"icon-menu-settings"];
            selectedImage = [UIImage imageNamed:@"icon-menu-settings-active"];
        } else if (row == 1) {
            text = @"Reader";
            image = [UIImage imageNamed:@"icon-menu-reader"];
            selectedImage = [UIImage imageNamed:@"icon-menu-reader-active"];
        } else if (row == 2) {
            text = @"Notifications";
            image = [UIImage imageNamed:@"icon-menu-notifications"];
            selectedImage = [UIImage imageNamed:@"icon-menu-notifications-active"];
        }
        
        cell.cellBackgroundColor = SidebarTableViewCellBackgroundColorDark;
        cell.title = text;
        cell.mainImage = image;
        cell.selectedImage = selectedImage;
        
        return cell;
    } else {
        static NSString *CellIdentifier = @"Cell";
        NewSidebarCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[NewSidebarCell alloc] init];
        }
        
        cell.showsBadge = false;
        cell.firstAccessoryViewImage = nil;
        cell.secondAccessoryViewImage = nil;
        
        NSUInteger row = indexPath.row;
        NSString *text;
        UIImage *image;
        UIImage *selectedImage;
        if (row == 0) {
            text = @"Posts";
            image = [UIImage imageNamed:@"icon-menu-posts"];
            selectedImage = [UIImage imageNamed:@"icon-menu-posts-active"];
            cell.firstAccessoryViewImage = [UIImage imageNamed:@"icon-menu-posts-quickphoto"];
            cell.secondAccessoryViewImage = [UIImage imageNamed:@"icon-menu-posts-add"];
        } else if (row == 1) {
            text = @"Pages";
            image = [UIImage imageNamed:@"icon-menu-pages"];
            selectedImage = [UIImage imageNamed:@"icon-menu-pages-active"];
            cell.secondAccessoryViewImage = [UIImage imageNamed:@"icon-menu-posts-add"];
        } else if (row == 2) {
            text = @"Comments";
            image = [UIImage imageNamed:@"icon-menu-comments"];
            selectedImage = [UIImage imageNamed:@"icon-menu-pages-active"];
            cell.showsBadge = true;
            cell.badgeNumber = arc4random() % 100;
        } else if (row == 3) {
            text = @"Stats";
            image = [UIImage imageNamed:@"icon-menu-stats"];
            selectedImage = [UIImage imageNamed:@"icon-menu-stats-active"];
        } else if (row == 4) {
            text = @"View Site";
            image = [UIImage imageNamed:@"icon-menu-viewsite"];
            selectedImage = [UIImage imageNamed:@"icon-menu-viewsite-active"];
        }
        
        cell.cellBackgroundColor = SidebarTableViewCellBackgroundColorLight;
        cell.title = text;
        cell.mainImage = image;
        cell.selectedImage = selectedImage;
        
        return cell;
    }
}

- (BOOL)isLastSection:(NSUInteger)section
{
    return (section == [[self.resultsController fetchedObjects] count]);
}

@end
