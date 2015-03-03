#import <UIKit/UIKit.h>

@class Blog;

@interface CalypsoPostsViewController : UIViewController

@property (nonatomic, strong) Blog *blog;

+ (instancetype)controllerWithBlog:(Blog *)blog;

@end
