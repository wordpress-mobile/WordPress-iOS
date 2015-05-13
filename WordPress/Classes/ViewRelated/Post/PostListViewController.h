#import <UIKit/UIKit.h>

@class Blog;

@interface PostListViewController : UIViewController

@property (nonatomic, strong) Blog *blog;

+ (instancetype)controllerWithBlog:(Blog *)blog;

@end
