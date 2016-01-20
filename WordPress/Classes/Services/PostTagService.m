#import "PostTagService.h"
#import "Blog.h"
#import "RemotePostTag.h"
#import "ContextManager.h"
#import "TaxonomyServiceRemote.h"
#import "TaxonomyServiceRemoteREST.h"
#import "TaxonomyServiceRemoteXMLRPC.h"

@implementation PostTagService

- (void)syncTagsForBlog:(Blog *)blog
                success:(void (^)())success
                failure:(void (^)(NSError *error))failure
{
    id<TaxonomyServiceRemote> remote = [self remoteForBlog:blog];
    NSManagedObjectID *blogID = blog.objectID;
    [remote getTagsWithSuccess:^(NSArray <RemotePostTag *> *tags) {
        [self.managedObjectContext performBlock:^{
            Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:blogID error:nil];
            if (!blog) {
                return;
            }
            
            // make and sync the PostTags to the blog
        }];
    } failure:failure];
}

#pragma mark - helpers

- (id<TaxonomyServiceRemote>)remoteForBlog:(Blog *)blog {
    if (blog.restApi) {
        return [[TaxonomyServiceRemoteREST alloc] initWithApi:blog.restApi siteID:blog.dotComID];
    } else {
        return [[TaxonomyServiceRemoteXMLRPC alloc] initWithApi:blog.api username:blog.username password:blog.password];
    }
}


@end
