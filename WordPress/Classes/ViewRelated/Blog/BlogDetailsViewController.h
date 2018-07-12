#import <UIKit/UIKit.h>

@class Blog;

typedef NS_ENUM(NSUInteger, BlogDetailsSubsection) {
    BlogDetailsSubsectionStats,
    BlogDetailsSubsectionPosts,
    BlogDetailsSubsectionCustomize,
    BlogDetailsSubsectionThemes,
    BlogDetailsSubsectionMedia,
    BlogDetailsSubsectionPages,
    BlogDetailsSubsectionActivity
};

@interface BlogDetailsViewController : UITableViewController <UIViewControllerRestoration> {
    
}

@property (nonatomic, strong) Blog *blog;

- (void)showDetailViewForSubsection:(BlogDetailsSubsection)section;

@end
