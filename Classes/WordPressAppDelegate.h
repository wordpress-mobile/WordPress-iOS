#import <UIKit/UIKit.h>
#import "Constants.h"

@class BlogDataManager;

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate> {
    BlogDataManager *dataManager;

    IBOutlet UIWindow *window;
    IBOutlet UINavigationController *navigationController;
    BOOL alertRunning;

    UIImageView *splashView;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, getter = isAlertRunning) BOOL alertRunning;

+ (WordPressAppDelegate *)sharedWordPressApp;

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)showErrorAlert:(NSString *)message;

@end
