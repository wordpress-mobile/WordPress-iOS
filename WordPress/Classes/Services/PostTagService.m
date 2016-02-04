#import "PostTagService.h"
#import "Blog.h"
#import "RemotePostTag.h"
#import "PostTag.h"
#import "ContextManager.h"
#import "TaxonomyServiceRemote.h"
#import "TaxonomyServiceRemoteREST.h"
#import "TaxonomyServiceRemoteXMLRPC.h"
#import "RemoteTaxonomyPaging.h"

@interface PostTagService ()

@property (nonatomic, strong) RemoteTaxonomyPaging *remotePaging;

@end

static void logErrorForRetrievingBlog(Blog *blog, NSError *error)
{
    NSString *message = @"Could not retrieve blog from context";
    if (error) {
        message = [NSString stringWithFormat:@"%@ with error: %@", message, error];
    }
    DDLogError(message);
};

@implementation PostTagService

- (void)syncTagsForBlog:(Blog *)blog
                success:(void (^)())success
                failure:(void (^)(NSError *error))failure
{
    id<TaxonomyServiceRemote> remote = [self remoteForBlog:blog];
    NSManagedObjectID *blogObjectID = blog.objectID;
    [remote getTagsWithSuccess:^(NSArray <RemotePostTag *> *remoteTags) {
        [self.managedObjectContext performBlock:^{
            NSError *error;
            Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:blogObjectID error:&error];
            if (!blog || error) {
                logErrorForRetrievingBlog(blog, error);
                return;
            }
            
            [self mergeTagsWithRemoteTags:remoteTags blog:blog];
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            
            if (success) {
                success();
            }
        }];
    } failure:failure];
}

- (void)loadMoreTagsForBlog:(Blog *)blog
                    success:(void (^)(NSArray <PostTag *> *tags))success
                    failure:(void (^)(NSError *error))failure
{
    RemoteTaxonomyPaging *paging = self.remotePaging;
    if (!paging) {
        paging = [[RemoteTaxonomyPaging alloc] init];
        paging.number = @(100);
        // start the offset at 0
        paging.offset = @(0);
        self.remotePaging = paging;
    }
    
    id<TaxonomyServiceRemote> remote = [self remoteForBlog:blog];
    NSManagedObjectID *blogObjectID = blog.objectID;
    [remote getTagsWithPaging:paging
                      success:^(NSArray<RemotePostTag *> *remoteTags) {
                          NSError *error;
                          Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:blogObjectID error:&error];
                          if (!blog || error) {
                              logErrorForRetrievingBlog(blog, error);
                              return;
                          }
                          
                          // increment the offset by the number of tags being requested for the next paging request
                          self.remotePaging.offset = @(self.remotePaging.offset.integerValue + self.remotePaging.number.integerValue);
                          
                          NSArray *tags = [self mergeTagsWithRemoteTags:remoteTags blog:blog];
                          [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
                          
                          if (success) {
                              success(tags);
                          }
                      } failure:failure];
}

- (void)searchTagsWithName:(NSString *)nameQuery
                      blog:(Blog *)blog
                   success:(void (^)(NSArray <PostTag *> *tags))success
                   failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(nameQuery.length > 0);
    id<TaxonomyServiceRemote> remote = [self remoteForBlog:blog];
    NSManagedObjectID *blogObjectID = blog.objectID;
    [remote searchTagsWithName:nameQuery
                       success:^(NSArray<RemotePostTag *> *remoteTags) {
                           
                           NSError *error;
                           Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:blogObjectID error:&error];
                           if (!blog || error) {
                               logErrorForRetrievingBlog(blog, error);
                               return;
                           }
                           
                           NSArray *tags = [self mergeTagsWithRemoteTags:remoteTags blog:blog];
                           [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
                           
                           if (success) {
                               success(tags);
                           }
                           
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

- (NSArray <PostTag *> *)mergeTagsWithRemoteTags:(NSArray<RemotePostTag *> *)remoteTags blog:(Blog *)blog
{
    if (!remoteTags.count) {
        return nil;
    }
    
    NSMutableArray *tags = [NSMutableArray arrayWithCapacity:remoteTags.count];
    for (RemotePostTag *remoteTag in remoteTags) {
        [tags addObject:[self tagFromRemoteTag:remoteTag blog:blog]];
    }
    
    return [NSArray arrayWithArray:tags];
}

- (PostTag *)tagFromRemoteTag:(RemotePostTag *)remoteTag blog:(Blog *)blog
{
    PostTag *tag = [self existingTagForRemoteTag:remoteTag blog:blog];
    if (!tag) {
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[PostTag entityName]
                                                             inManagedObjectContext:self.managedObjectContext];
        tag = [[PostTag alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:self.managedObjectContext];
        tag.tagID = remoteTag.tagID;
        tag.blog = blog;
    }
    
    tag.name = remoteTag.name;
    tag.slug = remoteTag.slug;
    
    return tag;
}

- (PostTag *)existingTagForRemoteTag:(RemotePostTag *)remoteTag blog:(Blog *)blog
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[PostTag entityName]];
    request.predicate = [NSPredicate predicateWithFormat:@"blog = %@ AND tagID = %@", blog, remoteTag.tagID];
    NSError *error;
    NSArray *tags = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"Error when retrieving PostTag by tagID: %@", error);
        return nil;
    }
    
    return [tags firstObject];
}

@end
