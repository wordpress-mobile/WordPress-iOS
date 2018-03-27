#import "BlogSyncFacade.h"
#import "ContextManager.h"
#import "BlogService.h"
#import "AccountService.h"
#import "Blog.h"
#import "WPAppAnalytics.h"
#import "WordPress-Swift.h"

#import <WordPressShared/NSString+XMLExtensions.h>

@implementation BlogSyncFacade

- (void)syncBlogsForAccount:(WPAccount *)account
                    success:(void (^)(void))success
                    failure:(void (^)(NSError *error))failure
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
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
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];

    NSString *blogName = [options stringForKeyPath:@"blog_title.value"];
    NSString *url = [options stringForKeyPath:@"home_url.value"];
    if (!url) {
        url = [options stringForKeyPath:@"blog_url.value"];
    }
    Blog *blog = [blogService findBlogWithXmlrpc:xmlrpc andUsername:username];
    if (!blog) {
        blog = [blogService createBlogWithAccount:nil];
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
                AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
                WPAccount *account = [accountService findAccountWithUsername:dotcomUsername];
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
