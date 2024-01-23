#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <XCTest/XCTest.h>
#import "Blog.h"
#import "AbstractPost.h"

@interface CoreDataMigrationTests : XCTestCase

@end

@interface NSManagedObjectContext (Fetch)

- (NSArray *)fetch:(NSString *)entityName withPredicate:(NSString *)predicate arguments:(NSArray *)arguments;

@end

@implementation CoreDataMigrationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testModelUrl {
    NSURL *url = [self urlForModelName:@"WordPress 20" inDirectory:nil];
    
    XCTAssertNotNil(url);
}

/// Test that when migrating from 91 to 92, the values of Posts/Pages' `status` property will
/// be copied over to their `statusAfterSync` property.
- (void)testMigrationFrom91To92WillCopyStatusValuesToStatusAfterSync
{
    // Arrange
    NSURL *model91Url = [self urlForModelName:@"WordPress 91" inDirectory:nil];
    NSURL *model92Url = [self urlForModelName:@"WordPress 92" inDirectory:nil];
    NSURL *storeUrl = [self urlForStoreWithName:@"WordPress91.sqlite"];

    // Load a Model 91 Stack
    NSManagedObjectModel *model91 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model91Url];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model91];

    NSDictionary *options = @{
        NSInferMappingModelAutomaticallyOption       : @(YES),
        NSMigratePersistentStoresAutomaticallyOption : @(YES)
    };

    NSError *error = nil;
    NSPersistentStore *ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                                              configuration:nil
                                                        URL:storeUrl
                                                    options:options
                                                      error:&error];
    XCTAssertNil(error, @"Error while loading the PSC for Model 91");
    XCTAssertNotNil(ps);

    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;
    XCTAssertNotNil(context, @"Invalid NSManagedObjectContext");

    NSNumber *blog1ID = @(987);
    NSNumber *blog2ID = @(4810);
    NSNumber *blog3ID = @(76);
    NSManagedObject *blog1 = [self insertDummyBlogInContext:context blogID:blog1ID];
    NSManagedObject *blog2 = [self insertDummyBlogInContext:context blogID:blog2ID];
    NSManagedObject *blog3 = [self insertDummyBlogInContext:context blogID:blog3ID];

    // Insert posts
    NSManagedObject *draftPost = [self insertDummyPostInContext:context blog:blog1];
    [draftPost setValue:@"draft" forKey:@"status"];
    NSManagedObject *publishedPost = [self insertDummyPostInContext:context blog:blog2];
    [publishedPost setValue:@"publish" forKey:@"status"];
    NSManagedObject *scheduledPost = [self insertDummyPostInContext:context blog:blog2];
    [scheduledPost setValue:@"future" forKey:@"status"];

    // Insert pages
    NSManagedObject *draftPage = [self insertDummyPageInContext:context blog:blog2];
    [draftPage setValue:@"draft" forKey:@"status"];
    NSManagedObject *publishedPage = [self insertDummyPageInContext:context blog:blog1];
    [publishedPage setValue:@"publish" forKey:@"status"];
    NSManagedObject *scheduledPage = [self insertDummyPageInContext:context blog:blog2];
    [scheduledPage setValue:@"future" forKey:@"status"];

    // Insert post with null status
    NSManagedObject *unknownPost = [self insertDummyPostInContext:context blog:blog3];
    [unknownPost setValue:nil forKey:@"status"];

    [context save:&error];
    XCTAssertNil(error, @"Error while saving context");

    // Cleanup
    psc = nil;

    // Act
    // Migrate to Model 92
    NSManagedObjectModel *model92 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model92Url];
    [CoreDataIterativeMigrator iterativeMigrateWithSourceStore:storeUrl
                                                     storeType:NSSQLiteStoreType
                                                            to:model92
                                                         using:@[@"WordPress 91", @"WordPress 92"]
                                                         error:&error];

    if (error != nil) {
        NSLog(@"Error while migrating: %@", error);
    }
    XCTAssertNil(error);

    // Load a Model 92 Stack
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model92];
    ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil
                                     URL:storeUrl
                                 options:options
                                   error:&error];

    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;

    // Assert
    NSManagedObject *fetchedBlog1 = [context fetch:@"Blog" withPredicate:@"blogID = %i" arguments:@[blog1ID]].firstObject;
    XCTAssertNotNil(fetchedBlog1);
    NSSet<NSManagedObject *> *blog1Posts = [fetchedBlog1 valueForKey:@"posts"];
    XCTAssertEqual(blog1Posts.count, 2);

    NSManagedObject *fetchedBlog2 = [context fetch:@"Blog" withPredicate:@"blogID = %i" arguments:@[blog2ID]].firstObject;
    XCTAssertNotNil(fetchedBlog2);
    NSSet<NSManagedObject *> *blog2Posts = [fetchedBlog2 valueForKey:@"posts"];
    XCTAssertEqual(blog2Posts.count, 4);

    for (NSManagedObject *post in [blog1Posts setByAddingObjectsFromSet:blog2Posts]) {
        XCTAssertNotNil([post valueForKey:@"status"]);
        XCTAssertNotNil([post valueForKey:@"statusAfterSync"]);
        XCTAssertEqual([post valueForKey:@"status"], [post valueForKey:@"statusAfterSync"]);
    }

    // Assert blog3 which has a post with null status
    NSManagedObject *fetchedBlog3 = [context fetch:@"Blog" withPredicate:@"blogID = %i" arguments:@[blog3ID]].firstObject;
    XCTAssertNotNil(fetchedBlog3);
    NSSet<NSManagedObject *> *blog3Posts = [fetchedBlog3 valueForKey:@"posts"];
    XCTAssertEqual(blog3Posts.count, 1);
    XCTAssertNil([blog3Posts.anyObject valueForKey:@"status"]);
    XCTAssertNil([blog3Posts.anyObject valueForKey:@"statusAfterSync"]);
}

