#import <UIKit/UIKit.h>

@class Blog;
@class BlogDetailHeaderView;
@class CreateButtonCoordinator;
@class IntrinsicTableView;
@class MeViewController;
@protocol BlogDetailHeader;

typedef NS_ENUM(NSUInteger, BlogDetailsSectionCategory) {
    BlogDetailsSectionCategoryReminders,
    BlogDetailsSectionCategoryDomainCredit,
    BlogDetailsSectionCategoryHome,
    BlogDetailsSectionCategoryGeneral,
    BlogDetailsSectionCategoryJetpack,
    BlogDetailsSectionCategoryPersonalize,
    BlogDetailsSectionCategoryConfigure,
    BlogDetailsSectionCategoryExternal,
    BlogDetailsSectionCategoryRemoveSite,
    BlogDetailsSectionCategoryMigrationSuccess,
    BlogDetailsSectionCategoryJetpackBrandingCard,
    BlogDetailsSectionCategoryJetpackInstallCard,
    BlogDetailsSectionCategorySotW2023Card,
    BlogDetailsSectionCategoryContent,
    BlogDetailsSectionCategoryTraffic,
    BlogDetailsSectionCategoryMaintenance
};

typedef NS_ENUM(NSUInteger, BlogDetailsSubsection) {
    BlogDetailsSubsectionReminders,
    BlogDetailsSubsectionDomainCredit,
    BlogDetailsSubsectionStats,
    BlogDetailsSubsectionPosts,
    BlogDetailsSubsectionCustomize,
    BlogDetailsSubsectionThemes,
    BlogDetailsSubsectionMedia,
    BlogDetailsSubsectionPages,
    BlogDetailsSubsectionActivity,
    BlogDetailsSubsectionJetpackSettings,
    BlogDetailsSubsectionMe,
    BlogDetailsSubsectionComments,
    BlogDetailsSubsectionSharing,
    BlogDetailsSubsectionPeople,
    BlogDetailsSubsectionPlugins,
    BlogDetailsSubsectionHome,
    BlogDetailsSubsectionMigrationSuccess,
    BlogDetailsSubsectionJetpackBrandingCard,
    BlogDetailsSubsectionBlaze,
    BlogDetailsSubsectionSiteMonitoring
};

typedef NS_ENUM(NSUInteger, BlogDetailsNavigationSource) {
    BlogDetailsNavigationSourceButton = 0,
    BlogDetailsNavigationSourceRow = 1,
    BlogDetailsNavigationSourceLink = 2,
    BlogDetailsNavigationSourceWidget = 3,
    BlogDetailsNavigationSourceOnboarding = 4,
    BlogDetailsNavigationSourceNotification = 5,
    BlogDetailsNavigationSourceShortcut = 6,
    BlogDetailsNavigationSourceTodayStatsCard = 7,
};


@interface BlogDetailsSection : NSObject

@property (nonatomic, strong, nullable, readonly) NSString *title;
@property (nonatomic, strong, nonnull, readonly) NSArray *rows;
@property (nonatomic, strong, nullable, readonly) NSString *footerTitle;
@property (nonatomic, readonly) BlogDetailsSectionCategory category;

- (instancetype _Nonnull)initWithTitle:(NSString * __nullable)title andRows:(NSArray * __nonnull)rows category:(BlogDetailsSectionCategory)category;
- (instancetype _Nonnull)initWithTitle:(NSString * __nullable)title rows:(NSArray * __nonnull)rows footerTitle:(NSString * __nullable)footerTitle category:(BlogDetailsSectionCategory)category;

@end


@interface BlogDetailsRow : NSObject

@property (nonatomic, strong, nonnull) NSString *title;
@property (nonatomic, strong, nonnull) NSString *identifier;
@property (nonatomic, strong, nullable) NSString *accessibilityIdentifier;
@property (nonatomic, strong, nullable) NSString *accessibilityHint;
@property (nonatomic, strong, nonnull) UIImage *image;
@property (nonatomic, strong, nullable) UIColor *imageColor;
@property (nonatomic, strong, nullable) UIView *accessoryView;
@property (nonatomic, strong, nullable) NSString *detail;
@property (nonatomic) BOOL showsSelectionState;
@property (nonatomic) BOOL forDestructiveAction;
@property (nonatomic) BOOL showsDisclosureIndicator;
@property (nonatomic, copy, nullable) void (^callback)(void);

