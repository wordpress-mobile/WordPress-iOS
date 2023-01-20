#import "PostCategoryService.h"
#import "PostCategory.h"
#import "Blog.h"
#import "CoreDataStack.h"
#import "WordPress-Swift.h"
@import WordPressKit;

NS_ASSUME_NONNULL_BEGIN

@implementation PostCategoryService

- (instancetype)initWithCoreDataStack:(id<CoreDataStack>)coreDataStack
{
    if ((self = [super init])) {
        _coreDataStack = coreDataStack;
    }
    return self;
}

- (NSError *)serviceErrorNoBlog
{
    return [NSError errorWithDomain:NSStringFromClass([self class])
                               code:PostCategoryServiceErrorsBlogNotFound
                           userInfo:nil];
}

- (void)syncCategoriesForBlog:(Blog *)blog
                      success:(nullable void (^)(void))success
                      failure:(nullable void (^)(NSError *error))failure
{
    id<TaxonomyServiceRemote> remote = [self remoteForBlog:blog];
    NSManagedObjectID *blogID = blog.objectID;
    [remote getCategoriesWithSuccess:^(NSArray *categories) {
                               [[ContextManager sharedInstance] performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
                                   Blog *blog = (Blog *)[context existingObjectWithID:blogID error:nil];
                                   if (!blog) {
                                       if (failure) {
                                           failure([self serviceErrorNoBlog]);
                                       }
                                       return;
                                   }
                                   [self mergeCategories:categories forBlog:blog inContext:context];
                               } completion: ^{
                                   if (success) {
                                       success();
                                   }
                               }];
                           } failure:failure];
}

- (void)syncCategoriesForBlog:(Blog *)blog
                       number:(nullable NSNumber *)number
                       offset:(nullable NSNumber *)offset
                      success:(nullable void (^)(NSArray <PostCategory *> *categories))success
                      failure:(nullable void (^)(NSError *error))failure
{
    id<TaxonomyServiceRemote> remote = [self remoteForBlog:blog];
    RemoteTaxonomyPaging *paging = [[RemoteTaxonomyPaging alloc] init];
    paging.number = number ?: @(100);
    paging.offset = offset ?: @(0);
    NSManagedObjectID *blogID = blog.objectID;
    [remote getCategoriesWithPaging:paging
                            success:^(NSArray<RemotePostCategory *> *categories) {
                                [[ContextManager sharedInstance] performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
                                    Blog *blog = (Blog *)[context existingObjectWithID:blogID error:nil];
                                    if (!blog) {
                                        if (failure) {
                                            failure([self serviceErrorNoBlog]);
                                        }
                                        return;
                                    }
                                    [self mergeCategories:categories forBlog:blog inContext:context];
                                } completion: ^{
                                    if (success) {
                                        NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
                                        NSArray *postCategories = [categories wp_map:^id(RemotePostCategory *obj) {
                                            return [PostCategory lookupWithBlogObjectID:blogID categoryID:obj.categoryID inContext:context];
                                        }];
                                        success(postCategories);
                                    }
                                }];
                            } failure:failure];
}

- (void)createCategoryWithName:(NSString *)name
        parentCategoryObjectID:(nullable NSManagedObjectID *)parentCategoryObjectID
               forBlogObjectID:(NSManagedObjectID *)blogObjectID
                       success:(nullable void (^)(PostCategory *category))success
                       failure:(nullable void (^)(NSError *error))failure
{
    NSParameterAssert(name != nil);
    Blog * __block blog = nil;

    RemotePostCategory *remoteCategory = [RemotePostCategory new];
    remoteCategory.name = name;

    [self.coreDataStack.mainContext performBlockAndWait:^{
        blog = [self.coreDataStack.mainContext existingObjectWithID:blogObjectID error:nil];
        if (parentCategoryObjectID) {
            PostCategory *parent = [self.coreDataStack.mainContext existingObjectWithID:parentCategoryObjectID error:nil];
            remoteCategory.parentID = parent.categoryID;
        }
    }];

    id<TaxonomyServiceRemote> remote = [self remoteForBlog:blog];
    [remote createCategory:remoteCategory
                   success:^(RemotePostCategory *receivedCategory) {
                       [self.coreDataStack performAndSaveUsingBlock:^(NSManagedObjectContext *context) {
                           Blog *blog = [context existingObjectWithID:blogObjectID error:nil];
                           if (!blog) {
                               if (failure) {
                                   failure([self serviceErrorNoBlog]);
                               }
                               return;
                           }
                           PostCategory *newCategory = [PostCategory createWithBlogObjectID:blogObjectID inContext:context];
                           newCategory.categoryID = receivedCategory.categoryID;
                           if ([remote isKindOfClass:[TaxonomyServiceRemoteXMLRPC class]]) {
                               newCategory.categoryName = remoteCategory.name;
                               newCategory.parentID = remoteCategory.parentID;
                           } else {
                               newCategory.categoryName = receivedCategory.name;
                               newCategory.parentID = receivedCategory.parentID;
                           }
                           if (newCategory.parentID == nil) {
                               newCategory.parentID = @0;
                           }
                       } completion:^{
                           if (success) {
                               PostCategory *newCategory = [PostCategory lookupWithBlogObjectID:blogObjectID
                                                                           categoryID:receivedCategory.categoryID
                                                                            inContext:[[ContextManager sharedInstance] mainContext]];
                               success(newCategory);
                           }
                           if ([remote isKindOfClass:[TaxonomyServiceRemoteXMLRPC class]]) {
                               // XML-RPC only returns ID, let's fetch the new category as
                               // filters might change the content
                               [self syncCategoriesForBlog:blog success:nil failure:nil];
                           }
                       }];
                   } failure:failure];
}

- (void)mergeCategories:(NSArray <RemotePostCategory *> *)remoteCategories forBlog:(Blog *)blog inContext:(NSManagedObjectContext *)context
{
    NSSet *remoteSet = [NSSet setWithArray:[remoteCategories valueForKey:@"categoryID"]];
    NSSet *localSet = [blog.categories valueForKey:@"categoryID"];
    NSMutableSet *toDelete = [localSet mutableCopy];
    [toDelete minusSet:remoteSet];

    if ([toDelete count] > 0) {
        NSSet *blogCategories = [blog.categories copy];
        for (PostCategory *category in blogCategories) {
            if ([toDelete containsObject:category.categoryID]) {
                [context deleteObject:category];
            }
        }
    }
    
    NSMutableArray *categories = [NSMutableArray arrayWithCapacity:remoteCategories.count];
    
    for (RemotePostCategory *remoteCategory in remoteCategories) {
        PostCategory *category = [PostCategory lookupWithBlogObjectID:blog.objectID categoryID:remoteCategory.categoryID inContext:context];
        if (!category) {
            category = [PostCategory createWithBlogObjectID:blog.objectID inContext:context];
            category.categoryID = remoteCategory.categoryID;
        }
        category.categoryName = remoteCategory.name;
        category.parentID = remoteCategory.parentID;
        
        [categories addObject:category];
    }
}

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

@end

NS_ASSUME_NONNULL_END
