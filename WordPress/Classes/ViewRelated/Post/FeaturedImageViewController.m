#import "FeaturedImageViewController.h"

#import "Media.h"
#import "WordPress-Swift.h"
#import <WordPressUI/WordPressUI.h>


@interface FeaturedImageViewController ()

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) UIImage *image;

@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) UIBarButtonItem *removeButton;

@end

@implementation FeaturedImageViewController

@dynamic url;
@dynamic image;

#pragma mark - Life Cycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = NSLocalizedString(@"Featured Image", @"Title for the Featured Image view");
    self.view.backgroundColor = [UIColor murielBasicBackground];
    self.navigationItem.leftBarButtonItems = @[self.doneButton];
    self.navigationItem.rightBarButtonItems = @[self.removeButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Super class will hide the status bar by default
    [self hideBars:NO animated:NO];

    // Called here to be sure the view is complete in case we need to present a popover from the toolbar.
    [self loadImage];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

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
            self.view.backgroundColor = [UIColor murielBasicBackground];
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
                                    if (self.delegate) {
                                        [self.delegate FeaturedImageViewControllerOnRemoveImageButtonPressed:self];
                                    }
                                }];
    alertController.popoverPresentationController.barButtonItem = self.removeButton;
    [self presentViewController:alertController animated:YES completion:nil];

}

- (void)confirmFeaturedImage
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


@end
