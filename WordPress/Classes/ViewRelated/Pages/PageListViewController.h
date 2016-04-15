#import <UIKit/UIKit.h>

@class Blog;

@interface PageListViewController : AbstractPostListViewController

+ (instancetype)controllerWithBlog:(Blog *)blog;

@end
