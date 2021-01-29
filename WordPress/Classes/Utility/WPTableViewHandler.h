#import <Foundation/Foundation.h>

@class WPTableViewHandler;

@protocol WPTableViewHandlerDelegate <NSObject>

- (nonnull NSManagedObjectContext *)managedObjectContext;
- (nonnull NSFetchRequest *)fetchRequest;
- (void)configureCell:(nonnull UITableViewCell *)cell atIndexPath:(nonnull NSIndexPath *)indexPath;
- (void)tableView:(nonnull UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath;

@optional

#pragma mark - WPTableViewHandlerDelegate Methods

- (nonnull NSString *)sectionNameKeyPath;
- (void)deletingSelectedRowAtIndexPath:(nonnull NSIndexPath *)indexPath;
- (void)tableViewDidChangeContent:(nonnull UITableView *)tableView;
- (void)tableViewWillChangeContent:(nonnull UITableView *)tableView;
- (void)tableViewHandlerWillRefreshTableViewPreservingOffset:(nonnull WPTableViewHandler *)tableViewHandler;
- (void)tableViewHandlerDidRefreshTableViewPreservingOffset:(nonnull WPTableViewHandler *)tableViewHandler;


#pragma mark - Proxied UITableViewDelegate Methods.
#pragma mark - Configure rows for the table view.

- (CGFloat)tableView:(nonnull UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath;
- (CGFloat)tableView:(nonnull UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath forWidth:(CGFloat)width;
- (CGFloat)tableView:(nonnull UITableView *)tableView estimatedHeightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath;
- (void)tableView:(nonnull UITableView *)tableView willDisplayCell:(nonnull UITableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)indexPath;

#pragma mark - Managing selections

- (nullable NSIndexPath *)tableView:(nonnull UITableView *)tableView willSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath;

#pragma mark - Modifying the header and footer of sections

- (nullable UIView *)tableView:(nonnull UITableView *)tableView viewForHeaderInSection:(NSInteger)section;
- (CGFloat)tableView:(nonnull UITableView *)tableView heightForHeaderInSection:(NSInteger)section;
- (nullable UIView *)tableView:(nonnull UITableView *)tableView viewForFooterInSection:(NSInteger)section;
- (CGFloat)tableView:(nonnull UITableView *)tableView heightForFooterInSection:(NSInteger)section;
- (void)tableView:(nonnull UITableView *)tableView willDisplayHeaderView:(nonnull UIView *)view forSection:(NSInteger)section;
- (void)tableView:(nonnull UITableView *)tableView willDisplayFooterView:(nonnull UIView *)view forSection:(NSInteger)section;

#pragma mark - Editing table rows

- (UITableViewCellEditingStyle)tableView:(nonnull UITableView *)tableView editingStyleForRowAtIndexPath:(nonnull NSIndexPath *)indexPath;
- (nullable NSString *)tableView:(nonnull UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(nonnull NSIndexPath *)indexPath;

#pragma mark - Editing actions

- (nullable UISwipeActionsConfiguration *)tableView:(nonnull UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(nonnull NSIndexPath *)indexPath;
- (nullable UISwipeActionsConfiguration *)tableView:(nonnull UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(nonnull NSIndexPath *)indexPath;

#pragma mark - Tracking the removal of views

- (void)tableView:(nonnull UITableView *)tableView didEndDisplayingCell:(nonnull UITableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)indexPath;

#pragma mark - Managing table view highlighting

- (BOOL)tableView:(nonnull UITableView *)tableView shouldHighlightRowAtIndexPath:(nonnull NSIndexPath *)indexPath;


#pragma mark - Proxied UITableViewDatasource Methods
#pragma mark - Configuring a table view

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath;

- (nullable NSString *)tableView:(nonnull UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
- (nullable NSString *)tableView:(nonnull UITableView *)tableView titleForFooterInSection:(NSInteger)section;

#pragma mark - Inserting or deleting table rows

- (void)tableView:(nonnull UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(nonnull NSIndexPath *)indexPath;
- (BOOL)tableView:(nonnull UITableView *)tableView canEditRowAtIndexPath:(nonnull NSIndexPath *)indexPath;


#pragma mark - Proxied UIScrollViewDelegate Methods
#pragma mark - Responding to Scrolling and Dragging

- (void)scrollViewWillBeginDragging:(nonnull UIScrollView *)scrollView;
- (void)scrollViewDidEndDecelerating:(nonnull UIScrollView *)scrollView;
- (void)scrollViewDidScroll:(nonnull UIScrollView *)scrollView;
- (void)scrollViewWillEndDragging:(nonnull UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(nonnull inout CGPoint *)targetContentOffset;
- (void)scrollViewDidEndDragging:(nonnull UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;

@end


@interface WPTableViewHandler : NSObject <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong, readonly, nonnull) UITableView *tableView;
@property (nonatomic, strong, readonly, nonnull) NSFetchedResultsController *resultsController;
@property (nonatomic, weak, nullable) id<WPTableViewHandlerDelegate> delegate;
@property (nonatomic) BOOL cacheRowHeights;
@property (nonatomic, readonly) BOOL isScrolling;
@property (nonatomic) UITableViewRowAnimation updateRowAnimation;
@property (nonatomic) UITableViewRowAnimation insertRowAnimation;
@property (nonatomic) UITableViewRowAnimation deleteRowAnimation;
@property (nonatomic) UITableViewRowAnimation moveRowAnimation;
@property (nonatomic) UITableViewRowAnimation sectionRowAnimation;
@property (nonatomic) BOOL listensForContentChanges;

- (nonnull instancetype)initWithTableView:(nonnull UITableView *)tableView;
- (void)clearCachedRowHeights;
- (void)refreshCachedRowHeightsForWidth:(CGFloat)width;
- (void)invalidateCachedRowHeightAtIndexPath:(nonnull NSIndexPath *)indexPath;

/**
 A convenience method for clearing cached row heights and reloading the table view.
 */
- (void)refreshTableView;

/**
 Reloads the table, adjusting the table view's content offset so that the currently
 visible content stays in place.
 
 The caller should update the tableview's content, (i.e. the fetched results)  
 in the `tableViewHandlerWillRefreshTableViewPreservingOffset:` delegate method.
 */
- (void)refreshTableViewPreservingOffset;

@end
