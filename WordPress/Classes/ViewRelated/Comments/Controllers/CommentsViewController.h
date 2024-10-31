#import <Foundation/Foundation.h>
#import "CommentService.h"

@class Blog;

@interface CommentsViewController : UIViewController

@property (nonatomic) BOOL isSidebarModeEnabled;

+ (CommentsViewController *)controllerWithBlog:(Blog *)blog;
- (void)refreshWithStatusFilter:(CommentStatusFilter)statusFilter;

@end
