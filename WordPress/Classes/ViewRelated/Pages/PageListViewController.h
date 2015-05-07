#import <UIKit/UIKit.h>

@class Blog;

@interface PageListViewController : UIViewController

@property (nonatomic, strong) Blog *blog;

+ (instancetype)controllerWithBlog:(Blog *)blog;

@end
