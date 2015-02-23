#import "EditPageViewController.h"
#import "AbstractPost.h"
#import "ContextManager.h"
#import "PostService.h"
#import "Page.h"
#import "Blog.h"
#import "PageSettingsViewController.h"
#import <AMPopTip/AMPopTip.h>

@implementation EditPageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.titlePlaceholderText = NSLocalizedString(@"Page title", @"Placeholder text for the title field on Pages screen.");
}

- (NSString *)editorTitle
{
    NSString *title = @"";
    if (self.ownsPost) {
        title = NSLocalizedString(@"New Page", @"New Page Editor screen title.");
    } else {
        if ([self.post.postTitle length] > 0) {
            title = self.post.postTitle;
        } else {
            title = NSLocalizedString(@"Edit Page", @"Page Editor screen title.");
        }
    }
    self.navigationItem.backBarButtonItem.title = title;
    return title;
}

- (void)didSaveNewPost
{
    // Noop.
    // The superclass triggers a tab switch with this method which we don't want for pages.
}

- (Class)classForSettingsViewController
{
    return [PageSettingsViewController class];
}

- (void)geotagNewPost
{
    // Noop. Pages do not support geolocation.
}

- (AbstractPost *)createNewDraftForBlog:(Blog *)blog {
    return [PostService createDraftPageInMainContextForBlog:blog];
}

#pragma mark - Onboarding

- (void)showOnboardingTips
{
    AMPopTip *popTip = [AMPopTip popTip];
    CGFloat xValue = IS_IPAD ? CGRectGetMaxX(self.view.frame)-NavigationBarButtonRect.size.width-20.0 : CGRectGetMaxX(self.view.frame)-NavigationBarButtonRect.size.width-10.0;
    CGRect targetFrame = CGRectMake(xValue, 0.0, NavigationBarButtonRect.size.width, 0.0);
    [[AMPopTip appearance] setFont:[WPStyleGuide regularTextFont]];
    [[AMPopTip appearance] setTextColor:[UIColor whiteColor]];
    [[AMPopTip appearance] setPopoverColor:[WPStyleGuide littleEddieGrey]];
    [[AMPopTip appearance] setArrowSize:CGSizeMake(12.0, 8.0)];
    [[AMPopTip appearance] setEdgeMargin:5.0];
    [[AMPopTip appearance] setDelayIn:0.5];
    UIEdgeInsets insets = {6,5,6,5};
    [[AMPopTip appearance] setEdgeInsets:insets];
    popTip.shouldDismissOnTap = YES;
    popTip.shouldDismissOnTapOutside = YES;
    [popTip showText:NSLocalizedString(@"Tap to edit page", @"Tooltip for the button that allows the user to edit the current page.")
           direction:AMPopTipDirectionDown
            maxWidth:200
              inView:self.view
           fromFrame:targetFrame
            duration:3];
}

@end
