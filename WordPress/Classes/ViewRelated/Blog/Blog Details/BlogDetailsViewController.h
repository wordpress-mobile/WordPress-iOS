#import <UIKit/UIKit.h>

@class Blog;
@class BlogDetailHeaderView;
@class CreateButtonCoordinator;
@class IntrinsicTableView;
@protocol BlogDetailHeader;

typedef NS_ENUM(NSUInteger, BlogDetailsSectionCategory) {
    BlogDetailsSectionCategoryReminders,
    BlogDetailsSectionCategoryDomainCredit,
    BlogDetailsSectionCategoryQuickStart,
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
    BlogDetailsSubsectionQuickStart,
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

typedef NS_ENUM(NSInteger, QuickStartTitleState) {
    QuickStartTitleStateUndefined = 0,
    QuickStartTitleStateCustomizeIncomplete = 1,
    QuickStartTitleStateGrowIncomplete = 2,
    QuickStartTitleStateCompleted = 3,
};

typedef NS_ENUM(NSInteger, QuickStartTourElement) {
    QuickStartTourElementNoSuchElement = 0,
    QuickStartTourElementTabFlipped = 1,
    QuickStartTourElementBlogDetailNavigation = 2,
    QuickStartTourElementViewSite = 3,
    QuickStartTourElementChecklist = 4,
    QuickStartTourElementThemes = 5,
    QuickStartTourElementCustomize = 6,
    QuickStartTourElementNewpost = 7,
    QuickStartTourElementSharing = 8,
    QuickStartTourElementConnections = 9,
    QuickStartTourElementReaderTab = 10,
    QuickStartTourElementReaderDiscoverSettings = 12,
    QuickStartTourElementTourCompleted = 13,
    QuickStartTourElementCongratulations = 14,
    QuickStartTourElementSiteIcon = 15,
    QuickStartTourElementPages = 16,
    QuickStartTourElementNewPage = 17,
    QuickStartTourElementStats = 18,
    QuickStartTourElementPlans = 19,
    QuickStartTourElementSiteTitle = 20,
    QuickStartTourElementSiteMenu = 21,
    QuickStartTourElementNotifications = 22,
    QuickStartTourElementSetupQuickStart = 23,
    QuickStartTourElementUpdateQuickStart = 24,
    QuickStartTourElementMediaScreen = 25,
    QuickStartTourElementMediaUpload = 26,
};

typedef NS_ENUM(NSUInteger, BlogDetailsNavigationSource) {
    BlogDetailsNavigationSourceButton = 0,
    BlogDetailsNavigationSourceRow = 1,
    BlogDetailsNavigationSourceLink = 2
};


@interface BlogDetailsSection : NSObject

@property (nonatomic, strong, nullable, readonly) NSString *title;
@property (nonatomic, strong, nonnull, readonly) NSArray *rows;
@property (nonatomic, strong, nullable, readonly) NSString *footerTitle;
@property (nonatomic, readonly) BlogDetailsSectionCategory category;
@property (nonatomic) BOOL showQuickStartMenu;

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
@property (nonatomic) QuickStartTourElement quickStartIdentifier;
@property (nonatomic) QuickStartTitleState quickStartTitleState;

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

@interface BlogDetailsViewController : UIViewController <UIViewControllerRestoration, UIViewControllerTransitioningDelegate> {
    
}

@property (nonatomic, strong, nonnull) Blog * blog;
@property (nonatomic, strong, readonly) CreateButtonCoordinator * _Nullable createButtonCoordinator;
@property (nonatomic, strong, readwrite) UITableView * _Nonnull tableView;
@property (nonatomic) BOOL isScrollEnabled;
@property (nonatomic, weak, nullable) id<BlogDetailsPresentationDelegate> presentationDelegate;
@property (nonatomic, strong, nullable) BlogDetailsRow *meRow;

- (id _Nonnull)init;
- (void)showDetailViewForSubsection:(BlogDetailsSubsection)section;
- (void)showDetailViewForSubsection:(BlogDetailsSubsection)section userInfo:(nonnull NSDictionary *)userInfo;
- (NSIndexPath * _Nonnull)indexPathForSubsection:(BlogDetailsSubsection)subsection;
- (void)reloadTableViewPreservingSelection;
- (void)configureTableViewData;
- (void)scrollToElement:(QuickStartTourElement)element;

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

@end
