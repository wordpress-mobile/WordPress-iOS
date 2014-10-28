#import "BlogService.h"
#import "Blog.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "WPError.h"
#import "Comment.h"
#import "Post.h"
#import "Page.h"
#import "Media.h"
#import "CategoryService.h"
#import "CommentService.h"
#import "PostService.h"
#import "BlogServiceRemote.h"
#import "BlogServiceRemoteXMLRPC.h"
#import "BlogServiceRemoteREST.h"
#import "AccountServiceRemote.h"
#import "AccountServiceRemoteREST.h"
#import "AccountServiceRemoteXMLRPC.h"
#import "RemoteBlog.h"
#import "NSString+XMLExtensions.h"

@interface BlogService ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

NSString *const LastUsedBlogURLDefaultsKey = @"LastUsedBlogURLDefaultsKey";

@implementation BlogService

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _managedObjectContext = context;
    }

    return self;
}

- (Blog *)blogByBlogId:(NSNumber *)blogID
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Blog"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"blogID == %@", blogID];

    fetchRequest.predicate = predicate;

    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

    if (error) {
        DDLogError(@"Error while fetching Blog by blogID: %@", error);
        return nil;
    }

    return [results firstObject];
}

- (void)flagBlogAsLastUsed:(Blog *)blog
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:blog.url forKey:LastUsedBlogURLDefaultsKey];
    [defaults synchronize];
}

- (Blog *)lastUsedOrFirstBlog
{
    Blog *blog = [self lastUsedBlog];

    if (!blog) {
        blog = [self firstBlog];
    }

    return blog;
}

- (Blog *)lastUsedOrFirstWPcomBlog
{
    Blog *blog = [self lastUsedBlog];

    if (![blog isWPcom]) {
        blog = [self firstWPComBlog];
    }

    return blog;
}

- (Blog *)lastUsedBlog
{
    // Try to get the last used blog, if there is one.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *url = [defaults stringForKey:LastUsedBlogURLDefaultsKey];
    if (!url) {
        // Check for the old key and migrate the value if it exists.
        // TODO: We can probably discard this in the 4.2 release.
        NSString *oldKey = @"EditPostViewControllerLastUsedBlogURL";
        url = [defaults stringForKey:oldKey];
        if (url) {
            [defaults setObject:url forKey:LastUsedBlogURLDefaultsKey];
            [defaults removeObjectForKey:oldKey];
            [defaults synchronize];
        }
    }

    if (!url) {
        return nil;
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Blog"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"visible = YES AND url = %@", url];
    [fetchRequest setPredicate:predicate];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"blogName" ascending:YES]];
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (error) {
        DDLogError(@"Couldn't fetch blogs: %@", error);
        return nil;
    }

    if ([results count] == 0) {
        // Blog might have been removed from the app. Clear the key.
        [defaults removeObjectForKey:LastUsedBlogURLDefaultsKey];
        [defaults synchronize];
        return nil;
    }

    return [results firstObject];
}

- (Blog *)firstBlog
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"visible = YES"];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Blog"];
    [fetchRequest setPredicate:predicate];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"blogName" ascending:YES]];
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

    if (error) {
        DDLogError(@"Couldn't fetch blogs: %@", error);
        return nil;
    }

    return [results firstObject];
}

- (Blog *)firstWPComBlog
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account.isWpcom = YES AND visible = YES"];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Blog"];
    [fetchRequest setPredicate:predicate];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"blogName" ascending:YES]];
    NSError *error = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];

    if (error) {
        DDLogError(@"Couldn't fetch blogs: %@", error);
        return nil;
    }

    return [results firstObject];
}

- (void)syncBlogsForAccount:(WPAccount *)account success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    DDLogMethod();

    id<AccountServiceRemote> remote = [self remoteForAccount:account];
    [remote getBlogsWithSuccess:^(NSArray *blogs) {
        [self.managedObjectContext performBlock:^{
            [self mergeBlogs:blogs withAccount:account completion:success];
        }];
    } failure:^(NSError *error) {
        DDLogError(@"Error syncing blogs: %@", error);

        if (failure) {
            failure(error);
        }
    }];
}

