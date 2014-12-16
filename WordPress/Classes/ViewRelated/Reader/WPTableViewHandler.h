#import <Foundation/Foundation.h>

@class WPTableViewHandler;

@protocol WPTableViewHandlerDelegate <NSObject>

- (NSManagedObjectContext *)managedObjectContext;
- (NSFetchRequest *)fetchRequest;
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (NSString *)sectionNameKeyPath;
- (NSString *)titleForHeaderInSection:(NSInteger)section;
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath forWidth:(CGFloat)width;
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)deletingSelectedRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableViewDidChangeContent:(UITableView *)tableView;
- (void)tableViewWillChangeContent:(UITableView *)tableView;
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section;
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section;
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section;
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section;
- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
- (void)tableViewHandlerWillRefreshTableViewPreservingOffset:(WPTableViewHandler *)tableViewHandler;
- (void)tableViewHandlerDidRefreshTableViewPreservingOffset:(WPTableViewHandler *)tableViewHandler;

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
