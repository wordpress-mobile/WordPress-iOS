#import <UIKit/UIKit.h>
#import "ReaderPostsViewController.h"

@class ReaderPost;

@interface ReaderPostDetailViewController : UIViewController

@property (nonatomic, assign) ReaderViewStyle readerViewStyle;
@property (nonatomic, strong,  readonly) ReaderPost *post;
@property (nonatomic, assign, readwrite) BOOL shouldHideComments;

- (void)setupWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID;

+ (instancetype)detailControllerWithPost:(ReaderPost *)post;
+ (instancetype)detailControllerWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID;

@end
