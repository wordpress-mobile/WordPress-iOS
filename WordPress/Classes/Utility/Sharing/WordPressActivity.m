#import "WordPressActivity.h"
#import "EditPostViewController.h"

@interface WordPressActivity () <EditPostViewControllerDelegate>

@end

@implementation WordPressActivity {
    NSURL *_URL;
    NSString *_title;
    NSString *_summary;
    NSString *_tags;
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
        if ([activityItem isKindOfClass:[NSDictionary class]]) {
			_title = activityItem[@"title"];
            _summary = activityItem[@"summary"];
            _tags = activityItem[@"tags"];
		}
	}
}

-(UIViewController *)activityViewController{
    NSString * content = [_summary stringByAppendingString:[NSString stringWithFormat:@"\n\n <a href=\"%@\">%@</a>", _URL, _URL]];
    
    EditPostViewController * editPostViewController = [[EditPostViewController alloc] initWithTitle:_title andContent:content andTags:_tags andImage:nil];
    editPostViewController.delegate = self;
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
    navController.modalPresentationStyle = UIModalPresentationCurrentContext;
    navController.navigationBar.translucent = NO;
    navController.restorationIdentifier = WPEditorNavigationRestorationID;
    navController.restorationClass = [EditPostViewController class];
    
    return navController;
}

- (void)editPostViewDismissed {
    [self activityDidFinish:YES];
}

@end
