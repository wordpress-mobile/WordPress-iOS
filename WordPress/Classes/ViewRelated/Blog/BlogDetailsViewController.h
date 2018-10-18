#import <UIKit/UIKit.h>

@class Blog;

typedef NS_ENUM(NSUInteger, BlogDetailsSubsection) {
    BlogDetailsSubsectionQuickStart,
    BlogDetailsSubsectionStats,
    BlogDetailsSubsectionPosts,
    BlogDetailsSubsectionCustomize,
    BlogDetailsSubsectionThemes,
    BlogDetailsSubsectionMedia,
    BlogDetailsSubsectionPages,
    BlogDetailsSubsectionActivity,
    BlogDetailsSubsectionComments,
    BlogDetailsSubsectionSharing,
    BlogDetailsSubsectionPeople,
    BlogDetailsSubsectionPlugins
};

@interface BlogDetailsViewController : UITableViewController <UIViewControllerRestoration, UIViewControllerTransitioningDelegate> {
    
}

@property (nonatomic, strong) Blog *blog;

- (void)showDetailViewForSubsection:(BlogDetailsSubsection)section;
- (void)reloadTableViewPreservingSelection;
- (void)configureTableViewData;
@end
