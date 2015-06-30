#import <UIKit/UIKit.h>
#import "AbstractPostListViewController.h"

@class Blog;

@interface PageListViewController : AbstractPostListViewController

+ (instancetype)controllerWithBlog:(Blog *)blog;

@end
