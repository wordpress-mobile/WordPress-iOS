#import <UIKit/UIKit.h>

@class ReaderPost;

@interface ReaderPostDetailViewController : UIViewController

@property (nonatomic, strong,  readonly) ReaderPost *post;
@property (nonatomic, assign, readwrite) BOOL shouldHideComments;

- (void)setupWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID;

+ (instancetype)detailControllerWithPost:(ReaderPost *)post;
+ (instancetype)detailControllerWithPostID:(NSNumber *)postID siteID:(NSNumber *)siteID;

@end
