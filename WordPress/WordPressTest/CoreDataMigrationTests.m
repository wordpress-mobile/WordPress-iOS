#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <XCTest/XCTest.h>
#import "ALIterativeMigrator.h"
#import "Blog.h"

@interface CoreDataMigrationTests : XCTestCase

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

- (void)testMigrate19to21Failure
{
    NSURL *model19Url = [self urlForModelName:@"WordPress 19" inDirectory:nil];
    NSURL *model21Url = [self urlForModelName:@"WordPress 21" inDirectory:nil];
    NSURL *storeUrl = [self urlForStoreWithName:@"WordPress20.sqlite"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:model19Url];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    NSDictionary *options = @{
                              NSInferMappingModelAutomaticallyOption            : @(YES),
                              NSMigratePersistentStoresAutomaticallyOption    : @(YES)
                              };
    
    NSError *error = nil;
    NSPersistentStore * ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                                    configuration:nil
                                              URL:storeUrl
                                          options:options
                                            error:&error];
    
    XCTAssertNotNil(ps);
    //make sure we remove the persistent store to make sure it releases the file.
    [psc removePersistentStore:ps error:&error];
    
    psc = nil;
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:model21Url];
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSPersistentStore * psFail = [psc addPersistentStoreWithType:NSSQLiteStoreType
                               configuration:nil
                                         URL:storeUrl
                                     options:options
                                       error:&error];
    
    XCTAssertNil(psFail);
}

- (void)testMigrate19to21Success {
    NSURL *model19Url = [self urlForModelName:@"WordPress 19" inDirectory:nil];
    NSURL *model21Url = [self urlForModelName:@"WordPress 21" inDirectory:nil];
    NSURL *storeUrl = [self urlForStoreWithName:@"WordPress20.sqlite"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:model19Url];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    NSDictionary *options = @{
                              NSInferMappingModelAutomaticallyOption            : @(YES),
                              NSMigratePersistentStoresAutomaticallyOption    : @(YES)
                              };
    
    NSError *error = nil;
    NSPersistentStore * ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                                               configuration:nil
                                                         URL:storeUrl
                                                     options:options
                                                       error:&error];
    
    if (!ps) {
        NSLog(@"Error while openning Persistent Store: %@", [error localizedDescription]);
    }
    
    XCTAssertNotNil(ps);
    
    psc = nil;
    
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:model21Url];
    BOOL migrateResult = [ALIterativeMigrator iterativeMigrateURL:storeUrl
                                                           ofType:NSSQLiteStoreType
                                                          toModel:model
                                                orderedModelNames:@[@"WordPress 18", @"WordPress 19", @"WordPress 20", @"WordPress 21"]
                                                            error:&error];
    if (!migrateResult) {
        NSLog(@"Error while migrating: %@", error);
    }
    XCTAssertTrue(migrateResult);
    
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil
                                     URL:storeUrl
                                 options:options
                                   error:&error];
    
    if (!ps) {
        NSLog(@"Error while openning Persistent Store: %@", [error localizedDescription]);
    }
    XCTAssertNotNil(ps);
    
    //make sure we remove the persistent store to make sure it releases the file.
    [psc removePersistentStore:ps error:&error];
}

