#import <UIKit/UIKit.h>

@class AbstractPost;

@interface PostViewController : UIViewController

/*
 Initialize the detail with the specified post.
 @param post The post to display.
 */
- (id)initWithPost:(AbstractPost *)post;

@end
