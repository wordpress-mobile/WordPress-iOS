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

CGFloat const blavatarImageSize = 50.f;

@interface BlogListViewController ()
@property (nonatomic, strong) NSFetchedResultsController *resultsController;

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
    
    [[NSNotificationCenter defaultCenter] addObserverForName:WordPressComApiDidLoginNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:WordPressComApiDidLogoutNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    }];

    UIEdgeInsets tableInset = [self.tableView contentInset];
    tableInset.top = -1;
    self.tableView.contentInset = tableInset;
    
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
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.resultsController.delegate = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Number of blogs plus an extra row for 'Add a Site'
    return [[self.resultsController fetchedObjects] count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"BlogCell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    [WPStyleGuide configureTableViewCell:cell];
    [self configureCell:cell atIndexPath:indexPath];

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

- (NSInteger)rowForAddSite {
    return [[self.resultsController fetchedObjects] count];
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
    return 1;
}


#pragma mark -
#pragma mark NSFetchedResultsController

- (NSFetchedResultsController *)resultsController {
    if (_resultsController)
        return _resultsController;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSManagedObjectContext *moc = [[WordPressAppDelegate sharedWordPressApplicationDelegate] managedObjectContext];
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
}


@end
