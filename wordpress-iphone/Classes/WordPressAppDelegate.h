#import <UIKit/UIKit.h>
#import "Constants.h"


@interface WordPressAppDelegate : NSObject <UIApplicationDelegate> {
	
	IBOutlet UIWindow *window;
	IBOutlet UINavigationController *navigationController;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;

+ (WordPressAppDelegate *)sharedWordPressApp;

@end