- (void)testMigrate19to31Success {
    NSURL *model19Url = [self urlForModelName:@"WordPress 19" inDirectory:nil];
    NSURL *model31Url = [self urlForModelName:@"WordPress 31" inDirectory:nil];
    NSURL *storeUrl = [self urlForStoreWithName:@"WordPress19to31.sqlite"];


    // Load Model 19
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:model19Url];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    NSDictionary *options = @{
                              NSInferMappingModelAutomaticallyOption            : @(YES),
                              NSMigratePersistentStoresAutomaticallyOption    : @(YES)
                              };
    
    NSError *error = nil;
    NSPersistentStore * ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                                               configuration:nil
                                                         URL:storeUrl
                                                     options:options
                                                       error:&error];
    XCTAssertNotNil(ps);

    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;

    XCTAssertNil(error, @"Error while loading the PSC for Model 19");
    XCTAssertNotNil(context, @"Invalid NSManagedObjectContext");


    // Insert a dummy Post into Model 19.
    NSManagedObject *account = [self insertDummyAccountInContext:context];
    XCTAssertNotNil(account, @"Couldn't insert an account");

    NSManagedObject *blog = [self insertDummyBlogInContext:context];
    XCTAssertNotNil(blog, @"Couldn't insert a blog");

    [blog setValue:account forKey:@"account"];

    NSManagedObject *post = [self insertDummyPostInContext:context];
    XCTAssertNotNil(post, @"Couldn't insert a post");

    [post setValue:blog forKey:@"blog"];
    [post setPrimitiveValue:@1 forKey:@"postID"];
    [post setPrimitiveValue:@2 forKey:@"remoteStatusNumber"];

    [context save:&error];

    XCTAssertNil(error, @"Error while saving post context");

    psc = nil;


    // Migrate to Model 31.
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:model31Url];
    BOOL migrateResult = [ALIterativeMigrator iterativeMigrateURL:storeUrl
                                                           ofType:NSSQLiteStoreType
                                                          toModel:model
                                                orderedModelNames:@[@"WordPress 19", @"WordPress 20", @"WordPress 21", @"WordPress 22", @"WordPress 23", @"WordPress 24", @"WordPress 25", @"WordPress 26", @"WordPress 27", @"WordPress 28", @"WordPress 29", @"WordPress 30", @"WordPress 31"]
                                                            error:&error];
    if (!migrateResult) {
        NSLog(@"Error while migrating: %@", error);
    }
    XCTAssertTrue(migrateResult);


    // Load Model 31 after migrating
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil
                                     URL:storeUrl
                                 options:options
                                   error:&error];
    
    if (!ps) {
        NSLog(@"Error while openning Persistent Store: %@", [error localizedDescription]);
    }
    XCTAssertNotNil(ps);

    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;


    // Find the post and confirm it was updated properly
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
    NSArray *posts = [context executeFetchRequest:request error:&error];
    NSManagedObject *migratedPost = [posts firstObject];

    XCTAssertNotNil(migratedPost, @"Missing migrated post?");
    NSNumber *isLocal = [migratedPost valueForKey:@"metaIsLocal"];
    NSNumber *publishImmedately = [migratedPost valueForKey:@"metaPublishImmediately"];

    XCTAssertTrue([isLocal boolValue], @"Is local flag was not properly updated.");
    XCTAssertTrue([publishImmedately boolValue], @"Publish immedately flag was not properly updated.");

    //make sure we remove the persistent store to make sure it releases the file.
    [psc removePersistentStore:ps error:&error];
}

- (void)testMigrate27to28preservesCategories {
    // Properties
    NSURL *model27Url = [self urlForModelName:@"WordPress 27" inDirectory:nil];
    NSURL *model28Url = [self urlForModelName:@"WordPress 28" inDirectory:nil];
    NSURL *storeUrl = [self urlForStoreWithName:@"WordPress27.sqlite"];
    
    // Load a Model 27 Stack
    NSManagedObjectModel *model27 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model27Url];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model27];
    
    NSDictionary *options = @{
        NSInferMappingModelAutomaticallyOption          : @(YES),
        NSMigratePersistentStoresAutomaticallyOption    : @(YES)
    };
    
    NSError *error = nil;
    NSPersistentStore *ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                                              configuration:nil
                                                        URL:storeUrl
                                                    options:options
                                                      error:&error];
    
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;
    
    XCTAssertNil(error, @"Error while loading the PSC for Model 27");
    XCTAssertNotNil(context, @"Invalid NSManagedObjectContext");
    
    // Insert a dummy Category
    NSManagedObject *account = [self insertDummyAccountInContext:context];
    XCTAssertNotNil(account, @"Couldn't insert an account");
    
    NSManagedObject *blog = [self insertDummyBlogInContext:context];
    XCTAssertNotNil(blog, @"Couldn't insert a blog");

    [blog setValue:account forKey:@"account"];
    
    NSManagedObject *category = [self insertDummyCategoryInContext:context];
    XCTAssertNotNil(category, @"Couldn't insert a category");
    
    [category setValue:blog forKey:@"blog"];
    
    [context save:&error];
    
    XCTAssertNil(error, @"Error while saving context");
    
    // Cleanup
    XCTAssertNotNil(ps);
    psc = nil;
    
    // Migrate to Model 28
    NSManagedObjectModel *model28 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model28Url];
    BOOL migrateResult = [ALIterativeMigrator iterativeMigrateURL:storeUrl
                                                           ofType:NSSQLiteStoreType
                                                          toModel:model28
                                                orderedModelNames:@[@"WordPress 27", @"WordPress 28"]
                                                            error:&error];
    if (!migrateResult) {
        NSLog(@"Error while migrating: %@", error);
    }
    XCTAssertTrue(migrateResult);
    
    // Load a Model 28 Stack
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model28];
    ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil
                                     URL:storeUrl
                                 options:options
                                   error:&error];
    
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;

    XCTAssertNil(error, @"Error while loading the PSC for Model 27");
    XCTAssertNotNil(ps);
    
    // Is the category there?
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Category"];
    NSArray *categories = [context executeFetchRequest:request error:&error];
    NSManagedObject *migratedCategory = categories.firstObject;
    
    XCTAssertNotNil(migratedCategory, @"Missing migrated category?");
    XCTAssertTrue([self isDummyCategory:migratedCategory], @"Invalid category entity");
    
    // Cleanup
    [psc removePersistentStore:ps error:&error];
}

