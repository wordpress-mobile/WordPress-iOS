#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class Blog, MenusService;

@interface MenusViewController : UIViewController

+ (MenusViewController *)controllerWithBlog:(Blog *)blog;

@property (nonatomic, strong, readonly) Blog *blog;
@property (nonatomic, strong, readonly) MenusService *menusService;

@end

NS_ASSUME_NONNULL_END
