#import "WPMainTabBarController.h"
#import "WordPressAppDelegate.h"

@interface WPMainTabBarController ()

@property (nonatomic, strong) UIButton *postButton;

@end

@implementation WPMainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *image = [UIImage imageNamed:@"icon-tab-newpost"];
    CGFloat x = CGRectGetWidth(self.view.frame) - (image.size.width + 20);
    CGFloat y = CGRectGetHeight(self.view.frame) - (image.size.height + 2);
    
    self.postButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _postButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin;
    _postButton.frame = CGRectMake(x, y, image.size.width, image.size.height);
    [_postButton setImage:image forState:UIControlStateNormal];
    [_postButton setImage:[UIImage imageNamed:@"icon-tab-newpost-highlighted"] forState:UIControlStateHighlighted];
    _postButton.contentMode = UIViewContentModeCenter;
    _postButton.clipsToBounds = NO;
    [_postButton addTarget:self action:@selector(postButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    
    // iPad in landscape orientation will end up positioning the post button in the
    // wrong place the first time viewWillAppear: is called, but not subsequent times.
    // This seems to be because the layer transform due to rotation has not yet ben applied.
    _postButton.hidden = YES;
    [self.view addSubview:_postButton];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Make sure to reposition if we rotated while hidden by a modal.
    [self positionPostButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self positionPostButton];
    // The button should be in the correct location so its safe to show.
    self.postButton.hidden = NO;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    // Hide before we rotate so the button doesn't appear momentarily out of place
    self.postButton.hidden = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self positionPostButton];
    self.postButton.hidden = NO;
}


// Position the post button over its respective tab.
// For best alignment the target tab should have an image
// that is the same size as the one used for the post button.
- (void)positionPostButton {
    
    CGRect tabFrame = CGRectZero;
    CGFloat lastX = 0;
    // Find the right most UITabBarButtonItem
    NSArray *tabBarButtonItems = self.tabBar.subviews;
    for (NSInteger i = 0; i < [tabBarButtonItems count]; i++) {
        UIView *tabBarButton = [tabBarButtonItems objectAtIndex:i];
        CGFloat x = CGRectGetMinX(tabBarButton.frame);
        if (x > lastX) {
            lastX = x;
            tabFrame = tabBarButton.frame;
        }
    }

    tabFrame = [self.view convertRect:tabFrame fromView:self.tabBar];

    // Since the button uses contentMode UIViewContentModeCenter, adjust the frame
    // to make sure we don't crop any of the image.
    CGFloat diff;
    CGSize imageSize = _postButton.imageView.image.size;
    if (tabFrame.size.height < imageSize.height) {
        diff = imageSize.height - tabFrame.size.height;
        tabFrame.size.height  = imageSize.height;
        tabFrame.origin.y -= ceilf(diff / 2.0f);
    }
    if (tabFrame.size.width < imageSize.width) {
        diff = imageSize.width - tabFrame.size.width;
        tabFrame.size.width  = imageSize.width;
        tabFrame.origin.x -= ceilf(diff / 2.0f);
    }
    
    _postButton.frame = tabFrame;
}

- (void)postButtonTapped {
    [[WordPressAppDelegate sharedWordPressApplicationDelegate] showPostTab];
}

@end
