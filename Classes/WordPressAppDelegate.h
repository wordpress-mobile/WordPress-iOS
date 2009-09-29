#import <UIKit/UIKit.h>
#import "Constants.h"

@class BlogDataManager;

@interface WordPressAppDelegate : NSObject <UIApplicationDelegate> {
@private
    BlogDataManager *dataManager;

    IBOutlet UIWindow *window;
    IBOutlet UINavigationController *navigationController;
    BOOL connectionStatus;
    BOOL alertRunning;

    UIImageView *splashView;
	NSMutableData *statsData;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, getter = isAlertRunning) BOOL alertRunning;

+ (WordPressAppDelegate *)sharedWordPressApp;

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)showErrorAlert:(NSString *)message;
- (void)storeCurrentBlog;
- (void)resetCurrentBlogInUserDefaults;
- (BOOL)shouldLoadBlogFromUserDefaults;
- (void)setAutoRefreshMarkers;
@end
