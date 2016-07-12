#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class Blog;

@interface MenusViewController : UIViewController

+ (MenusViewController *)controllerWithBlog:(Blog *)blog;

@end

NS_ASSUME_NONNULL_END