/// In model 104, we updated transformables to use the NSSecureUnarchiveFromData transformer type.
/// Here we'll check that they're still accessible after a migration. Most of our transformable properties
/// are arrays or dictionaries, so we'll test a couple of representative examples.
///
- (void)testMigrationFrom103To104Transformables
{
    // Arrange
    NSURL *model103Url = [self urlForModelName:@"WordPress 103" inDirectory:nil];
    NSURL *model104Url = [self urlForModelName:@"WordPress 104" inDirectory:nil];
    NSURL *storeUrl = [self urlForStoreWithName:@"WordPress103.sqlite"];

    // Load a Model 103 Stack
    NSManagedObjectModel *model103 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model103Url];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model103];

    NSDictionary *options = @{
        NSInferMappingModelAutomaticallyOption       : @(YES),
        NSMigratePersistentStoresAutomaticallyOption : @(YES)
    };

    NSError *error = nil;
    NSPersistentStore *ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                                              configuration:nil
                                                        URL:storeUrl
                                                    options:options
                                                      error:&error];
    XCTAssertNil(error, @"Error while loading the PSC for Model 103");
    XCTAssertNotNil(ps);

    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;
    XCTAssertNotNil(context, @"Invalid NSManagedObjectContext");

    // Create a dictionary-backed transformable
    NSNumber *blog1ID = @(987);
    Blog *blog1 = (Blog *)[self insertDummyBlogInContext:context blogID:blog1ID];
    NSDictionary *blogOptions = @{
        @"allowed_file_types": @[
                @"pdf", @"xls", @"jpg"
        ]
    };
    blog1.options = blogOptions;

    // Create an array-backed transformable
    AbstractPost *post1 = (AbstractPost *)[self insertDummyPostInContext:context blog:blog1];
    NSArray *revisions = @[ @123, @124 ];
    post1.revisions = revisions;

    [context save:&error];
    XCTAssertNil(error, @"Error while saving context");

    psc = nil;

    // Migrate to Model 104
    NSManagedObjectModel *model104 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model104Url];
    [CoreDataIterativeMigrator iterativeMigrateWithSourceStore:storeUrl
                                                     storeType:NSSQLiteStoreType
                                                            to:model104
                                                         using:@[@"WordPress 103", @"WordPress 104"]
                                                         error:&error];

    if (error != nil) {
        NSLog(@"Error while migrating: %@", error);
    }
    XCTAssertNil(error);

    // Load a Model 104 Stack
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model104];
    ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil
                                     URL:storeUrl
                                 options:options
                                   error:&error];

    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;

    // Check that our properties persisted
    Blog *fetchedBlog1 = [context fetch:@"Blog" withPredicate:@"blogID = %i" arguments:@[blog1ID]].firstObject;
    XCTAssertNotNil(fetchedBlog1);

    NSSet<AbstractPost *> *blog1Posts = [fetchedBlog1 valueForKey:@"posts"];
    XCTAssertEqual(blog1Posts.count, 1);
    XCTAssertTrue([fetchedBlog1.options isEqualToDictionary:blogOptions]);

    AbstractPost *fetchedPost1 = [blog1Posts anyObject];
    XCTAssertTrue([fetchedPost1.revisions isEqualToArray:revisions]);
}

