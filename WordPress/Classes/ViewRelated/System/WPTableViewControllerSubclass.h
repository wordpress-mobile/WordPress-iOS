#import "WPTableViewController.h"

@class WPNoResultsView;

@interface WPTableViewController (SubclassMethods)
/**
 The results controller is made available to the subclasses so they can access the data
 */
@property (nonatomic,readonly,retain) NSFetchedResultsController *resultsController;

/**
 Enables the infinteScrolling
 */
@property (nonatomic) BOOL infiniteScrollEnabled;

/**
 The noResultsView is made available to subclasses so they can customize its content.
 */
@property (nonatomic, readonly, strong) WPNoResultsView *noResultsView;


/**
 Sync content with the server
 
 Subclasses can call this method if they need to invoke a refresh, but it's not meant to be implemented by subclasses.
 Override syncItemsViaUserInteraction:success:failure: instead.
 */
- (void)syncItems;


/// ----------------------------------------------
/// @name Methods that subclasses should implement
/// ----------------------------------------------

/**
 The NSManagedObjectContext to use. 
 
 Optional. Only needed if there subclass needs a custom context. 
 */
- (NSManagedObjectContext *)managedObjectContext;

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

/**
 The attribute name to use to group results into sections
 
 @see [NSFetchedResultsController initWithFetchRequest:managedObjectContext:sectionNameKeyPath:cacheName:] for more info on sectionNameKeyPath
 */
- (NSString *)sectionNameKeyPath;

/**
 Returns the class for the cell being used
 
 Optional. If a subclass doesn't implement this method, the UITableViewCell
 
 @return the class for the cell to be registered
 */
- (Class)cellClass;

/**
 Configure a table cell for a specific index path
 
 Subclasses *MUST* implement this method
 */
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

/**
 Performs syncing of items
 
 Subclasses *MUST* implement this method
 
 @param userInteraction true if the sync is in response to a user action, like pull to refresh
 @param success A block that's executed if the sync was successful
 @param failure A block that's executed if there was any error
 */
- (void)syncItemsViaUserInteraction:(BOOL)userInteraction success:(void (^)())success failure:(void (^)(NSError *error))failure;

/**
 Returns a boolean indicating if the blog is syncing that type of item right now
 
 Optional. If a subclass doesn't implement this method, WPTableViewController tracks syncing internally.
 Subclasses might want to implement this if the objects are going to be synced from other parts of the app
 */
- (BOOL)isSyncing;

/**
 If the subclass supports infinite scrolling, and there's more content available, return YES.
 This is an optional method which returns NO by default
 
 @return YES if there is more content to load
 */
- (BOOL)hasMoreContent;

/**
 Load extra content for infinite scrolling

 Subclasses *MUST* implement this method if infiniteScrollingEnabled is YES

 @param success A block that's executed if the sync was successful
 @param failure A block that's executed if there was any error
 */
- (void)loadMoreWithSuccess:(void (^)())success failure:(void (^)(NSError *error))failure;

/**
 Create a custom view to display to the user when there are no results to show.
 
 Optional. If a subclass does not override this method a default view is constructed.
 @return The view to use for the no results view.
 */
- (UIView *)createNoResultsView;


/**
 Returns the row animation style the tableview should use.
 
 Optional. If the sub class does not implment this method the default will be used.
 @return The row animation style that the tableview should use.
 */
- (UITableViewRowAnimation)tableViewRowAnimation;


/**
 Completely reset the resultsController. Useful if the fetchRequest needs to be recreated with a new predicate.
 */
- (void)resetResultsController;

/**
 Checks to see if a refresh should occur. 
 */
- (BOOL)userCanRefresh;

@end
