#import <UIKit/UIKit.h>

@class Blog;

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (RemoveQuickStart)


/// Displays an action sheet with an option to remove current quickstart tours from the provided blog.
/// Displayed as an action sheet on iPhone and as a popover on iPad
/// @param blog Blog to remove quickstart from
- (void)removeQuickStartFromBlog:(Blog *)blog;

@end

NS_ASSUME_NONNULL_END