/// In model 104, we updated some transformables to use custom Transformer subclasses.
/// Here we'll check that they're still accessible after a migration.
///
- (void)testMigrationFrom103To104CustomTransformers
{
    // Arrange
    NSURL *model103Url = [self urlForModelName:@"WordPress 103" inDirectory:nil];
    NSURL *model104Url = [self urlForModelName:@"WordPress 104" inDirectory:nil];
    NSURL *storeUrl = [self urlForStoreWithName:@"WordPress103-1.sqlite"];

    // Load a Model 103 Stack
    NSManagedObjectModel *model103 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model103Url];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model103];

    NSDictionary *options = @{
        NSInferMappingModelAutomaticallyOption       : @(YES),
        NSMigratePersistentStoresAutomaticallyOption : @(YES)
    };

    NSError *error = nil;
    NSPersistentStore *ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                                              configuration:nil
                                                        URL:storeUrl
                                                    options:options
                                                      error:&error];
    XCTAssertNil(error, @"Error while loading the PSC for Model 103");
    XCTAssertNotNil(ps);

    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;
    XCTAssertNotNil(context, @"Invalid NSManagedObjectContext");

    Blog *blog1 = (Blog *)[self insertDummyBlogInContext:context blogID:@123];

    // BlogSettings uses Set transformers
    BlogSettings *settings1 = (BlogSettings *)[NSEntityDescription insertNewObjectForEntityForName:[BlogSettings entityName] inManagedObjectContext:context];
    settings1.commentsModerationKeys = [NSSet setWithArray:@[ @"purple", @"monkey", @"dishwasher" ]];
    blog1.settings = settings1;

    // Media has an Error transformer
    Media *media1 = (Media *)[NSEntityDescription insertNewObjectForEntityForName:[Media entityName] inManagedObjectContext:context];
    media1.blog = blog1;
    // The UserInfo dictionary of an NSError can contain types that can't be securely coded, which will throw a Core Data exception on save.
    // We attach an NSUnderlyingError with the expectation that it won't be included when the error is encoded and persisted.
    NSError *underlyingError = [NSError errorWithDomain:NSURLErrorDomain code:500 userInfo:nil];
    NSError *error1 = [NSError errorWithDomain:NSURLErrorDomain code:100 userInfo:@{ NSLocalizedDescriptionKey: @"test", NSUnderlyingErrorKey: underlyingError }];
    media1.error = error1;

    [context save:&error];
    XCTAssertNil(error, @"Error while saving context");

    psc = nil;

    // Migrate to Model 104
    NSManagedObjectModel *model104 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model104Url];
    [CoreDataIterativeMigrator iterativeMigrateWithSourceStore:storeUrl
                                                     storeType:NSSQLiteStoreType
                                                            to:model104
                                                         using:@[@"WordPress 103", @"WordPress 104"]
                                                         error:&error];

    if (error != nil) {
        NSLog(@"Error while migrating: %@", error);
    }
    XCTAssertNil(error);

    // Load a Model 104 Stack
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model104];
    ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil
                                     URL:storeUrl
                                 options:options
                                   error:&error];

    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;

    // Check that our properties persisted
    Media *fetchedMedia1 = [context fetch:@"Media" withPredicate:nil arguments:nil].firstObject;
    // The expected error is stripped of any keys not included in the Media.error setter
    NSError *expectedError = [NSError errorWithDomain:NSURLErrorDomain code:100 userInfo:@{ NSLocalizedDescriptionKey: @"test" }];
    XCTAssert([fetchedMedia1.error isEqual:expectedError]);

    Blog *fetchedBlog1 = [context fetch:@"Blog" withPredicate:@"blogID = %i" arguments:@[@123]].firstObject;
    XCTAssertNotNil(fetchedBlog1);
    XCTAssertTrue([fetchedBlog1.settings.commentsModerationKeys isEqualToSet:settings1.commentsModerationKeys]);
}

