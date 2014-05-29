#import "WordPressActivity.h"
#import "EditPostViewController.h"

@implementation WordPressActivity {
    NSURL *_URL;
}

- (UIImage *)activityImage {
	return [UIImage imageNamed:@"sidebar-logo"];
}

- (NSString *)activityTitle {
	return @"WordPress";
}

- (NSString *)activityType {
	return NSStringFromClass([self class]);
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
	for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:activityItem]) {
			return YES;
		}
	}
    
	return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
	for (id activityItem in activityItems) {
		if ([activityItem isKindOfClass:[NSURL class]]) {
			_URL = activityItem;
		}
	}
}

-(UIViewController *)activityViewController{
    EditPostViewController * editPostViewController = [[EditPostViewController alloc] initWithTitle:@"" andContent:[_URL absoluteString] andTags:@"" andImage:nil];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
    navController.modalPresentationStyle = UIModalPresentationCurrentContext;
    navController.navigationBar.translucent = NO;
    navController.restorationIdentifier = WPEditorNavigationRestorationID;
    navController.restorationClass = [EditPostViewController class];
    
    return navController;
}

- (void)finishedSharing:(BOOL)shared {
    [self activityDidFinish:shared];
}

@end
