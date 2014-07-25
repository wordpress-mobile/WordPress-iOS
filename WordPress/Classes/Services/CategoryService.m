#import "CategoryService.h"
#import "Category.h"
#import "Blog.h"
#import "ContextManager.h"
#import "CategoryServiceRemote.h"

@interface CategoryService ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation CategoryService

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context {
    self = [super init];
    if (self) {
        _managedObjectContext = context;
    }
    
    return self;
}

- (Category *)newCategoryForBlog:(Blog *)blog {
    Category *category = [NSEntityDescription insertNewObjectForEntityForName:@"Category"
                                                       inManagedObjectContext:self.managedObjectContext];
    category.blog = blog;
    return category;
}

- (Category *)newCategoryForBlogObjectID:(NSManagedObjectID *)blogObjectID {
    Blog *blog = [self blogWithObjectID:blogObjectID];
    return [self newCategoryForBlog:blog];
}

- (BOOL)existsName:(NSString *)name forBlogObjectID:(NSManagedObjectID *)blogObjectID withParentId:(NSNumber *)parentId {
    Blog *blog = [self blogWithObjectID:blogObjectID];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(categoryName like %@) AND (parentID = %@)", name,
                              (parentId ? parentId : [NSNumber numberWithInt:0])];
    
    NSSet *items = [blog.categories filteredSetUsingPredicate:predicate];
    
    if ((items != nil) && (items.count > 0)) {
        // Already exists
        return YES;
    } else {
        return NO;
    }
}

- (Category *)findWithBlogObjectID:(NSManagedObjectID *)blogObjectID andCategoryID:(NSNumber *)categoryID {
    Blog *blog = [self blogWithObjectID:blogObjectID];

    NSSet *results = [blog.categories filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"categoryID == %@",categoryID]];
    
    if (results && (results.count > 0)) {
        return [[results allObjects] objectAtIndex:0];
    }
    return nil;
}

- (Category *)createOrReplaceFromDictionary:(NSDictionary *)categoryInfo forBlogObjectID:(NSManagedObjectID *)blogObjectID {
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

- (void)createCategoryWithName:(NSString *)name parentCategoryObjectID:(NSManagedObjectID *)parentCategoryObjectID forBlogObjectID:(NSManagedObjectID *)blogObjectID success:(void (^)(Category *category))success failure:(void (^)(NSError *error))failure {
    Blog *blog = [self blogWithObjectID:blogObjectID];

    Category *parent = [self categoryWithObjectID:parentCategoryObjectID];
    Category *category = [self newCategoryForBlog:blog];
    category.categoryName = name;
	if (parent.categoryID != nil)
		category.parentID = parent.categoryID;
    
    CategoryServiceRemote *remote = [CategoryServiceRemote new];
    [remote createCategoryWithName:name
                  parentCategoryID:parent.categoryID
                           forBlog:blog
                           success:^(NSNumber *categoryID) {
                               [self.managedObjectContext performBlockAndWait:^{
                                   category.categoryID = categoryID;
                                   [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
                               }];
                               
                               if (success) {
                                   success(category);
                               }
                               
                           } failure:^(NSError *error) {
                               DDLogError(@"Error while saving remote Category: %@", error);
                               [self.managedObjectContext performBlockAndWait:^{
                                   [self.managedObjectContext deleteObject:category];
                                   [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
                               }];
                               
                               if (failure) {
                                   failure(error);
                               }
                           }];
}

- (void)mergeNewCategories:(NSArray *)newCategories forBlogObjectID:(NSManagedObjectID *)blogObjectID {
    NSMutableArray *categoriesToKeep = [NSMutableArray array];
    Blog *contextBlog = [self blogWithObjectID:blogObjectID];
    
    for (NSDictionary *categoryInfo in newCategories) {
        // TODO :: This needs to be done on the current context
        Category *newCategory = [self createOrReplaceFromDictionary:categoryInfo forBlogObjectID:blogObjectID];
        if (newCategory != nil) {
            [categoriesToKeep addObject:newCategory];
        } else {
            DDLogInfo(@"-[Category createOrReplaceFromDictionary:forBlog:] returned a nil category: %@", categoryInfo);
        }
    }
    
    NSSet *existingCategories = contextBlog.categories;
    if (existingCategories && (existingCategories.count > 0)) {
        for (Category *c in existingCategories) {
            if (![categoriesToKeep containsObject:c]) {
                DDLogInfo(@"Deleting Category: %@", c);
                [self.managedObjectContext deleteObject:c];
            }
        }
    }
    
    [[ContextManager sharedInstance] saveContext:self.managedObjectContext];
}

- (Blog *)blogWithObjectID:(NSManagedObjectID *)objectID {
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

- (Category *)categoryWithObjectID:(NSManagedObjectID *)objectID {
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

@end
