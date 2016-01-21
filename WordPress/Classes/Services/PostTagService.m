#import "PostTagService.h"
#import "Blog.h"
#import "RemotePostTag.h"
#import "PostTag.h"
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
    [remote getTagsWithSuccess:^(NSArray <RemotePostTag *> *remoteTags) {
        [self.managedObjectContext performBlock:^{
            
            Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:blogID error:nil];
            if (!blog) {
                return;
            }
            
            NSArray *tags = [self tagsFromRemoteTags:remoteTags];
            blog.tags = [NSSet setWithArray:tags];
            
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            
            if (success) {
                success();
            }
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

- (NSArray <PostTag *> *)tagsFromRemoteTags:(NSArray<RemotePostTag *> *)remoteTags
{
    NSMutableArray *tags = [NSMutableArray arrayWithCapacity:remoteTags.count];
    for (RemotePostTag *remoteTag in remoteTags) {
        [tags addObject:[self tagFromRemoteTag:remoteTag]];
    }
    
    return [NSArray arrayWithArray:tags];
}

- (PostTag *)tagFromRemoteTag:(RemotePostTag *)remoteTag
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[PostTag entityName]
                                                         inManagedObjectContext:self.managedObjectContext];
    
    PostTag *tag = [[PostTag alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:self.managedObjectContext];
    tag.tagID = remoteTag.tagID;
    tag.name = remoteTag.name;
    tag.slug = remoteTag.slug;
    
    return tag;
}

@end
