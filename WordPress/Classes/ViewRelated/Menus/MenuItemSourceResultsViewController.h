#import <UIKit/UIKit.h>
#import "MenuItemSourceTextBar.h"
#import "MenuItemSourceCell.h"
#import "MenuItem.h"

NS_ASSUME_NONNULL_BEGIN

@class Blog;
@class MenuItem;

@protocol MenuItemSourceResultsViewControllerDelegate;

@interface MenuItemSourceResultsViewController : UIViewController <MenuItemSourceTextBarDelegate, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, weak, nullable) id <MenuItemSourceResultsViewControllerDelegate> delegate;

/**
 The blog the view is sourcing data from.
 */
@property (nonatomic, strong) Blog *blog;

/**
 The MenuItem the view is editing.
 */
@property (nonatomic, strong) MenuItem *item;

/**
 A stackView for adding any views that aren't cells before the tableView, Ex. searchBar, label, design views
 */
@property (nonatomic, strong, readonly) UIStackView *stackView;

/**
 A tableView for inserting cells of data relating to the source
 */
@property (nonatomic, strong, readonly) UITableView *tableView;

/**
 Searchbar created and implemented via insertSearchBarIfNeeded
 */
@property (nonatomic, strong, readonly) MenuItemSourceTextBar *searchBar;

/**
 Helpers flag for preventing text updates within the footerView.
 */
@property (nonatomic, assign) BOOL defersFooterViewMessageUpdates;

/**
 Refreshes any data appearences within the view.
 */
- (void)refresh;

/**
 Adds the custom searchBar view to the stackView, if not already added.
 */
- (void)insertSearchBarIfNeeded;

/**
 The searchBar is active as a firstResponder or the user has text input within the the searchBar.
 */
- (BOOL)searchBarInputIsActive;

/**
 A searchBar text update has changed in a way that local results should be fetched to reflect the search.
 */
- (void)searchBarInputChangeDetectedForLocalResultsUpdateWithText:(nullable NSString *)searchText;

/**
 A searchBar text update has changed in a way that remote results should be fetched to reflect the search.
 */
- (void)searchBarInputChangeDetectedForRemoteResultsUpdateWithText:(nullable NSString *)searchText;

/**
 Shows an animated loading indicator in the tableFooterView, if the data set is empty.
 */
- (void)showLoadingSourcesIndicatorIfEmpty;

/**
 Shows an animated loading indicator in the tableFooterView.
 */
- (void)showLoadingSourcesIndicator;

/**
 Hides the animated loading indicator shown via showLoadingSourcesIndicator.
 */
- (void)hideLoadingSourcesIndicator;

/**
 Displays an error message in the footer of the tableView.
 */
- (void)showLoadingErrorMessageForResults;

/**
 The item type matches the sourceItemType of the view.
 */
- (BOOL)itemTypeMatchesSourceItemType;

/**
 Called when a source has been selected and the MenuItem should be updated.
 @param contentId - The ID of the source such as a postID, tagID, categoryID, etc.
 @param itemType - The type of the source.
 @param name - The name that should be used for the source.
 */
- (void)setItemSourceWithContentID:(nullable NSNumber *)contentID name:(nullable NSString *)name;

/**
 The item type the view uses as a source.
 */
- (NSString *)sourceItemType;

/**
 The managedObjectContext the view is working with.
 */
- (NSManagedObjectContext *)managedObjectContext;

/**
 Configurable fetchRequest within subclasses for the resultsController to initialize with.
 */
- (nullable NSFetchRequest *)fetchRequest;

/**
 Configurable predicate for fetchRequest
 */
- (nullable NSPredicate *)defaultFetchRequestPredicate;

/**
 Configurable fetchedResultsController for populating the tableView with source data.
 */
- (nullable NSFetchedResultsController *)resultsController;

/**
 Configurable sectionName key within subclasses for the fetchRequest and resultsController to initialize with.
 */
- (nullable NSString *)fetechedResultsControllerSectionNameKeyPath;

/**
 Handles performing the fetchRequest on the resultsController and any errors that occur.
 */
- (void)performResultsControllerFetchRequest;

/**
 Deselects any visible MenuItemSourceCells that are selected.
 */
- (void)deselectVisibleSourceCellsIfNeeded;

/**
 Method for subclasses to handle the cell configuraton based on the data being used for that subclass.
 */
- (void)configureSourceCell:(MenuItemSourceCell *)cell forIndexPath:(NSIndexPath *)indexPath;

/**
 Scrolling behavior will display the end of the tableView.
 */
- (void)scrollingWillDisplayEndOfTableView:(UITableView *)tableView;

@end

@protocol MenuItemSourceResultsViewControllerDelegate <NSObject>

/**
 Helper method for informing whether or not the name should be overriden by itemType changes.
 */
- (BOOL)sourceResultsViewControllerCanOverrideItemName:(MenuItemSourceResultsViewController *)sourceResultsViewController;

/**
 The associated MenuItem was updated.
 */
- (void)sourceResultsViewControllerDidUpdateItem:(MenuItemSourceResultsViewController *)sourceResultsViewController;

/**
 Helper method for updating any layout constraints for keyboard changes.
 */
- (void)sourceResultsViewControllerDidBeginEditingWithKeyBoard:(MenuItemSourceResultsViewController *)sourceResultsViewController;

/**
 Helper method for updating any layout constraints for keyboard changes.
 */
- (void)sourceResultsViewControllerDidEndEditingWithKeyboard:(MenuItemSourceResultsViewController *)sourceResultsViewController;

@end

NS_ASSUME_NONNULL_END
