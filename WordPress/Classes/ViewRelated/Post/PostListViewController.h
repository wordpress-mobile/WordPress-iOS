#import <UIKit/UIKit.h>
#import <WordPress-Swift.h>

@class Blog;

@interface PostListViewController : AbstractPostListViewController

+ (instancetype)controllerWithBlog:(Blog *)blog;

@end
