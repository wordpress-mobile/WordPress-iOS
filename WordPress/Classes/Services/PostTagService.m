#import "PostTagService.h"
#import "WordPress-Swift.h"
@import WordPressData;
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

            NSArray *tags = [self saveRemoteTags:remoteTags toBlog:blog];
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

                          NSArray *tags = [self saveRemoteTags:remoteTags toBlog:blog];
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
                              NSArray<PostTag *> *tags = [self saveRemoteTags:remoteTags toBlog:blog];
                              [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

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
                           
                           NSArray *tags = [self saveRemoteTags:remoteTags toBlog:blog];
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

- (nullable id<TaxonomyServiceRemote>)remoteForBlog:(Blog *)blog {
    TaxonomyServiceRemoteCoreREST *instance = [[TaxonomyServiceRemoteCoreREST alloc] initWithBlog:blog];
    if (instance != nil) {
        return instance;
    }

    if ([blog supports:BlogFeatureWPComRESTAPI]) {
        if (blog.wordPressComRestApi) {
            return [[TaxonomyServiceRemoteREST alloc] initWithWordPressComRestApi:blog.wordPressComRestApi siteID:blog.dotComID];
        }
    } else if (blog.xmlrpcApi) {
        return [[TaxonomyServiceRemoteXMLRPC alloc] initWithApi:blog.xmlrpcApi username:blog.username password:blog.password];
    }
    return nil;
}

- (NSArray<PostTag *> *)saveRemoteTags:(NSArray<RemotePostTag *> *)tags toBlog:(Blog *)blog
{
    if (tags.count == 0) {
        return [NSArray array];
    }

    NSManagedObjectContext *context = blog.managedObjectContext;
    if (context == nil) {
        return [NSArray array];
    }

    NSArray<NSNumber *> *remoteTagIDs = [tags wp_map:^NSNumber *(RemotePostTag *remoteTag) {
        return remoteTag.tagID;
    }];

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[PostTag entityName]];
    request.predicate = [NSPredicate predicateWithFormat:@"blog = %@ AND tagID IN %@", blog, remoteTagIDs];

    NSError *error;
    NSArray<PostTag *> *existingTags = [context executeFetchRequest:request error:&error];
    if (error) {
        DDLogError(@"Error when retrieving PostTags by tagIDs: %@", error);
        return [NSArray array];
    }

    NSMutableDictionary<NSNumber *, PostTag *> *existingTagsLookup = [NSMutableDictionary dictionaryWithCapacity:existingTags.count];
    for (PostTag *tag in existingTags) {
        existingTagsLookup[tag.tagID] = tag;
    }

    NSMutableArray<PostTag *> *savedTags = [NSMutableArray array];
    for (RemotePostTag *remote in tags) {
        PostTag *tag = existingTagsLookup[remote.tagID];
        if (tag == nil) {
            NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[PostTag entityName]
                                                                 inManagedObjectContext:context];
            tag = [[PostTag alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:context];
        }

        tag.tagID = remote.tagID;
        tag.name = remote.name;
        tag.slug = remote.slug;
        tag.tagDescription = remote.tagDescription;
        tag.postCount = remote.postCount;
        tag.blog = blog;

        [savedTags addObject:tag];
    }

    return savedTags;
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
            PostTag *localTag = [[self saveRemoteTags:@[tag] toBlog:blog] firstObject];
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
