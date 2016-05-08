#import <UIKit/UIKit.h>
#import "NavbarTitleDropdownButton.h"
#import "PostListFilter.h"
#import "WordPress-swift.h"

@class Blog;

typedef NS_ENUM(NSUInteger, PostAuthorFilter) {
    PostAuthorFilterMine,
    PostAuthorFilterEveryone,
};

extern const NSTimeInterval PostsControllerRefreshInterval;
extern const NSInteger HTTPErrorCodeForbidden;
extern const NSInteger PostsFetchRequestBatchSize;
extern const NSInteger PostsLoadMoreThreshold;
extern const CGSize PreferredFiltersPopoverContentSize;

@interface AbstractPostListViewController : UIViewController

@property (nonatomic, strong) Blog* __nullable blog;

/**
 *  Sets the filtering of this VC to show the posts with the specified status.
 *
 *  @param      status      The status of the type of post we want to show.
 */
- (void)setFilterWithPostStatus:(NSString* __nonnull)status;

@property (nullable, nonatomic, strong) UITableViewController *postListViewController;
@property (nullable, nonatomic, weak) UITableView *tableView;
@property (nullable, nonatomic, weak) UIRefreshControl *refreshControl;
@property (nullable, nonatomic, strong) WPTableViewHandler *tableViewHandler;
@property (nullable, nonatomic, strong) WPContentSyncHelper *syncHelper;
@property (nullable, nonatomic, strong) WPNoResultsView *noResultsView;
@property (nullable, nonatomic, strong) PostListFooterView *postListFooterView;
@property (nullable, nonatomic, strong) WPAnimatedBox *animatedBox;
@property (nullable, nonatomic, weak) IBOutlet NavBarTitleDropdownButton *filterButton;
@property (nullable, nonatomic, weak) IBOutlet UIView *rightBarButtonView;
@property (nullable, nonatomic, weak) IBOutlet UIButton *searchButton;
@property (nullable, nonatomic, weak) IBOutlet UIButton *addButton;
@property (nullable, nonatomic, weak) IBOutlet UIView *searchWrapperView; // Used on iPhone for presenting the search bar.
@property (nullable, nonatomic, weak) IBOutlet UIView *authorsFilterView; // Search lives here on iPad
@property (nullable, nonatomic, weak) IBOutlet NSLayoutConstraint *authorsFilterViewHeightConstraint;
@property (nullable, nonatomic, weak) IBOutlet NSLayoutConstraint *searchWrapperViewHeightConstraint;
@property (nullable, nonatomic, strong) WPSearchController *searchController; // Stand-in for UISearchController
@property (nullable, nonatomic, strong) NSMutableDictionary <NSString *, NSArray *> *allPostListFilters;
@property (nullable, nonatomic, strong) NSMutableArray *recentlyTrashedPostObjectIDs; // IDs of trashed posts. Cleared on refresh or when filter changes.

- (NSString* _Nonnull)postTypeToSync;
- (NSDate* _Nullable)lastSyncDate;
- (void)syncItemsWithUserInteraction:(BOOL)userInteraction;
- (BOOL)canFilterByAuthor;
- (BOOL)shouldShowOnlyMyPosts;
- (PostAuthorFilter)currentPostAuthorFilter;
- (void)setCurrentPostAuthorFilter:(PostAuthorFilter)filter;
- (PostListFilter * _Nullable)currentPostListFilter;
- (CGFloat)heightForFooterView;
- (void)publishPost:(AbstractPost* _Nonnull)apost;
- (void)viewPost:(AbstractPost* _Nonnull)apost;
- (void)deletePost:(AbstractPost* _Nonnull)apost;
- (void)restorePost:(AbstractPost* _Nonnull)apost;
- (void)updateAndPerformFetchRequestRefreshingCachedRowHeights;
- (void)resetTableViewContentOffset;
- (BOOL)isSearching;
- (NSString* _Nullable)currentSearchTerm;
- (NSDictionary* _Nonnull)propertiesForAnalytics;
- (NSManagedObjectContext* _Nonnull)managedObjectContext;

@end
