#import "PostTagService.h"
#import "Blog.h"
#import "PostTag.h"
#import "ContextManager.h"
#import "WordPress-Swift.h"
@import WordPressKit;

NS_ASSUME_NONNULL_BEGIN

static const NSInteger PostTagIdDefaultValue = -1;

@interface PostTagService ()

@end

@implementation PostTagService

- (void)syncTagsForBlog:(Blog *)blog
                success:(nullable void (^)(NSArray <PostTag *> *tags))success
                failure:(nullable void (^)(NSError *error))failure
{
    id<TaxonomyServiceRemote> remote = [self remoteForBlog:blog];
    NSManagedObjectID *blogObjectID = blog.objectID;
    [remote getTagsWithSuccess:^(NSArray <RemotePostTag *> *remoteTags) {
        [self.managedObjectContext performBlock:^{
            NSError *error;
            Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:blogObjectID error:&error];
            if (!blog || error) {
                [self handleError:error forBlog:blog withFailure:failure];
                return;
            }
            
            NSArray *tags = [self mergeTagsWithRemoteTags:remoteTags blog:blog];
            [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
            
            if (success) {
                success(tags);
            }
        }];
    } failure:failure];
}

- (void)syncTagsForBlog:(Blog *)blog
                 number:(nullable NSNumber *)number
                 offset:(nullable NSNumber *)offset
                success:(nullable void (^)(NSArray <PostTag *> *tags))success
                failure:(nullable void (^)(NSError *error))failure
{
    RemoteTaxonomyPaging *paging = [[RemoteTaxonomyPaging alloc] init];
    paging.number = number ?: @(100);
    paging.offset = offset ?: @(0);
    
    id<TaxonomyServiceRemote> remote = [self remoteForBlog:blog];
    NSManagedObjectID *blogObjectID = blog.objectID;
    [remote getTagsWithPaging:paging
                      success:^(NSArray<RemotePostTag *> *remoteTags) {
                          NSError *error;
                          Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:blogObjectID error:&error];
                          if (!blog || error) {
                              [self handleError:error forBlog:blog withFailure:failure];
                              return;
                          }
                          
                          NSArray *tags = [self mergeTagsWithRemoteTags:remoteTags blog:blog];
                          [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
                          
                          if (success) {
                              success(tags);
                          }
                      } failure:failure];
}

- (void)getTopTagsForBlog:(Blog *)blog
                  success:(nullable void (^)(NSArray <PostTag *> *tags))success
                  failure:(nullable void (^)(NSError *error))failure
{
    id<TaxonomyServiceRemote> remote = [self remoteForBlog:blog];
    RemoteTaxonomyPaging *paging = [RemoteTaxonomyPaging new];
    paging.orderBy = RemoteTaxonomyPagingResultsOrderingByCount;
    paging.order = RemoteTaxonomyPagingOrderDescending;

    [remote getTagsWithPaging:paging
                      success:^(NSArray <RemotePostTag *> *remoteTags) {
                          [self.managedObjectContext performBlock:^{
                              NSArray *tags = [remoteTags wp_map:^PostTag *(RemotePostTag *remoteTag) {
                                  return [self tagFromRemoteTag:remoteTag blog:blog];
                              }];
                              if (success) {
                                  success(tags);
                              }
                          }];
                      } failure:failure];
}

- (void)searchTagsWithName:(NSString *)nameQuery
                      blog:(Blog *)blog
                   success:(nullable void (^)(NSArray <PostTag *> *tags))success
                   failure:(nullable void (^)(NSError *error))failure
{
    NSParameterAssert(nameQuery.length > 0);
    id<TaxonomyServiceRemote> remote = [self remoteForBlog:blog];
    NSManagedObjectID *blogObjectID = blog.objectID;
    [remote searchTagsWithName:nameQuery
                       success:^(NSArray<RemotePostTag *> *remoteTags) {
                           NSError *error;
                           Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:blogObjectID error:&error];
                           if (!blog || error) {
                               [self handleError:error forBlog:blog withFailure:failure];
                               return;
                           }
                           
                           NSArray *tags = [self mergeTagsWithRemoteTags:remoteTags blog:blog];
                           [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
                           
                           if (success) {
                               success(tags);
                           }
                           
                       } failure:failure];
}

- (void)deleteTag:(PostTag*)tag
          forBlog:(Blog *)blog
          success:(nullable void (^)(void))success
          failure:(nullable void (^)(NSError *error))failure
{
    NSObject<TaxonomyServiceRemote> *remote = [self remoteForBlog:blog];

    RemotePostTag *remoteTag = [self remoteTagWith:tag];

    [self.managedObjectContext deleteObject:tag];
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

    [remote deleteTag:remoteTag success:^(void) {
        if (success) {
            success();
        }
    } failure:^(NSError * _Nonnull error) {
        [self handleError:error forBlog:blog withFailure:failure];
    }];
}