- (void)testMigrate32to33
{
    // Properties
    NSURL *model32Url = [self urlForModelName:@"WordPress 32" inDirectory:nil];
    NSURL *model33Url = [self urlForModelName:@"WordPress 33" inDirectory:nil];
    NSURL *storeUrl = [self urlForStoreWithName:@"WordPress32.sqlite"];

    // Load a Model 32 Stack
    NSManagedObjectModel *model32 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model32Url];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model32];

    NSDictionary *options = @{
                              NSInferMappingModelAutomaticallyOption          : @(YES),
                              NSMigratePersistentStoresAutomaticallyOption    : @(YES)
                              };

    NSError *error = nil;
    NSPersistentStore *ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                                              configuration:nil
                                                        URL:storeUrl
                                                    options:options
                                                      error:&error];

    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;

    XCTAssertNil(error, @"Error while loading the PSC for Model 32");
    XCTAssertNotNil(context, @"Invalid NSManagedObjectContext");

    NSManagedObject *account1 = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:context];
    [account1 setValue:@"https://wordpress.com/xmlrpc.php" forKey:@"xmlrpc"];
    [account1 setValue:@"dotcomuser1" forKey:@"username"];
    [account1 setValue:@YES forKey:@"isWpcom"];

    NSManagedObject *account2 = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:context];
    [account2 setValue:@"https://wordpress.com/xmlrpc.php" forKey:@"xmlrpc"];
    [account2 setValue:@"dotcomuser2" forKey:@"username"];
    [account2 setValue:@YES forKey:@"isWpcom"];

    NSManagedObject *account3 = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:context];
    [account3 setValue:@"http://example.com/xmlrpc.php" forKey:@"xmlrpc"];
    [account3 setValue:@"selfhosteduser1" forKey:@"username"];
    [account3 setValue:@NO forKey:@"isWpcom"];

    NSManagedObject *blog1 = [NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:context];
    [blog1 setValue:@(1001) forKey:@"blogID"];
    [blog1 setValue:@"https://test1.wordpress.com" forKey:@"url"];
    [blog1 setValue:@"https://test1.wordpress.com/xmlrpc.php" forKey:@"xmlrpc"];
    [blog1 setValue:account1 forKey:@"account"];

    NSManagedObject *blog2 = [NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:context];
    [blog2 setValue:@(1) forKey:@"blogID"];
    [blog2 setValue:@"http://example.com" forKey:@"url"];
    [blog2 setValue:@"https://example.com/xmlrpc.php" forKey:@"xmlrpc"];
    [blog2 setValue:account3 forKey:@"account"];
    [blog2 setValue:account2 forKey:@"jetpackAccount"];

    NSManagedObject *blog3 = [NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:context];
    [blog3 setValue:@(1002) forKey:@"blogID"];
    [blog3 setValue:@"http://jpm.example.com" forKey:@"url"];
    [blog3 setValue:@"https://jpm.example.com/xmlrpc.php" forKey:@"xmlrpc"];
    [blog3 setValue:account1 forKey:@"account"];
    [blog3 setValue:@YES forKey:@"isJetpack"];

    [context save:&error];
    XCTAssertNil(error, @"Error while saving context");

    // Cleanup
    XCTAssertNotNil(ps);
    psc = nil;

    // Migrate to Model 33
    NSManagedObjectModel *model33 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model33Url];
    BOOL migrateResult = [ALIterativeMigrator iterativeMigrateURL:storeUrl
                                                           ofType:NSSQLiteStoreType
                                                          toModel:model33
                                                orderedModelNames:@[@"WordPress 32", @"WordPress 33"]
                                                            error:&error];
    if (!migrateResult) {
        NSLog(@"Error while migrating: %@", error);
    }
    XCTAssertTrue(migrateResult);

    // Load a Model 33 Stack
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model33];
    ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil
                                     URL:storeUrl
                                 options:options
                                   error:&error];

    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;

    XCTAssertNil(error, @"Error while loading the PSC for Model 33");
    XCTAssertNotNil(ps);

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Account"];
    NSUInteger accountCount = [context countForFetchRequest:request error:&error];
    XCTAssertEqual(2, accountCount);

    request = [NSFetchRequest fetchRequestWithEntityName:@"Blog"];
    request.predicate = [NSPredicate predicateWithFormat:@"blogID == 1001"];
    NSArray *blogs = [context executeFetchRequest:request error:&error];
    NSManagedObject *newBlog1 = blogs.firstObject;
    XCTAssertEqualObjects(@"dotcomuser1", [newBlog1 valueForKey:@"username"]);
    XCTAssertTrue([[newBlog1 valueForKey:@"isHostedAtWPcom"] boolValue]);

    request = [NSFetchRequest fetchRequestWithEntityName:@"Blog"];
    request.predicate = [NSPredicate predicateWithFormat:@"blogID == 1"];
    blogs = [context executeFetchRequest:request error:&error];
    NSManagedObject *newBlog2 = blogs.firstObject;
    XCTAssertEqualObjects(@"selfhosteduser1", [newBlog2 valueForKey:@"username"]);
    XCTAssertEqualObjects(@"dotcomuser2", [newBlog2 valueForKeyPath:@"jetpackAccount.username"]);
    XCTAssertFalse([[newBlog2 valueForKey:@"isHostedAtWPcom"] boolValue]);

    request = [NSFetchRequest fetchRequestWithEntityName:@"Blog"];
    request.predicate = [NSPredicate predicateWithFormat:@"blogID == 1002"];
    blogs = [context executeFetchRequest:request error:&error];
    NSManagedObject *newBlog3 = blogs.firstObject;
    XCTAssertNil([newBlog3 valueForKey:@"username"]);
    XCTAssertEqualObjects(@"dotcomuser1", [newBlog3 valueForKeyPath:@"account.username"]);
    XCTAssertFalse([[newBlog3 valueForKey:@"isHostedAtWPcom"] boolValue]);
}

