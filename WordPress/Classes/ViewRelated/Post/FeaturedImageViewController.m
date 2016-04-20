#import "FeaturedImageViewController.h"

#import "Post.h"
#import "Media.h"
#import "WordPress-Swift.h"

@interface FeaturedImageViewController ()

@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) UIBarButtonItem *removeButton;
@property (nonatomic, strong) AbstractPost *post;

@end

@implementation FeaturedImageViewController

#pragma mark - Life Cycle Methods

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithPost:(AbstractPost *)post
{
    self = [super initWithImage:nil andURL:[NSURL URLWithString:post.featuredImage.remoteURL]];
    if (self) {
        self.title = NSLocalizedString(@"Featured Image", @"Title for the Featured Image view");
        self.post = post;
        self.extendedLayoutIncludesOpaqueBars = YES;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItems = @[self.doneButton];
    self.navigationItem.rightBarButtonItems = @[self.removeButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Super class will hide the status bar by default
    [self hideBars:NO animated:NO];

    if (self.url) {
        if (![self.url.absoluteString isEqualToString:self.post.featuredImage.remoteURL]) {
            self.image = nil;
            self.url = [NSURL URLWithString:self.post.featuredImage.remoteURL];
        }
    }

    // Called here to be sure the view is complete in case we need to present a popover from the toolbar.
    [self loadImage];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.toolbar.translucent = NO;
}

#pragma mark - Appearance Related Methods

- (UIBarButtonItem *)doneButton
{
    if (!_doneButton) {
        _doneButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Label for confirm feature image of a post")
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(confirmFeaturedImage)];
    }
    return _doneButton;
}

- (UIBarButtonItem *)removeButton
{
    if (!_removeButton) {
        UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Remove", @"Label for the Remove Feature Image icon. Tapping will show a confirmation screen for removing the feature image from the post.")
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(removeFeaturedImage)];
        NSString *title = NSLocalizedString(@"Remove Featured Image", @"Accessibility  Label for the Remove Feature Image icon. Tapping will show a confirmation screen for removing the feature image from the post.");
        button.accessibilityLabel = title;
        button.accessibilityIdentifier = @"Remove Featured Image";
        _removeButton = button;
    }
    
    return _removeButton;
}


- (void)hideBars:(BOOL)hide animated:(BOOL)animated
{
    [super hideBars:hide animated:animated];

    if (self.navigationController.navigationBarHidden != hide) {
        [self.navigationController setNavigationBarHidden:hide animated:animated];
    }

    [self centerImage];
    [UIView animateWithDuration:0.3 animations:^{
        if (hide) {
            self.view.backgroundColor = [UIColor blackColor];
        } else {
            self.view.backgroundColor = [UIColor whiteColor];
        }
    }];
}

#pragma mark - Action Methods

- (void)handleImageTapped:(UITapGestureRecognizer *)tgr
{
    BOOL hide = !self.navigationController.navigationBarHidden;
    [self hideBars:hide animated:YES];
}

- (void)removeFeaturedImage
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Remove this Featured Image?", @"Prompt when removing a featured image from a post")
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addActionWithTitle:NSLocalizedString(@"Cancel", "Cancel a prompt")
                                  style:UIAlertActionStyleCancel
                                handler:nil];
    [alertController addActionWithTitle:NSLocalizedString(@"Remove", @"Remove an image/posts/etc")
                                  style:UIAlertActionStyleDestructive
                                handler:^(UIAlertAction *alertAction) {
                                    [self.post setFeaturedImage:nil];
                                    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
                                }];
    alertController.popoverPresentationController.barButtonItem = self.removeButton;
    [self presentViewController:alertController animated:YES completion:nil];

}

- (void)confirmFeaturedImage
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


@end
