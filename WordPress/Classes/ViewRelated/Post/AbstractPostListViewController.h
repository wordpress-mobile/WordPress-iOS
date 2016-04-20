#import <UIKit/UIKit.h>

@class Blog;

@interface AbstractPostListViewController : UIViewController

@property (nonatomic, strong) Blog* __nullable blog;

/**
 *  Sets the filtering of this VC to show the posts with the specified status.
 *
 *  @param      status      The status of the type of post we want to show.
 */
- (void)setFilterWithPostStatus:(NSString* __nonnull)status;

@end