- (void)testMigrate35to36
{
    // Properties
    NSURL *model35Url = [self urlForModelName:@"WordPress 35" inDirectory:nil];
    NSURL *model36Url = [self urlForModelName:@"WordPress 36" inDirectory:nil];
    NSURL *storeUrl = [self urlForStoreWithName:@"WordPress35.sqlite"];
    
    // Load a Model 34 Stack
    NSManagedObjectModel *model35 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model35Url];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model35];
    
    NSDictionary *options = @{
                              NSInferMappingModelAutomaticallyOption          : @(YES),
                              NSMigratePersistentStoresAutomaticallyOption    : @(YES)
                              };
    
    NSError *error = nil;
    NSPersistentStore *ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                                              configuration:nil
                                                        URL:storeUrl
                                                    options:options
                                                      error:&error];
    
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;
    
    XCTAssertNil(error, @"Error while loading the PSC for Model 35");
    XCTAssertNotNil(context, @"Invalid NSManagedObjectContext");
    

    Blog *blog = (Blog *)[NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:context];
    [blog setValue:@(1001) forKey:@"blogID"];
    [blog setValue:@"https://test1.wordpress.com" forKey:@"url"];
    [blog setValue:@"https://test1.wordpress.com/xmlrpc.php" forKey:@"xmlrpc"];
    XCTAssertThrows(blog.blogTagline = @"TagLine", @"Model 35 doesn't support tagline");
    [context save:&error];
    XCTAssertNil(error, @"Error while saving context");
    
    // Cleanup
    XCTAssertNotNil(ps);
    psc = nil;
    
    // Migrate to Model 36
    NSManagedObjectModel *model36 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model36Url];
    BOOL migrateResult = [ALIterativeMigrator iterativeMigrateURL:storeUrl
                                                           ofType:NSSQLiteStoreType
                                                          toModel:model36
                                                orderedModelNames:@[@"WordPress 35", @"WordPress 36"]
                                                            error:&error];
    if (!migrateResult) {
        NSLog(@"Error while migrating: %@", error);
    }
    XCTAssertTrue(migrateResult);
    
    // Load a Model 36 Stack
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model36];
    ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil
                                     URL:storeUrl
                                 options:options
                                   error:&error];
    
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;
    
    XCTAssertNil(error, @"Error while loading the PSC for Model 36");
    XCTAssertNotNil(ps);
    
    Blog *blog2 = (Blog *)[NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:context];
    [blog2 setValue:@(1002) forKey:@"blogID"];
    [blog2 setValue:@"https://test1.wordpress.com" forKey:@"url"];
    [blog2 setValue:@"https://test1.wordpress.com/xmlrpc.php" forKey:@"xmlrpc"];
    XCTAssertNoThrow(blog2.blogTagline = @"TagLine", @"Model 36 supports tagline");
    [context save:&error];
    XCTAssertNil(error, @"Error while saving context");
}

