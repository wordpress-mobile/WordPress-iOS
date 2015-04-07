#import "WPLegacyEditPageViewController.h"
#import "WPLegacyEditPostViewController_Internal.h"
#import "AbstractPost.h"
#import "PageSettingsViewController.h"
#import "PostService.h"
#import "BlogService.h"
#import "Page.h"
#import "ContextManager.h"

@implementation WPLegacyEditPageViewController

- (id)initWithDraftForLastUsedBlog
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    
    Blog *blog = [blogService lastUsedOrFirstBlog];
    return [self initWithPost:[PostService createDraftPageInMainContextForBlog:blog]];
}

- (AbstractPost *)createNewDraftForBlog:(Blog *)blog
{
    return [PostService createDraftPageInMainContextForBlog:blog];
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

- (Class)classForSettingsViewController
{
    return [PageSettingsViewController class];
}

- (void)geotagNewPost {
    // Noop. Pages do not support geolocation.
}

@end
