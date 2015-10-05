#import <UIKit/UIKit.h>

@class Blog;
@class PostCategory;
@protocol WPAddPostCategoryViewControllerDelegate;

@interface WPAddPostCategoryViewController : UITableViewController

- (instancetype)initWithBlog:(Blog *)blog;

@property (nonatomic, weak) id<WPAddPostCategoryViewControllerDelegate>delegate;

@end

@protocol WPAddPostCategoryViewControllerDelegate <NSObject>

@optional
- (void)addPostCategoryViewController:(WPAddPostCategoryViewController *)controller didAddCategory:(PostCategory *)category;

@end
