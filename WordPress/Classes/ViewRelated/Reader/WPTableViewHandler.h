#import <Foundation/Foundation.h>

@class WPTableViewHandler;

@protocol WPTableViewHandlerDelegate <NSObject>

- (NSManagedObjectContext *)managedObjectContext;
- (NSFetchRequest *)fetchRequest;
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

#pragma mark - WPTableViewHandlerDelegate Methods

- (NSString *)sectionNameKeyPath;
- (void)deletingSelectedRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableViewDidChangeContent:(UITableView *)tableView;
- (void)tableViewWillChangeContent:(UITableView *)tableView;
- (void)tableViewHandlerWillRefreshTableViewPreservingOffset:(WPTableViewHandler *)tableViewHandler;
- (void)tableViewHandlerDidRefreshTableViewPreservingOffset:(WPTableViewHandler *)tableViewHandler;


#pragma mark - Proxied UITableViewDelegate Methods.
#pragma mark - Configure rows for the table view.

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath forWidth:(CGFloat)width;
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark - Managing selections

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark - Modifying the header and footer of sections

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section;
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section;
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section;
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section;

#pragma mark - Editing table rows

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark - Tracking the removal of views

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark - Managing table view highlighting

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath;


#pragma mark - Proxied UITableViewDatasource Methods
#pragma mark - Configuring a table view

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (NSString *)titleForHeaderInSection:(NSInteger)section;

#pragma mark - Inserting or deleting table rows

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath;


#pragma mark - Proxied UIScrollViewDelegate Methods
#pragma mark - Responding to Scrolling and Dragging

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;

@end


@interface WPTableViewHandler : NSObject <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong, readonly) UITableView *tableView;
@property (nonatomic, strong, readonly) NSFetchedResultsController *resultsController;
@property (nonatomic, weak) id<WPTableViewHandlerDelegate> delegate;
@property (nonatomic) BOOL cacheRowHeights;
@property (nonatomic, readonly) BOOL isScrolling;
@property (nonatomic) BOOL shouldRefreshTableViewPreservingOffset;
@property (nonatomic) UITableViewRowAnimation updateRowAnimation;
@property (nonatomic) UITableViewRowAnimation insertRowAnimation;
@property (nonatomic) UITableViewRowAnimation deleteRowAnimation;
@property (nonatomic) UITableViewRowAnimation moveRowAnimation;
@property (nonatomic) UITableViewRowAnimation sectionRowAnimation;

- (instancetype)initWithTableView:(UITableView *)tableView;
- (void)updateTitleForSection:(NSUInteger)section;
- (void)clearCachedRowHeights;
- (void)refreshCachedRowHeightsForWidth:(CGFloat)width;
- (void)invalidateCachedRowHeightAtIndexPath:(NSIndexPath *)indexPath;

@end