#pragma mark - Private Helpers

// Returns the URL for a model file with the given name in the given directory.
// @param directory The name of the bundle directory to search.  If nil,
//    searches default paths.
- (NSURL *)urlForModelName:(NSString*)modelName
               inDirectory:(NSString*)directory
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *url = [bundle URLForResource:modelName
                          withExtension:@"mom"
                           subdirectory:directory];
    if (nil == url) {
        // Get mom file paths from momd directories.
        NSArray *momdPaths = [[NSBundle mainBundle] pathsForResourcesOfType:@"momd"
                                                                inDirectory:directory];
        for (NSString *momdPath in momdPaths) {
            url = [bundle URLForResource:modelName
                           withExtension:@"mom"
                            subdirectory:[momdPath lastPathComponent]];
        }
    }
    
    return url;
}

- (NSURL *)urlForStoreWithName:(NSString *)fileName
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                        NSUserDomainMask,
                                                                        YES) lastObject];
    NSURL *storeURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:fileName]];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error]) {
        NSLog(@"Error removing file: %@", [error localizedDescription]);
    }
    
    return storeURL;
}

- (NSManagedObject *)insertDummyBlogInContext:(NSManagedObjectContext *)context
{
    // Insert a dummy blog with all of the required properties set
    NSManagedObject *blog = [NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:context];

    [blog setValue:@(123) forKey:@"blogID"];
    [blog setValue:@(false) forKey:@"geolocationEnabled"];
    [blog setValue:@(false) forKey:@"hasOlderPosts"];
    [blog setValue:@(false) forKey:@"visible"];
    [blog setValue:@"www.wordpress.com" forKey:@"url"];
    [blog setValue:@"www.wordpress.com" forKey:@"xmlrpc"];

    return blog;
}

/// Insert a `Blog` entity with required values set.
///
/// This is validated to be compatible with model versions from 90 and up.
- (NSManagedObject *)insertDummyBlogInContext:(NSManagedObjectContext *)context blogID:(NSNumber *)blogID
{
    NSManagedObject *blog = [NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:context];

    [blog setValue:blogID forKey:@"blogID"];
    [blog setValue:@"https://example.com" forKey:@"url"];
    [blog setValue:@"https://example.com/xmlrpc.php" forKey:@"xmlrpc"];

    return blog;
}

