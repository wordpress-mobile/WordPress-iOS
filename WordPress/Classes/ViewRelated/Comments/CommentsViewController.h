#import <Foundation/Foundation.h>

@class Blog;

@interface CommentsViewController : UIViewController

+ (CommentsViewController *)controllerWithBlog:(Blog *)blog;

@end
