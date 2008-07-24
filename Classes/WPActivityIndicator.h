#import <UIKit/UIKit.h>


@interface WPActivityIndicator : NSObject {
	IBOutlet UIWindow *window;
}

@property (nonatomic, readonly) UIWindow *window;
+ (WPActivityIndicator *)sharedActivityIndicator;

- (void)show;
- (void)hide;

@end
