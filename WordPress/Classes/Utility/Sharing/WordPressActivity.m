#import "WordPressActivity.h"
#import "EditPostViewController.h"

@interface WordPressActivity () <WPEditorViewControllerDelegate>

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *summary;
@property (nonatomic, strong) NSString *tags;

@end

@implementation WordPressActivity

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
            self.URL = activityItem;
		}
        if ([activityItem isKindOfClass:[NSDictionary class]]) {
            self.title = activityItem[@"title"];
            self.summary = activityItem[@"summary"];
            self.tags = activityItem[@"tags"];
        }
    }
}

-(UIViewController *)activityViewController{
    NSString * content = [self.summary stringByAppendingString:[NSString stringWithFormat:@"\n\n <a href=\"%@\">%@</a>", self.URL, self.URL]];

    EditPostViewController * editPostViewController = [[EditPostViewController alloc] initWithTitle:self.title andContent:content andTags:self.tags andImage:nil];
    editPostViewController.activityDelegate = self;

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
