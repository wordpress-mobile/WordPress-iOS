#import <UIKit/UIKit.h>

@class ReaderPost;
@interface ReaderBrowseSiteViewController : UIViewController

- (instancetype)initWithPost:(ReaderPost *)post;

- (instancetype)initWithSiteID:(NSNumber *)siteID
                       siteURL:(NSString *)siteURL
                       isWPcom:(BOOL)isWPcom;
@end
