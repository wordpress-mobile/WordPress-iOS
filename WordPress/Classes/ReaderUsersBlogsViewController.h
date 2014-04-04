#import <UIKit/UIKit.h>

@class Blog;

@protocol ReaderUsersBlogsDelegate <NSObject>
- (void)userDidSelectBlog:(Blog *)blog;
@end

@interface ReaderUsersBlogsViewController : UIViewController
@property (nonatomic, weak) id<ReaderUsersBlogsDelegate>delegate;
@end