- (instancetype _Nonnull)initWithTitle:(NSString * __nonnull)title
                            identifier:(NSString * __nonnull)identifier
               accessibilityIdentifier:(NSString *__nullable)accessibilityIdentifier
                                 image:(UIImage * __nonnull)image
                              callback:(void(^_Nullable)(void))callback;

- (instancetype _Nonnull)initWithTitle:(NSString * __nonnull)title
                            identifier:(NSString * __nonnull)identifier
               accessibilityIdentifier:(NSString *__nullable)accessibilityIdentifier
                     accessibilityHint:(NSString *__nullable)accessibilityHint
                                 image:(UIImage * __nonnull)image
                              callback:(void(^_Nullable)(void))callback;

- (instancetype _Nonnull)initWithTitle:(NSString * __nonnull)title
               accessibilityIdentifier:(NSString *__nullable)accessibilityIdentifier
                                 image:(UIImage * __nonnull)image
                            imageColor:(UIColor * __nullable)imageColor
                              callback:(void(^_Nullable)(void))callback;

- (instancetype _Nonnull)initWithTitle:(NSString * __nonnull)title
               accessibilityIdentifier:(NSString *__nullable)accessibilityIdentifier
                                 image:(UIImage * __nonnull)image
                            imageColor:(UIColor * __nullable)imageColor
                         renderingMode:(UIImageRenderingMode)renderingMode
                              callback:(void(^_Nullable)(void))callback;

@end

@protocol ScenePresenter;

@protocol BlogDetailsPresentationDelegate
- (void)presentBlogDetailsViewController:(UIViewController * __nonnull)viewController;
@end

@interface BlogDetailsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIViewControllerTransitioningDelegate>

@property (nonatomic, strong, nonnull) Blog * blog;
@property (nonatomic, strong, readonly) CreateButtonCoordinator * _Nullable createButtonCoordinator;
@property (nonatomic, strong, readwrite) UITableView * _Nonnull tableView;
@property (nonatomic) BOOL isScrollEnabled;
@property (nonatomic, weak, nullable) id<BlogDetailsPresentationDelegate> presentationDelegate;
@property (nonatomic, strong, nullable) BlogDetailsRow *meRow;

/// A new display mode for the displaying it as part of the site menu.
@property (nonatomic) BOOL isSidebarModeEnabled;

- (id _Nonnull)init;
- (void)showDetailViewForSubsection:(BlogDetailsSubsection)section;
- (void)showDetailViewForSubsection:(BlogDetailsSubsection)section userInfo:(nonnull NSDictionary *)userInfo;
- (NSIndexPath * _Nonnull)indexPathForSubsection:(BlogDetailsSubsection)subsection;
- (void)reloadTableViewPreservingSelection;
- (void)configureTableViewData;

- (nonnull MeViewController *)showDetailViewForMeSubsectionWithUserInfo:(nonnull NSDictionary *)userInfo;

- (void)switchToBlog:(nonnull Blog *)blog;
- (void)showInitialDetailsForBlog;
- (void)showPostListFromSource:(BlogDetailsNavigationSource)source;
- (void)showPageListFromSource:(BlogDetailsNavigationSource)source;
- (void)showMediaLibraryFromSource:(BlogDetailsNavigationSource)source;
- (void)showStatsFromSource:(BlogDetailsNavigationSource)source;
- (void)updateTableView:(nullable void(^)(void))completion;
- (void)preloadMetadata;
- (void)pulledToRefreshWith:(nonnull UIRefreshControl *)refreshControl onCompletion:(nullable void(^)(void))completion;

+ (nonnull NSString *)userInfoShowPickerKey;
+ (nonnull NSString *)userInfoSiteMonitoringTabKey;
+ (nonnull NSString *)userInfoShowManagemenetScreenKey;
+ (nonnull NSString *)userInfoSourceKey;

@end