- (void)syncOptionsForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncOptionsForBlog:blog success:[self optionsHandlerWithBlog:blog completionHandler:success] failure:failure];
}

- (void)syncPostFormatsForBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncPostFormatsForBlog:blog success:[self postFormatsHandlerWithBlog:blog completionHandler:success] failure:failure];
}

- (void)syncBlog:(Blog *)blog success:(void (^)())success failure:(void (^)(NSError *error))failure
{
    id<BlogServiceRemote> remote = [self remoteForBlog:blog];
    [remote syncOptionsForBlog:blog success:[self optionsHandlerWithBlog:blog completionHandler:nil] failure:^(NSError *error) {
        DDLogError(@"Failed syncing options for blog %@: %@", blog.url, error);
    }];
    [remote syncPostFormatsForBlog:blog success:[self postFormatsHandlerWithBlog:blog completionHandler:nil] failure:^(NSError *error) {
        DDLogError(@"Failed syncing post formats for blog %@: %@", blog.url, error);
    }];

    CommentService *commentService = [[CommentService alloc] initWithManagedObjectContext:self.managedObjectContext];
    // Right now, none of the callers care about the results of the sync
    // We're ignoring the callbacks here but this needs refactoring
    [commentService syncCommentsForBlog:blog success:nil failure:nil];

    CategoryService *categoryService = [[CategoryService alloc] initWithManagedObjectContext:self.managedObjectContext];
    [categoryService syncCategoriesForBlog:blog success:nil failure:nil];

    PostService *postService = [[PostService alloc] initWithManagedObjectContext:self.managedObjectContext];
    // FIXME: this is hacky, but XML-RPC doesn't support fetching "any" type of post
    // Ideally we'd do a multicall and fetch both posts/pages, but it's out of scope for this commit
    if (blog.restApi) {
        [postService syncPostsOfType:PostServiceTypeAny forBlog:blog success:nil failure:nil];
    } else {
        [postService syncPostsOfType:PostServiceTypePost forBlog:blog success:nil failure:nil];
        [postService syncPostsOfType:PostServiceTypePage forBlog:blog success:nil failure:nil];
    }
}

- (void)checkVideoPressEnabledForBlog:(Blog *)blog success:(void (^)(BOOL enabled))success failure:(void (^)(NSError *error))failure
{
    if (!blog.isWPcom) {
        if (success) success(YES);
        return;
    }
    NSArray *parameters = [blog getXMLRPCArgsWithExtra:nil];
    WPXMLRPCRequest *request = [blog.api XMLRPCRequestWithMethod:@"wpcom.getFeatures" parameters:parameters];
    WPXMLRPCRequestOperation *operation = [blog.api XMLRPCRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        BOOL videoEnabled = YES;
        if (([responseObject isKindOfClass:[NSDictionary class]]) && ([responseObject objectForKey:@"videopress_enabled"] != nil)) {
            videoEnabled = [[responseObject objectForKey:@"videopress_enabled"] boolValue];
        } else {
            videoEnabled = YES;
        }

        if (success) {
            success(videoEnabled);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        DDLogError(@"Error while checking if VideoPress is enabled: %@", error);

        if (failure) {
            failure(error);
        }
    }];
    [blog.api enqueueXMLRPCRequestOperation:operation];
}

- (NSInteger)blogCountForAllAccounts
{
    return [self blogCountWithPredicate:nil];
}

- (NSInteger)blogCountSelfHosted
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account.isWpcom = %@" argumentArray:@[@(NO)]];
    return [self blogCountWithPredicate:predicate];
}

- (NSInteger)blogCountVisibleForAllAccounts
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"visible = %@" argumentArray:@[@(YES)]];
    return [self blogCountWithPredicate:predicate];
}

