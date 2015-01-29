#import <UIKit/UIKit.h>

extern const CGFloat BlogDetailHeaderViewBlavatarSize;

@class Blog;

@interface BlogDetailHeaderView : UIView

- (void)setBlog:(Blog *)blog;

@end
