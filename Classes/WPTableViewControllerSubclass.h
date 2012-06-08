//
//  WPTableViewControllerSubclass.h
//  WordPress
//
//  Created by Jorge Bernal on 6/8/12.
//  Copyright (c) 2012 WordPress. All rights reserved.
//

#import "WPTableViewController.h"

@interface WPTableViewController (SubclassMethods)
@property (nonatomic,retain) NSFetchedResultsController *resultsController;

- (void)syncItemsWithUserInteraction:(BOOL)userInteraction;

/**
 @group Methods that subclasses should implement
 */

/**
 Core Data entity name used by NSFetchedResultsController
 
 e.g. Post, Page, Comment, ...
 
 Subclasses *MUST* implement this method
 */
- (NSString *)entityName;

/**
 When this content was last synced.
 
 @return a NSDate object, or nil if it's never been synced before
 */
- (NSDate *)lastSyncDate;

/**
 Custom fetch request for NSFetchedResultsController
 
 Optional. Only needed if there are custom sort descriptors or predicate
 */
- (NSFetchRequest *)fetchRequest;
- (NSString *)sectionNameKeyPath;
/**
 Returns a new (unconfigured) cell for the table view.
 
 Optional. If a subclass doesn't implement this method, a UITableViewCell with the default style is used
 */
- (UITableViewCell *)newCell;
/**
 Configure a table cell for a specific index path
 
 Subclasses *MUST* implement this method
 */
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
/**
 Performs syncing of items
 
 Subclasses *MUST* implement this method
 
 @param userInteraction true if the sync responds to a user action, like pull to refresh
 */
- (void)syncItemsWithUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *error))failure;

- (BOOL)hasMoreContent;
- (void)loadMoreContent;

@end
