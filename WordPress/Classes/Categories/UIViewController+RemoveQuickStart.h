#import <UIKit/UIKit.h>

@class Blog;

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (RemoveQuickStart)


/// Displays an action sheet with an option to remove current quickstart tours from the provided blog.
/// Displayed as an action sheet on iPhone and as a popover on iPad
/// @param blog Blog to remove quickstart from
/// @param sourceView View used as sourceView for the sheet's popoverPresentationController
/// @param sourceRect rect used as sourceRect for the sheet's popoverPresentationController
- (void)removeQuickStartFromBlog:(Blog *)blog sourceView:(UIView *)sourceView sourceRect:(CGRect)sourceRect;

@end

NS_ASSUME_NONNULL_END