- (NSManagedObject *)insertDummyAccountInContext:(NSManagedObjectContext *)context
{
    // Insert an account with all of the required properties set
    NSManagedObject *account = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:context];
    
    [account setValue:@(false) forKey:@"isWpcom"];
    [account setValue:@"wordpress" forKey:@"username"];
    [account setValue:@"www.wordpress.com" forKey:@"xmlrpc"];
    
    return account;
}

- (NSManagedObject *)insertDummyCategoryInContext:(NSManagedObjectContext *)context
{
    // Insert a category with all of the required properties set
    NSManagedObject *category = [NSEntityDescription insertNewObjectForEntityForName:@"Category" inManagedObjectContext:context];
    
    [category setValue:@(1234) forKey:@"parentID"];
    [category setValue:@"name" forKey:@"categoryName"];
    
    return category;
}

- (BOOL)isDummyCategory:(NSManagedObject *)object
{
    NSNumber *parentID = [object valueForKey:@"parentID"];
    NSString *name = [object valueForKey:@"categoryName"];
    NSManagedObject *blog = [object valueForKey:@"blog"];
    
    return [@(1234) isEqual:parentID] && [@"name" isEqual:name] && [blog isKindOfClass:[NSManagedObject class]];
}

- (NSManagedObject *)insertDummyPostInContext:(NSManagedObjectContext *)context
{
    return [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:context];
}

- (NSManagedObject *)insertDummyPostInContext:(NSManagedObjectContext *)context blog:(NSManagedObject *)blog
{
    NSManagedObject *post = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:context];
    [post setValue:blog forKey:@"blog"];
    return post;
}

- (NSManagedObject *)insertDummyPageInContext:(NSManagedObjectContext *)context blog:(NSManagedObject *)blog
{
    NSManagedObject *post = [NSEntityDescription insertNewObjectForEntityForName:@"Page" inManagedObjectContext:context];
    [post setValue:blog forKey:@"blog"];
    return post;
}

- (void)cleanModelObjectClassnames:(NSManagedObjectModel *)model
{
    // NOTE:
    // =====
    // Suppose the following scenario...
    //  -   `Model N`'s Entity X contains `Attribute A`
    //  -   `Model N+1`'s Entity X *class* implementation differs from the one bundled in N.
    //      Added / Removed Attributes. It could differ vastly!
    //
    // Problem is... whenever we test `Model N` or `Model N+1`, Core Data will always instantiate the latest
    // NSManagedObject subclass implementation. This could prove troublesome in a variety of scenarios.
    // For that reason, we're implementing this helper, which will nuke NSMO's classnames.
    //
    // For instance:
    // =============
    // In our Data Model 40, Blog had its `blogTagline` property embedded right there.
    // Afterwards, this was moved over to `BlogSettings`, and renamed.
    // If we load a Core Data Stack with an old Model definition, the latest `Blog` class implementation
    // will be instantiated.
    //
    // Since the `Blog` NSManagedObject subclass implementation may map any of its latest properties
    // (such as `settings.tagline`), we may get Unit Test exceptions (due to the missing / invalid properties).
    //
    // The goal of this method is to prevent such scenarios. Please, note that Heavyweight Migrations, also,
    // only deal with NSManagedObject instances (the actuall MO's subclasses never get instantiated there).
    //
    for (NSEntityDescription *entity in model.entities) {
        entity.managedObjectClassName = nil;
    }
}

@end

@implementation NSManagedObjectContext (Fetch)

- (NSArray *)fetch:(NSString *)entityName withPredicate:(NSString *)predicate arguments:(NSArray *)arguments
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];

    if (predicate && arguments) {
        request.predicate = [NSPredicate predicateWithFormat:predicate argumentArray:arguments];
    }

    NSError *error = nil;
    NSArray *result = [self executeFetchRequest:request error:&error];

    if (error != nil) {
        NSLog(@"Fetch request returned error: %@", error);
    }
    NSCAssert(error == nil, @"Failed to execute fetch request.");

    return result;
}

@end
