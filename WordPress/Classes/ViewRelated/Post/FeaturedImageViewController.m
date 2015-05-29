#import "FeaturedImageViewController.h"

#import "Post.h"
#import "Media.h"

@interface FeaturedImageViewController () <UIActionSheetDelegate>

@property (nonatomic, strong) UIBarButtonItem *deleteButton;
@property (nonatomic, strong) AbstractPost *post;
@property (nonatomic, strong) UIBarButtonItem *activityItem;

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

    [self setupToolbar];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.navigationController.toolbarHidden) {
        [self.navigationController setToolbarHidden:NO animated:YES];
    }

    for (UIView *view in self.navigationController.toolbar.subviews) {
        [view setExclusiveTouch:YES];
    }

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

- (void)setupToolbar
{
    UIToolbar *toolbar = self.navigationController.toolbar;
    toolbar.barTintColor = [WPStyleGuide littleEddieGrey];
    toolbar.translucent = NO;
    toolbar.barStyle = UIBarStyleDefault;

    if ([self.toolbarItems count] > 0) {
        return;
    }

    self.deleteButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-comments-trash"] style:UIBarButtonItemStylePlain target:self action:@selector(removeFeaturedImage)];

    self.deleteButton.tintColor = [WPStyleGuide readGrey];
    self.deleteButton.accessibilityIdentifier = @"Remove Featured Image";
    self.deleteButton.accessibilityLabel = NSLocalizedString(@"Remove Featured Image", @"Accessibility  Label for the Remove Feature Image icon. Tapping will show a confirmation screen for removing the feature image from the post.");
    
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityView startAnimating];
    self.activityItem = [[UIBarButtonItem alloc] initWithCustomView:activityView];

    [self showActivityView:NO];
}

- (void)hideBars:(BOOL)hide animated:(BOOL)animated
{
    [super hideBars:hide animated:animated];

    if (self.navigationController.navigationBarHidden != hide) {
        [self.navigationController setNavigationBarHidden:hide animated:animated];
    }

    if (self.navigationController.toolbarHidden != hide) {
        [self.navigationController setToolbarHidden:hide animated:animated];
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

- (void)showActivityView:(BOOL)show
{
    UIBarButtonItem *leftFixedSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *rightFixedSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *centerFlexSpacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

    leftFixedSpacer.width = -2.0f;
    rightFixedSpacer.width = -5.0f;

    if (show) {
        self.toolbarItems = @[leftFixedSpacer, self.deleteButton, centerFlexSpacer, self.activityItem, rightFixedSpacer];
    } else {
        self.toolbarItems = @[leftFixedSpacer, self.deleteButton];
    }
}

#pragma mark - Action Methods

- (void)handleImageTapped:(UITapGestureRecognizer *)tgr
{
    BOOL hide = !self.navigationController.navigationBarHidden;
    [self hideBars:hide animated:YES];
}

- (void)removeFeaturedImage
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Remove this Featured Image?", @"Prompt when removing a featured image from a post")
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", "Cancel a prompt")
                                               destructiveButtonTitle:NSLocalizedString(@"Remove", @"Remove an image/posts/etc")
                                                    otherButtonTitles:nil];
    [actionSheet showFromBarButtonItem:self.deleteButton animated:YES];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)acSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self.post setFeaturedImage:nil];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end