- (void)testMigrate39to40
{
    // Properties
    NSURL *model39Url = [self urlForModelName:@"WordPress 39" inDirectory:nil];
    NSURL *model40Url = [self urlForModelName:@"WordPress 40" inDirectory:nil];
    NSURL *storeUrl = [self urlForStoreWithName:@"WordPress40.sqlite"];
    
    // Load a Model 39 Stack
    NSManagedObjectModel *model39 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model39Url];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model39];
    
    NSDictionary *options = @{
        NSInferMappingModelAutomaticallyOption          : @(YES),
        NSMigratePersistentStoresAutomaticallyOption    : @(YES)
    };
    
    NSError *error = nil;
    [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error];
    
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;
    
    XCTAssertNil(error, @"Error while loading the PSC for Model 39");
    XCTAssertNotNil(context, @"Invalid NSManagedObjectContext");
    
    // Insert a Dummy Notification
    NSNumber *noteID = @(123123123);
    NSString *simperiumKey = @"42424242";
    
    NSManagedObject *note = [NSEntityDescription insertNewObjectForEntityForName:@"Notification" inManagedObjectContext:context];
    [note setValue:simperiumKey forKey:@"simperiumKey"];
    [note setValue:noteID forKey:@"id"];
    [context save:&error];
    XCTAssertNil(error, @"Error while saving context");
    
    // Migrate to Model 40
    NSManagedObjectModel *model40 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model40Url];
    BOOL migrateResult = [ALIterativeMigrator iterativeMigrateURL:storeUrl
                                                           ofType:NSSQLiteStoreType
                                                          toModel:model40
                                                orderedModelNames:@[@"WordPress 39", @"WordPress 40"]
                                                            error:&error];
    if (!migrateResult) {
        NSLog(@"Error while migrating: %@", error);
    }
    
    XCTAssertTrue(migrateResult);
    
    // Load a Model 40 Stack
    NSPersistentStoreCoordinator *psc40 = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model40];
    [psc40 addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error];
    
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc40;
    
    XCTAssertNil(error, @"Error while loading the PSC for Model 40");
    
    // Fetch the Notification
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Notification"];
    request.predicate = [NSPredicate predicateWithFormat:@"simperiumKey == %@", simperiumKey];
    
    NSArray *results = [context executeFetchRequest:request error:nil];
    XCTAssert(results.count == 1, @"Error Fetching Note");
    
    NSManagedObject *migratedNote = [results firstObject];
    XCTAssertEqualObjects([migratedNote valueForKey:@"id"], noteID, @"Oops?");
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
    NSManagedObject *post = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:context];



    return post;
}

@end
