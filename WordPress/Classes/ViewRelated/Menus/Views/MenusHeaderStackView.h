#import <UIKit/UIKit.h>

@class Blog;

@interface MenusHeaderStackView : UIStackView

- (void)updateWithMenusForBlog:(Blog *)blog;

@end
