#import <UIKit/UIKit.h>

@class Blog;

@interface AbstractPostListViewController : UIViewController

@property (nonatomic, strong) Blog* __nullable blog;

- (void)setFilterWithPostStatus:(NSString* __nonnull)status;

@end
