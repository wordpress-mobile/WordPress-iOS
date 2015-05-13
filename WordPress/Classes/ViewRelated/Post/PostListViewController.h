#import <UIKit/UIKit.h>
#import "AbstractPostListViewController.h"

@class Blog;

@interface PostListViewController : AbstractPostListViewController

+ (instancetype)controllerWithBlog:(Blog *)blog;

@end