- (NSArray *)blogsForAllAccounts
{
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"blogName" ascending:YES];

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:self.managedObjectContext]];
    [request setSortDescriptors:@[sortDescriptor]];

    NSError *error;
    NSArray *blogs = [self.managedObjectContext executeFetchRequest:request error:&error];

    if (error) {
        DDLogError(@"Error while retrieving all blogs");
        return nil;
    }

    return blogs;
}

///--------------------
/// @name Blog creation
///--------------------

- (Blog *)findBlogWithXmlrpc:(NSString *)xmlrpc inAccount:(WPAccount *)account
{
    NSSet *foundBlogs = [account.blogs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"xmlrpc like %@", xmlrpc]];
    if ([foundBlogs count] == 1) {
        return [foundBlogs anyObject];
    }

    // If more than one blog matches, return the first and delete the rest
    if ([foundBlogs count] > 1) {
        Blog *blogToReturn = [foundBlogs anyObject];
        for (Blog *b in foundBlogs) {
            // Choose blogs with URL not starting with https to account for a glitch in the API in early 2014
            if (!([b.url hasPrefix:@"https://"])) {
                blogToReturn = b;
                break;
            }
        }

        for (Blog *b in foundBlogs) {
            if (!([b isEqual:blogToReturn])) {
                [self.managedObjectContext deleteObject:b];
            }
        }

        return blogToReturn;
    }
    return nil;
}

- (Blog *)createBlogWithAccount:(WPAccount *)account
{
    Blog *blog = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([Blog class]) inManagedObjectContext:self.managedObjectContext];
    blog.account = account;
    return blog;
}

#pragma mark - Private methods

- (void)mergeBlogs:(NSArray *)blogs withAccount:(WPAccount *)account completion:(void (^)())completion
{
    NSSet *remoteSet = [NSSet setWithArray:[blogs valueForKey:@"xmlrpc"]];
    NSSet *localSet = [account.blogs valueForKey:@"xmlrpc"];
    NSMutableSet *toDelete = [localSet mutableCopy];
    [toDelete minusSet:remoteSet];

    if ([toDelete count] > 0) {
        for (Blog *blog in account.blogs) {
            if ([toDelete containsObject:blog.xmlrpc]) {
                [self.managedObjectContext deleteObject:blog];
            }
        }
    }

    // Go through each remote incoming blog and make sure we're up to date with titles, etc.
    // Also adds any blogs we don't have
    for (RemoteBlog *remoteBlog in blogs) {
        Blog *blog = [self findBlogWithXmlrpc:remoteBlog.xmlrpc inAccount:account];
        if (!blog) {
            blog = [self createBlogWithAccount:account];
            blog.xmlrpc = remoteBlog.xmlrpc;
        }
        blog.url = remoteBlog.url;
        blog.blogName = [remoteBlog.title stringByDecodingXMLCharacters];
        blog.blogID = remoteBlog.ID;
    }

    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

    if (completion != nil) {
        dispatch_async(dispatch_get_main_queue(), completion);
    }
}

- (id<BlogServiceRemote>)remoteForBlog:(Blog *)blog
{
    id<BlogServiceRemote> remote;
    if (blog.restApi) {
        remote = [[BlogServiceRemoteREST alloc] initWithApi:blog.restApi];
    } else {
        remote = [[BlogServiceRemoteXMLRPC alloc] initWithApi:blog.api];
    }

    return remote;
}

- (id<AccountServiceRemote>)remoteForAccount:(WPAccount *)account
{
    if (account.restApi) {
        return [[AccountServiceRemoteREST alloc] initWithApi:account.restApi];
    }

    return [[AccountServiceRemoteXMLRPC alloc] initWithApi:account.xmlrpcApi];
}

- (NSInteger)blogCountWithPredicate:(NSPredicate *)predicate
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Blog" inManagedObjectContext:self.managedObjectContext]];
    [request setIncludesSubentities:NO];

    if (predicate) {
        [request setPredicate:predicate];
    }

    NSError *err;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:request error:&err];
    if (count == NSNotFound) {
        count = 0;
    }
    return count;
}

