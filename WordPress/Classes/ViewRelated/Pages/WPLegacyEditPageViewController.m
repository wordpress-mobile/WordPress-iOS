#import "WPLegacyEditPageViewController.h"
#import "AbstractPost.h"
#import "PageSettingsViewController.h"
#import "PostService.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "WordPress-Swift.h"

@implementation WPLegacyEditPageViewController

- (id)initWithDraftForLastUsedBlog
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:context];
    
    Blog *blog = [blogService lastUsedOrFirstBlog];
    AbstractPost *page = [postService createDraftPageForBlog:blog];

    return [self initWithPost:page];
}

- (AbstractPost *)createNewDraftForBlog:(Blog *)blog
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    PostService *postService = [[PostService alloc] initWithManagedObjectContext:context];

    AbstractPost *page = [postService createDraftPageForBlog:blog];
    return page;
}

- (void)didSaveNewPost {
    // Noop.
    // The superclass triggers a tab switch with this method which we don't want for pages.
}

- (Class)classForSettingsViewController
{
    return [PageSettingsViewController class];
}

@end