- (void)saveTag:(PostTag*)tag
        forBlog:(Blog *)blog
        success:(nullable void (^)(PostTag *tag))success
        failure:(nullable void (^)(NSError *error))failure
{
    if (tag.tagID.integerValue == PostTagIdDefaultValue) {
        [self saveNewTag:tag
                    blog:blog
                 success:success
                 failure:failure];
    } else {
        [self updateExistingTag:tag
                           blog:blog
                        success:success
                        failure:failure];
    }
}

#pragma mark - helpers

- (id<TaxonomyServiceRemote>)remoteForBlog:(Blog *)blog {
    if ([blog supports:BlogFeatureWPComRESTAPI]) {
        if (blog.wordPressComRestApi) {
            return [[TaxonomyServiceRemoteREST alloc] initWithWordPressComRestApi:blog.wordPressComRestApi siteID:blog.dotComID];
        }
    } else if (blog.xmlrpcApi) {
        return [[TaxonomyServiceRemoteXMLRPC alloc] initWithApi:blog.xmlrpcApi username:blog.username password:blog.password];
    }
    return nil;
}

- (nullable NSArray <PostTag *> *)mergeTagsWithRemoteTags:(NSArray<RemotePostTag *> *)remoteTags
                                                     blog:(Blog *)blog
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

- (PostTag *)tagFromRemoteTag:(RemotePostTag *)remoteTag
                         blog:(Blog *)blog
{
    PostTag *tag = [self existingTagForRemoteTag:remoteTag blog:blog];
    if (!tag) {
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[PostTag entityName]
                                                             inManagedObjectContext:self.managedObjectContext];
        tag = [[PostTag alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:self.managedObjectContext];
        tag.tagID = remoteTag.tagID;
        tag.tagDescription = remoteTag.tagDescription;
        tag.blog = blog;
    }
    
    tag.name = remoteTag.name;
    tag.slug = remoteTag.slug;
    tag.tagDescription = remoteTag.tagDescription;
    tag.postCount = remoteTag.postCount;
    
    return tag;
}

- (nullable PostTag *)existingTagForRemoteTag:(RemotePostTag *)remoteTag
                                         blog:(Blog *)blog
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

- (void)saveNewTag:(PostTag *)tag
              blog:(Blog *)blog
           success:(nullable void (^)(PostTag *tag))success
           failure:(nullable void (^)(NSError *error))failure
{
    RemotePostTag *remoteTag = [self remoteTagWith:tag];
    NSObject<TaxonomyServiceRemote> *remote = [self remoteForBlog:blog];
    [remote createTag:remoteTag success:^(RemotePostTag * _Nonnull tag) {
        if (success) {
            PostTag *localTag = [self tagFromRemoteTag:tag blog:blog];
            [[ContextManager sharedInstance] saveContextAndWait:self.managedObjectContext];
            success(localTag);
        }
    } failure:^(NSError * _Nonnull error) {
        [self handleError:error forBlog:blog withFailure:failure];
    }];
}

- (void)updateExistingTag:(PostTag *)tag
                     blog:(Blog *)blog
                  success:(nullable void (^)(PostTag *tag))success
                  failure:(nullable void (^)(NSError *error))failure
{
    RemotePostTag *remoteTag = [self remoteTagWith:tag];
    NSObject<TaxonomyServiceRemote> *remote = [self remoteForBlog:blog];
    [remote updateTag:remoteTag success:^(RemotePostTag * _Nonnull updatedTag) {
        tag.tagID = updatedTag.tagID;
        tag.tagDescription = updatedTag.tagDescription;
        tag.slug= updatedTag.slug;
        tag.name = updatedTag.name;
        [[ContextManager sharedInstance] saveContextAndWait:self.managedObjectContext];
        if (success) {
            success(tag);
        }
    } failure:^(NSError * _Nonnull error) {
        [self handleError:error forBlog:blog withFailure:failure];
    }];
}

- (RemotePostTag*)remoteTagWith:(PostTag *)tag
{
    RemotePostTag *remoteTag = [[RemotePostTag alloc] init];
    remoteTag.tagID = tag.tagID;
    remoteTag.name = tag.name;
    remoteTag.slug = tag.slug;
    remoteTag.tagDescription = tag.tagDescription;
    remoteTag.postCount = tag.postCount;

    return remoteTag;
}

- (void)handleError:(nullable NSError *)error forBlog:(nullable Blog *)blog withFailure:(nullable void(^)(NSError *error))failure
{
    DDLogError(@"Error occurred with %@ - error: %@", [self class], error);
    if (failure) {
        failure(error);
    }
}

@end

NS_ASSUME_NONNULL_END