- (NSUInteger)countForSyncedPostsWithEntityName:(NSString *)entityName forBlog:(Blog *)blog
{
    __block NSUInteger count = 0;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(remoteStatusNumber == %@) AND (postID != NULL) AND (original == NULL) AND (blog == %@)",
                              [NSNumber numberWithInt:AbstractPostRemoteStatusSync], blog];
    [request setPredicate:predicate];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"date_created_gmt" ascending:YES];
    [request setSortDescriptors:@[sortDescriptor]];
    request.includesSubentities = NO;
    request.resultType = NSCountResultType;

    [self.managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        count = [self.managedObjectContext countForFetchRequest:request error:&error];
    }];
    return count;
}

#pragma mark - Completion handlers

- (OptionsHandler)optionsHandlerWithBlog:(Blog *)blog completionHandler:(void (^)(void))completion
{
    NSManagedObjectID *blogObjectID = blog.objectID;
    return ^void(NSDictionary *options) {
        [self.managedObjectContext performBlock:^{
            Blog *blogInContext = (Blog *)[self.managedObjectContext existingObjectWithID:blogObjectID error:nil];
            if (blogInContext) {
                blog.options = [NSDictionary dictionaryWithDictionary:options];
                NSString *minimumVersion = @"3.6";
                float version = [[blog version] floatValue];
                if (version < [minimumVersion floatValue]) {
                    if (blog.lastUpdateWarning == nil || [blog.lastUpdateWarning floatValue] < [minimumVersion floatValue]) {
                        // TODO :: Remove UI call from service layer
                        [WPError showAlertWithTitle:NSLocalizedString(@"WordPress version too old", @"")
                                            message:[NSString stringWithFormat:NSLocalizedString(@"The site at %@ uses WordPress %@. We recommend to update to the latest version, or at least %@", @""), [blog hostname], [blog version], minimumVersion]];
                        blog.lastUpdateWarning = minimumVersion;
                    }
                }

                [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            }
            if (completion) {
                completion();
            }
        }];
    };
}

- (PostFormatsHandler)postFormatsHandlerWithBlog:(Blog *)blog completionHandler:(void (^)(void))completion
{
    NSManagedObjectID *blogObjectID = blog.objectID;
    return ^void(NSDictionary *postFormats) {
        [self.managedObjectContext performBlock:^{
            Blog *blogInContext = (Blog *)[self.managedObjectContext existingObjectWithID:blogObjectID error:nil];
            if (blogInContext) {
                NSDictionary *formats = postFormats;
                if (![formats objectForKey:@"standard"]) {
                    NSMutableDictionary *mutablePostFormats = [formats mutableCopy];
                    mutablePostFormats[@"standard"] = NSLocalizedString(@"Standard", @"Standard post format label");
                    formats = [NSDictionary dictionaryWithDictionary:mutablePostFormats];
                }
                blog.postFormats = formats;

                [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            }

            if (completion) {
                completion();
            }
        }];
    };
}

- (NSTimeZone *)timeZoneForBlog:(Blog *)blog
{
    NSString *timeZoneName = [blog.options stringForKey:@"timezone"];
    NSNumber *gmtOffSet = [blog.options numberForKey:@"gmt_offset"];
    id optionValue = [blog getOptionValue:@"time_zone"];
    
    NSTimeZone *timeZone = nil;
    if (timeZoneName.length > 0) {
        timeZone = [NSTimeZone timeZoneWithName:timeZoneName];
    }
    
    if (!timeZone && gmtOffSet != nil) {
        timeZone = [NSTimeZone timeZoneForSecondsFromGMT:(gmtOffSet.floatValue * 60.0 * 60.0)];
    }
    
    if (!timeZone && optionValue != nil) {
        NSInteger timeZoneOffsetSeconds = [optionValue floatValue] * 60.0 * 60.0;
        timeZone = [NSTimeZone timeZoneForSecondsFromGMT:timeZoneOffsetSeconds];
    }
    
    if (!timeZone) {
        timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    }
    
    return timeZone;
}

@end
