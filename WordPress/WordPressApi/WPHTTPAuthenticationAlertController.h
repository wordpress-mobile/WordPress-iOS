#import <UIKit/UIKit.h>

@interface WPHTTPAuthenticationAlertController : UIAlertController
+ (void)presentWithChallenge:(NSURLAuthenticationChallenge *)challenge;
@end
