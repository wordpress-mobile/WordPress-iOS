#import <UIKit/UIKit.h>
#import "WordPressAppDelegate.h"

int main(int argc, char *argv[]) {
	@autoreleasepool {
        Class appDelegateClass = NSClassFromString(@"TestingAppDelegate");
        if (!appDelegateClass) {
            appDelegateClass = [WordPressAppDelegate class];
        }

        return UIApplicationMain(argc, argv, nil, NSStringFromClass(appDelegateClass));
	}
}
