#import "CategoryService.h"
#import "Category.h"
#import "Blog.h"
#import "RemoteCategory.h"
#import "ContextManager.h"
#import "CategoryServiceRemote.h"
#import "CategoryServiceRemoteREST.h"
#import "CategoryServiceRemoteXMLRPC.h"

@interface CategoryService ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation CategoryService

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    self = [super init];
    if (self) {
        _managedObjectContext = context;
    }

    return self;
}

- (Category *)newCategoryForBlog:(Blog *)blog
{
    Category *category = [NSEntityDescription insertNewObjectForEntityForName:@"Category"
                                                       inManagedObjectContext:self.managedObjectContext];
    category.blog = blog;
    return category;
}

- (Category *)newCategoryForBlogObjectID:(NSManagedObjectID *)blogObjectID {
    Blog *blog = [self blogWithObjectID:blogObjectID];
    return [self newCategoryForBlog:blog];
}

- (BOOL)existsName:(NSString *)name forBlogObjectID:(NSManagedObjectID *)blogObjectID withParentId:(NSNumber *)parentId
{
    Blog *blog = [self blogWithObjectID:blogObjectID];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(categoryName like %@) AND (parentID = %@)", name,
                              (parentId ? parentId : @0)];

    NSSet *items = [blog.categories filteredSetUsingPredicate:predicate];

    if ((items != nil) && (items.count > 0)) {
        // Already exists
        return YES;
    }

    return NO;
}

- (Category *)findWithBlogObjectID:(NSManagedObjectID *)blogObjectID andCategoryID:(NSNumber *)categoryID
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"categoryID == %@", categoryID];
    return [self findWithBlogObjectID:blogObjectID predicate:predicate];
}

- (Category *)findWithBlogObjectID:(NSManagedObjectID *)blogObjectID parentID:(NSNumber *)parentID andName:(NSString *)name
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(categoryName like %@) AND (parentID = %@)", name,
                              (parentID ? parentID : @0)];
    return [self findWithBlogObjectID:blogObjectID predicate:predicate];
}

- (Category *)findWithBlogObjectID:(NSManagedObjectID *)blogObjectID predicate:(NSPredicate *)predicate
{
    Blog *blog = [self blogWithObjectID:blogObjectID];

    NSSet *results = [blog.categories filteredSetUsingPredicate:predicate];
    return [results anyObject];

}

- (Category *)createOrReplaceFromDictionary:(NSDictionary *)categoryInfo
                            forBlogObjectID:(NSManagedObjectID *)blogObjectID
{
    Blog *blog = [self blogWithObjectID:blogObjectID];

    if ([categoryInfo objectForKey:@"categoryId"] == nil) {
        return nil;
    }
    if ([categoryInfo objectForKey:@"categoryName"] == nil) {
        return nil;
    }

    Category *category = [self findWithBlogObjectID:blog.objectID andCategoryID:[[categoryInfo objectForKey:@"categoryId"] numericValue]];

    if (category == nil) {
        category = [self newCategoryForBlog:blog];
    }

    category.categoryID     = [[categoryInfo objectForKey:@"categoryId"] numericValue];
    category.categoryName   = [categoryInfo objectForKey:@"categoryName"];
    category.parentID       = [[categoryInfo objectForKey:@"parentId"] numericValue];

    return category;
}

- (void)syncCategoriesForBlog:(Blog *)blog
                      success:(void (^)())success
                      failure:(void (^)(NSError *error))failure
{
    id<CategoryServiceRemote> remote = [self remoteForBlog:blog];
    [remote getCategoriesForBlog:blog
                         success:^(NSArray *categories) {
                             [self.managedObjectContext performBlock:^{
                                 [self mergeCategories:categories forBlog:blog completionHandler:success];
                             }];
                         } failure:failure];
}

