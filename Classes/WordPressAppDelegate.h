#import <UIKit/UIKit.h>
#import "Constants.h"

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate> {
	IBOutlet UIWindow *window;
	IBOutlet UINavigationController *navigationController;
	BOOL alertRunning;
	
	UIImageView *splashView;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, getter=isAlertRunning) BOOL alertRunning;

+ (WordPressAppDelegate *)sharedWordPressApp;

-(void)startupAnimationDone:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)showErrorAlert:(NSString *)message;

@end
