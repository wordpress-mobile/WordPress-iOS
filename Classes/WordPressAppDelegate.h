#import <UIKit/UIKit.h>
#import "Constants.h"


@interface WordPressAppDelegate : NSObject <UIApplicationDelegate> {
	
	IBOutlet UIWindow *window;
	IBOutlet UINavigationController *navigationController;
	BOOL alertRunning;
	NSMutableData *statsData;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (nonatomic, getter=isAlertRunning) BOOL alertRunning;

+ (WordPressAppDelegate *)sharedWordPressApp;

@end

