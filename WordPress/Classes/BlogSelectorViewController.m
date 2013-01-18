//
//  BlogSelectorViewController.m
//  WordPress
//
//  Created by Jorge Bernal on 4/6/11.
//  Copyright 2011 WordPress. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BlogSelectorViewController.h"
#import "WordPressAppDelegate.h"
#import "BlogsTableViewCell.h"
#import "UIImageView+Gravatar.h"
#import "NSString+XMLExtensions.h" 

@interface BlogSelectorViewController (PrivateMethods)
- (NSFetchedResultsController *)resultsController;
@end

@implementation BlogSelectorViewController
@synthesize delegate;
@synthesize selectedBlog;

- (void)didReceiveMemoryWarning
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    NSError *error = nil;
    [[self resultsController] performFetch:&error];
    [super viewDidLoad];
    NSLog(@"Blog selector delegate: %@", self.tableView.delegate);
    NSLog(@"Blog selector dataSource: %@", self.tableView.dataSource);
}

- (void)viewDidUnload
{
    [FileLogger log:@"%@ %@", self, NSStringFromSelector(_cmd)];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [super shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[resultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = nil;
    sectionInfo = [[resultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 52.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"BlogCell";
    BlogsTableViewCell *cell = (BlogsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    Blog *blog = [resultsController objectAtIndexPath:indexPath];
    
    CGRect frame = CGRectMake(8,8,35,35);
    UIImageView* asyncImage = [[UIImageView alloc]
                                            initWithFrame:frame];
    
    if (cell == nil) {
        cell = [[BlogsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        [cell.imageView removeFromSuperview];
    }
    else {
        UIImageView* oldImage = (UIImageView*)[cell.contentView viewWithTag:999];
        [oldImage removeFromSuperview];
    }
    
	asyncImage.tag = 999;
	[asyncImage setImageWithBlavatarUrl:blog.blavatarUrl isWPcom:blog.isWPcom];
	[cell.contentView addSubview:asyncImage];
	
    cell.textLabel.text = [blog blogName];
    cell.detailTextLabel.text = [blog hostURL];
    
    if ([blog isEqual:self.selectedBlog]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Blog *blog = [resultsController objectAtIndexPath:indexPath];
    self.selectedBlog = blog;
    [self.delegate blogSelectorViewController:self didSelectBlog:blog];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView reloadData];
}

#pragma mark - Fetched results controller delegate

- (NSFetchedResultsController *)resultsController {
    if (resultsController != nil) {
        return resultsController;
    }
    
    WordPressAppDelegate *appDelegate = [WordPressAppDelegate sharedWordPressApplicationDelegate];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:appDelegate.managedObjectContext]];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"blogName" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // For some reasons, the cache sometimes gets corrupted
    // Since we don't really use sections we skip the cache here
    resultsController = [[NSFetchedResultsController alloc]
                                                       initWithFetchRequest:fetchRequest
                                                       managedObjectContext:appDelegate.managedObjectContext
                                                         sectionNameKeyPath:nil
                                                                  cacheName:nil];
    resultsController.delegate = self;
    
     sortDescriptor = nil;
     sortDescriptors = nil;
    
    return resultsController;
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    [self.tableView reloadData];
}

@end
