#import "BlogSyncService.h"
#import "ContextManager.h"
#import "BlogService.h"
#import "Blog.h"
#import "Blog+Jetpack.h"

#import <NSString+XMLExtensions.h>

@implementation BlogSyncService

- (void)syncBlogsForAccount:(WPAccount *)account success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];
    [blogService syncBlogsForAccount:account success:success failure:failure];
}

- (void)syncBlogForAccount:(WPAccount *)account username:(NSString *)username password:(NSString *)password xmlrpc:(NSString *)xmlrpc options:(NSDictionary *)options needsJetpack:(void(^)(NSNumber *))needsJetpack finishedSync:(void(^)())finishedSync;
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:context];

    NSString *blogName = [options stringForKeyPath:@"blog_title.value"];
    NSString *url = [options stringForKeyPath:@"home_url.value"];
    if (!url) {
        url = [options stringForKeyPath:@"blog_url.value"];
    }
    Blog *blog = [blogService findBlogWithXmlrpc:xmlrpc inAccount:account];
    if (!blog) {
        blog = [blogService createBlogWithAccount:account];
        if (url) {
            blog.url = url;
        }
        if (blogName) {
            blog.blogName = [blogName stringByDecodingXMLCharacters];
        }
    }
    blog.xmlrpc = xmlrpc;
    blog.options = options;
    [blog dataSave];
    [blogService syncBlog:blog success:nil failure:nil];

    if ([blog hasJetpack]) {
        if ([blog hasJetpackAndIsConnectedToWPCom]) {
            if (needsJetpack != nil) {
                needsJetpack(blog.blogID);
            }
        } else {
            [WPAnalytics track:WPAnalyticsStatAddedSelfHostedSiteButJetpackNotConnectedToWPCom];
            if (finishedSync != nil) {
                finishedSync();
            }
        }
    } else {
        if (finishedSync != nil) {
            finishedSync();
        }
    }

    [WPAnalytics track:WPAnalyticsStatAddedSelfHostedSite];
    [WPAnalytics track:WPAnalyticsStatSignedIn withProperties:@{ @"dotcom_user" : @(NO) }];
    [WPAnalytics refreshMetadata];
}


@end
