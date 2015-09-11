#import <UIKit/UIKit.h>

@class ReaderPost;
@interface ReaderBrowseSiteViewController : UIViewController

- (instancetype)initWithSiteID:(NSNumber *)siteID
                       siteURL:(NSString *)siteURL
                       isWPcom:(BOOL)isWPcom;
@end
