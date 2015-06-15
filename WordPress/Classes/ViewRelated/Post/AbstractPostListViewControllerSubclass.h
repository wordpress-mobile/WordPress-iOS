#import "AbstractPostListViewController.h"

#import "Blog.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "NavbarTitleDropdownButton.h"
#import "PostListFilter.h"
#import "PostListFooterView.h"
#import "PostService.h"
#import "WPAnimatedBox.h"
#import "WPNoResultsView+AnimatedBox.h"
#import "WPSearchController.h"
#import "WPStyleGuide+Posts.h"
#import "WPTableViewHandler.h"
#import <WordPress-iOS-Shared/WPStyleGuide.h>
#import "WordPress-swift.h"

typedef NS_ENUM(NSUInteger, PostAuthorFilter) {
    PostAuthorFilterMine,
    PostAuthorFilterEveryone,
};

extern const NSTimeInterval PostsControllerRefreshInterval;
extern const NSTimeInterval PostSearchBarAnimationDuration;
extern const NSInteger HTTPErrorCodeForbidden;
extern const NSInteger PostsFetchRequestBatchSize;
extern const NSInteger PostsLoadMoreThreshold;
extern const CGFloat PostsSearchBarWidth;
extern const CGFloat PostsSearchBariPadWidth;
extern const CGSize PreferredFiltersPopoverContentSize;
extern const CGFloat SearchWrapperViewPortraitHeight;
extern const CGFloat SearchWrapperViewLandscapeHeight;

@interface AbstractPostListViewController () <UIPopoverControllerDelegate,
                                                        WPContentSyncHelperDelegate,
                                                        WPNoResultsViewDelegate,
                                                        WPSearchControllerDelegate,
                                                        WPSearchResultsUpdating,
                                                        WPTableViewHandlerDelegate>

@property (nonatomic, strong) UITableViewController *postListViewController;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) UIRefreshControl *refreshControl;
@property (nonatomic, strong) WPTableViewHandler *tableViewHandler;
@property (nonatomic, strong) WPContentSyncHelper *syncHelper;
@property (nonatomic, strong) WPNoResultsView *noResultsView;
@property (nonatomic, strong) PostListFooterView *postListFooterView;
@property (nonatomic, strong) WPAnimatedBox *animatedBox;
@property (nonatomic, weak) IBOutlet NavBarTitleDropdownButton *filterButton;
@property (nonatomic, weak) IBOutlet UIView *rightBarButtonView;
@property (nonatomic, weak) IBOutlet UIButton *searchButton;
@property (nonatomic, weak) IBOutlet UIButton *addButton;
@property (nonatomic, weak) IBOutlet UIView *searchWrapperView; // Used on iPhone for presenting the search bar.
@property (nonatomic, weak) IBOutlet UIView *authorsFilterView; // Search lives here on iPad
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *authorsFilterViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *searchWrapperViewHeightConstraint;
@property (nonatomic, strong) WPSearchController *searchController; // Stand-in for UISearchController
@property (nonatomic, strong) UIPopoverController *postFilterPopoverController;
@property (nonatomic, strong) NSArray *postListFilters;
@property (nonatomic, strong) NSMutableArray *recentlyTrashedPostIDs; // IDs of trashed posts. Cleared on refresh or when filter changes.

- (NSString *)postTypeToSync;
- (void)syncItemsWithUserInteraction:(BOOL)userInteraction;
- (BOOL)canFilterByAuthor;
- (BOOL)shouldShowOnlyMyPosts;
- (PostAuthorFilter)currentPostAuthorFilter;
- (void)setCurrentPostAuthorFilter:(PostAuthorFilter)filter;
- (PostListFilter *)currentPostListFilter;
- (CGFloat)heightForFooterView;
- (void)publishPost:(AbstractPost *)apost;
- (void)viewPost:(AbstractPost *)apost;
- (void)deletePost:(AbstractPost *)apost;
- (void)restorePost:(AbstractPost *)apost;
- (void)updateAndPerformFetchRequestRefreshingCachedRowHeights;
- (BOOL)isSearching;
- (NSString *)currentSearchTerm;
- (NSDictionary *)propertiesForAnalytics;

@end
