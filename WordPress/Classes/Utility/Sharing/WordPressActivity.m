#import "WordPressActivity.h"
#import "EditPostViewController.h"

@interface WordPressActivity () <WPEditorViewControllerDelegate>

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *summary;
@property (nonatomic, strong) NSString *tags;

@end

@implementation WordPressActivity

- (NSString *)activityTitle {
    return @"WordPress";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"WordPress-share"];
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

    __weak __typeof(self) weakSelf = self;
    EditPostViewController * editPostViewController = [[EditPostViewController alloc] initWithTitle:self.title andContent:content andTags:self.tags andImage:nil];
    editPostViewController.onClose = ^(){
        [weakSelf activityDidFinish:YES];
    };
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:editPostViewController];
    navController.modalPresentationStyle = UIModalPresentationCurrentContext;
    navController.navigationBar.translucent = NO;
    navController.restorationIdentifier = WPEditorNavigationRestorationID;
    navController.restorationClass = [EditPostViewController class];

    return navController;
}

@end
