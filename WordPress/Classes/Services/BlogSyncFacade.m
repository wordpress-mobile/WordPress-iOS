#import "BlogSyncFacade.h"
#import "CoreDataStack.h"
#import "BlogService.h"
#import "AccountService.h"
#import "Blog.h"
#import "WPAppAnalytics.h"
#import "WordPress-Swift.h"

#import <WordPressShared/NSString+XMLExtensions.h>

@import NSObject_SafeExpectations;

@implementation BlogSyncFacade

- (void)syncBlogsForAccount:(WPAccount *)account
                    success:(void (^)(void))success
                    failure:(void (^)(NSError *error))failure
{
    BlogService *blogService = [[BlogService alloc] initWithCoreDataStack:[ContextManager sharedInstance]];
    [blogService syncBlogsForAccount:account success:^{
        WP3DTouchShortcutCreator *shortcutCreator = [WP3DTouchShortcutCreator new];
        [shortcutCreator createShortcutsIf3DTouchAvailable:YES];
        if (success) {
            success();
        }
    } failure:failure];
}

- (void)syncBlogWithUsername:(NSString *)username
                    password:(NSString *)password
                      xmlrpc:(NSString *)xmlrpc
                     options:(NSDictionary *)options
                finishedSync:(void(^)(Blog *))finishedSync
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];

    NSString *blogName = [options stringForKeyPath:@"blog_title.value"];
    NSString *url = [options stringForKeyPath:@"home_url.value"];
    if (!url) {
        url = [options stringForKeyPath:@"blog_url.value"];
    }
    Blog *blog = [Blog lookupWithUsername:username xmlrpc:xmlrpc inContext:context];
    if (!blog) {
        blog = [Blog createBlankBlogInContext:context];
        if (url) {
            blog.url = url;
        }
        if (blogName) {
            blog.settings.name = [blogName stringByDecodingXMLCharacters];
        }
    }
    blog.username = username;
    blog.xmlrpc = xmlrpc;
    /*
     Note: blog.password stores the password in the keychain using username/xmlrpc,
     so let's set it after we set those
     */
    blog.password = password;
    blog.options = options;

    // HACK:Sergio Estevao (2015-08-31): Because there is no direct way to
    // know if a user has permissions to change the options we check if the blog title property is read only or not.
    if ([blog.options numberForKeyPath:@"blog_title.readonly"]) {
        blog.isAdmin = ![[blog.options numberForKeyPath:@"blog_title.readonly"] boolValue];
    }
    [[ContextManager sharedInstance] saveContextAndWait:context];

    if (blog.jetpack.isInstalled) {
        if (blog.jetpack.isConnected) {
            NSString *dotcomUsername = [blog getOptionValue:@"jetpack_user_login"];
            if (dotcomUsername) {
                // Search for a matching .com account
                WPAccount *account = [WPAccount lookupDefaultWordPressComAccountInContext:context];
                if (account) {
                    blog.account = account;
                    [WPAppAnalytics track:WPAnalyticsStatSignedInToJetpack withBlog:blog];
                }
            }
        } else {
            [WPAnalytics track:WPAnalyticsStatAddedSelfHostedSiteButJetpackNotConnectedToWPCom];
        }
    }

    if (finishedSync != nil) {
        finishedSync(blog);
    }

    WP3DTouchShortcutCreator *shortcutCreator = [WP3DTouchShortcutCreator new];
    [shortcutCreator createShortcutsIf3DTouchAvailable:YES];
    
    [WPAnalytics track:WPAnalyticsStatAddedSelfHostedSite];
    [WPAnalytics track:WPAnalyticsStatSignedIn withProperties:@{ @"dotcom_user" : @(NO) }];
    [WPAnalytics refreshMetadata];
}


@end
