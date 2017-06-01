#import <UIKit/UIKit.h>

extern const CGFloat BlogDetailHeaderViewBlavatarSize;

@protocol BlogDetailHeaderViewDelegate

- (void)siteIconTapped;

@end

@class Blog;

@interface BlogDetailHeaderView : UIView

@property (nonatomic, weak) id<BlogDetailHeaderViewDelegate> delegate;
@property (nonatomic) BOOL updatingIcon;

- (void)setBlog:(Blog *)blog;
- (void)updateIconImage:(NSString *)iconURL;

@end
