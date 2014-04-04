#import "EditPageViewController.h"
#import "EditPostViewController_Internal.h"
#import "AbstractPost.h"
#import "PageSettingsViewController.h"

@implementation EditPageViewController

- (id)initWithPost:(AbstractPost *)aPost
{
    self = [super initWithPost:aPost];
    if (self) {
        self.statsPrefix = @"Page Detail";
    }
    return self;
}

- (NSString *)editorTitle {
    NSString *title = @"";
    if (self.editMode == EditPostViewControllerModeNewPost) {
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

- (void)didSaveNewPost {
    // Noop.
    // The superclass triggers a tab switch with this method which we don't want for pages.
}

- (Class)classForSettingsViewController {
    return [PageSettingsViewController class];
}

- (void)geotagNewPost {
    // Noop. Pages do not support geolocation.
}

@end
