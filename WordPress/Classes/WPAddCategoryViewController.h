#import <UIKit/UIKit.h>

extern NSString *const NewCategoryCreatedAndUpdatedInBlogNotification;

@class Blog;

@interface WPAddCategoryViewController : UIViewController

- (id)initWithBlog:(Blog *)blog;

@end