- (void)createCategoryWithName:(NSString *)name
        parentCategoryObjectID:(NSManagedObjectID *)parentCategoryObjectID
               forBlogObjectID:(NSManagedObjectID *)blogObjectID
                       success:(void (^)(Category *category))success
                       failure:(void (^)(NSError *error))failure
{
    NSParameterAssert(name != nil);
    Blog *blog = [self blogWithObjectID:blogObjectID];

    Category *parent = [self categoryWithObjectID:parentCategoryObjectID];

    RemoteCategory *remoteCategory = [RemoteCategory new];
    remoteCategory.parentID = parent.categoryID;
    remoteCategory.name = name;

    id<CategoryServiceRemote> remote = [self remoteForBlog:blog];
    [remote createCategory:remoteCategory
                   forBlog:blog
                   success:^(RemoteCategory *receivedCategory) {
                       [self.managedObjectContext performBlock:^{
                           Category *newCategory = [self newCategoryForBlog:blog];
                           newCategory.categoryID = receivedCategory.categoryID;
                           if ([remote isKindOfClass:[CategoryServiceRemoteXMLRPC class]]) {
                               // XML-RPC only returns ID, let's fetch the new category as
                               // filters might change the content
                               [self syncCategoriesForBlog:blog success:nil failure:nil];
                               newCategory.categoryName = remoteCategory.name;
                               newCategory.parentID = remoteCategory.parentID;
                           } else {
                               newCategory.categoryName = receivedCategory.name;
                               newCategory.parentID = receivedCategory.parentID;
                           }
                           if (newCategory.parentID == nil) {
                               newCategory.parentID = @0;
                           }
                           [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
                           if (success) {
                               success(newCategory);
                           }
                       }];
                   } failure:failure];
}

- (void)mergeCategories:(NSArray *)categories forBlog:(Blog *)blog completionHandler:(void (^)(void))completion
{
    NSSet *remoteSet = [NSSet setWithArray:[categories valueForKey:@"categoryID"]];
    NSSet *localSet = [blog.categories valueForKey:@"categoryID"];
    NSMutableSet *toDelete = [localSet mutableCopy];
    [toDelete minusSet:remoteSet];

    if ([toDelete count] > 0) {
        for (Category *category in blog.categories) {
            if ([toDelete containsObject:category.categoryID]) {
                [self.managedObjectContext deleteObject:category];
            }
        }
    }

    for (RemoteCategory *remoteCategory in categories) {
        Category *category = [self findWithBlogObjectID:blog.objectID andCategoryID:remoteCategory.categoryID];
        if (!category) {
            category = [self newCategoryForBlog:blog];
            category.categoryID = remoteCategory.categoryID;
        }
        category.categoryName = remoteCategory.name;
        category.parentID = remoteCategory.parentID;
    }

    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];

    if (completion) {
        completion();
    }
}

- (Blog *)blogWithObjectID:(NSManagedObjectID *)objectID
{
    if (objectID == nil) {
        return nil;
    }

    NSError *error;
    Blog *blog = (Blog *)[self.managedObjectContext existingObjectWithID:objectID error:&error];
    if (error) {
        DDLogError(@"Error when retrieving Blog by ID: %@", error);
        return nil;
    }

    return blog;
}

- (Category *)categoryWithObjectID:(NSManagedObjectID *)objectID
{
    if (objectID == nil) {
        return nil;
    }

    NSError *error;
    Category *category = (Category *)[self.managedObjectContext existingObjectWithID:objectID error:&error];
    if (error) {
        DDLogError(@"Error when retrieving Category by ID: %@", error);
        return nil;
    }

    return category;
}

- (id<CategoryServiceRemote>)remoteForBlog:(Blog *)blog {
    if (blog.restApi) {
        return [[CategoryServiceRemoteREST alloc] initWithApi:blog.restApi];
    } else {
        return [[CategoryServiceRemoteXMLRPC alloc] initWithApi:blog.api];
    }
}

@end
