#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <XCTest/XCTest.h>
#import "ALIterativeMigrator.h"
#import "Blog.h"

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
    [self cleanModelObjectClassnames:model];
    
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
    [self cleanModelObjectClassnames:model];
    
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
    [self cleanModelObjectClassnames:model27];

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
    [self cleanModelObjectClassnames:model28];
    
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
    
    // Load Model 35 and 36
    NSManagedObjectModel *model36 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model36Url];
    NSManagedObjectModel *model35 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model35Url];
    
    [self cleanModelObjectClassnames:model36];
    [self cleanModelObjectClassnames:model35];
    
    // New Model 35 Stack
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
    

    NSManagedObject *blog = [NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:context];
    [blog setValue:@(1001) forKey:@"blogID"];
    [blog setValue:@"https://test1.wordpress.com" forKey:@"url"];
    [blog setValue:@"https://test1.wordpress.com/xmlrpc.php" forKey:@"xmlrpc"];
    XCTAssertThrows([blog setValue:@"Tagline" forKey:@"blogTagline"], @"Model 35 doesn't support tagline");
    [context save:&error];
    XCTAssertNil(error, @"Error while saving context");
    
    // Cleanup
    XCTAssertNotNil(ps);
    psc = nil;
    
    // Migrate to Model 36
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
    
    NSManagedObject *blog2 = [NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:context];
    
    [blog2 setValue:@(1002) forKey:@"blogID"];
    [blog2 setValue:@"https://test1.wordpress.com" forKey:@"url"];
    [blog2 setValue:@"https://test1.wordpress.com/xmlrpc.php" forKey:@"xmlrpc"];
    XCTAssertNoThrow([blog2 setValue:@"Tagline" forKey:@"blogTagline"], @"Model 36 supports tagline");
    
    [context save:&error];
    XCTAssertNil(error, @"Error while saving context");
}

- (void)testMigrate40to41
{
    // Properties
    NSURL *model40Url = [self urlForModelName:@"WordPress 40" inDirectory:nil];
    NSURL *model41Url = [self urlForModelName:@"WordPress 41" inDirectory:nil];
    NSURL *storeUrl = [self urlForStoreWithName:@"WordPress40.sqlite"];
    
    // Load a Model 40 Stack
    NSManagedObjectModel *model40 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model40Url];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model40];
    
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
    
    // Migrate to Model 41
    NSManagedObjectModel *model41 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model41Url];
    BOOL migrateResult = [ALIterativeMigrator iterativeMigrateURL:storeUrl
                                                           ofType:NSSQLiteStoreType
                                                          toModel:model41
                                                orderedModelNames:@[@"WordPress 40", @"WordPress 41"]
                                                            error:&error];
    if (!migrateResult) {
        NSLog(@"Error while migrating: %@", error);
    }
    
    XCTAssertTrue(migrateResult);
    
    // Load a Model 41 Stack
    NSPersistentStoreCoordinator *psc41 = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model41];
    [psc41 addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error];
    
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc41;
    
    XCTAssertNil(error, @"Error while loading the PSC for Model 41");
    
    // Fetch the Notification
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Notification"];
    request.predicate = [NSPredicate predicateWithFormat:@"simperiumKey == %@", simperiumKey];
    
    NSArray *results = [context executeFetchRequest:request error:nil];
    XCTAssert(results.count == 1, @"Error Fetching Note");
    
    NSManagedObject *migratedNote = [results firstObject];
    XCTAssertEqualObjects([migratedNote valueForKey:@"id"], noteID, @"Oops?");
}

- (void)testMigrate41to42
{
    // Migrated Properties
    NSNumber *blogID                        = @(31337);
    NSString *blogName                      = @"Stark Industries";
    NSString *blogTagline                   = @"Jarvis is my Copilot";
    NSNumber *defaultCategoryID             = @(42);
    NSString *defaultPostFormat             = @"some-format";
    NSNumber *geolocationEnabled            = @(true);
    NSNumber *privacy                       = @(1);
    NSNumber *relatedPostsAllowed           = @(true);
    NSNumber *relatedPostsEnabled           = @(false);
    NSNumber *relatedPostsShowHeadline      = @(true);
    NSNumber *relatedPostsShowThumbnails    = @(false);
    NSString *url                           = @"http://tonystark-verified.wordpress.com";
    NSString *xmlrpc                        = @"http://tonystark-verified.wordpress.com/xmlrpc.php";
    
    NSDictionary *legacySettingsMap = @{
        @"blogID"                       : blogID,
        @"blogName"                     : blogName,
        @"blogTagline"                  : blogTagline,
        @"defaultCategoryID"            : defaultCategoryID,
        @"defaultPostFormat"            : defaultPostFormat,
        @"privacy"                      : privacy,
        @"relatedPostsAllowed"          : relatedPostsAllowed,
        @"relatedPostsEnabled"          : relatedPostsEnabled,
        @"relatedPostsShowHeadline"     : relatedPostsShowHeadline,
        @"relatedPostsShowThumbnails"   : relatedPostsShowThumbnails,
        @"geolocationEnabled"           : geolocationEnabled,
        @"url"                          : url,
        @"xmlrpc"                       : xmlrpc
    };
    
    NSDictionary *migratedSettingsMap = @{
        @"name"                         : blogName,
        @"tagline"                      : blogTagline,
        @"defaultCategoryID"            : defaultCategoryID,
        @"defaultPostFormat"            : defaultPostFormat,
        @"geolocationEnabled"           : geolocationEnabled,
        @"privacy"                      : privacy,
        @"relatedPostsAllowed"          : relatedPostsAllowed,
        @"relatedPostsEnabled"          : relatedPostsEnabled,
        @"relatedPostsShowHeadline"     : relatedPostsShowHeadline,
        @"relatedPostsShowThumbnails"   : relatedPostsShowThumbnails,
    };
    
    // Paths
    NSURL *model41Url = [self urlForModelName:@"WordPress 41" inDirectory:nil];
    NSURL *model42Url = [self urlForModelName:@"WordPress 42" inDirectory:nil];
    NSURL *storeUrl = [self urlForStoreWithName:@"WordPress41to42.sqlite"];
    
    // Load Model 40 and 41
    NSManagedObjectModel *model41 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model41Url];
    NSManagedObjectModel *model42 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model42Url];
    
    [self cleanModelObjectClassnames:model41];
    [self cleanModelObjectClassnames:model42];
    
    // New Model 40 Stack
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model41];
    
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
    
    XCTAssertNil(error, @"Error while loading the PSC for Model 40");
    XCTAssertNotNil(context, @"Invalid NSManagedObjectContext");
    
    
    NSManagedObject *blog = [NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:context];
    XCTAssertNoThrow([blog setValuesForKeysWithDictionary:legacySettingsMap], @"Something is very very wrong");
    XCTAssertThrows([blog valueForKey:@"settings"], @"Model 40 doesn't support Settings");
    
    [context save:&error];
    XCTAssertNil(error, @"Error while saving context");
    
    // Cleanup
    XCTAssertNotNil(ps);
    psc = nil;
    
    // Migrate to Model 42
    BOOL migrateResult = [ALIterativeMigrator iterativeMigrateURL:storeUrl
                                                           ofType:NSSQLiteStoreType
                                                          toModel:model42
                                                orderedModelNames:@[@"WordPress 41", @"WordPress 42"]
                                                            error:&error];
    if (!migrateResult) {
        NSLog(@"Error while migrating: %@", error);
    }

    XCTAssertTrue(migrateResult);
    
    // Load a Model 42 Stack
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model42];
    ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil
                                     URL:storeUrl
                                 options:options
                                   error:&error];
    
    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;
    
    XCTAssertNil(error, @"Error while loading the PSC for Model 41");
    XCTAssertNotNil(ps);
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Blog"];
    request.predicate = [NSPredicate predicateWithFormat:@"blogID == %@", blogID];
    
    // Verify the Heavyweight Migration: Blog Entity
    NSManagedObject *migratedBlog = [[context executeFetchRequest:request error:nil] firstObject];
    XCTAssertNotNil(migratedBlog, @"Oops");
    
    
    // Verify the Heavyweight Migration: BlogSettings Entity
    XCTAssertNoThrow([migratedBlog valueForKey:@"settings"], @"Model 42 supports BlogSettings");
    NSManagedObject *blogSettings = [migratedBlog valueForKey:@"settings"];
    
    for (NSString *key in migratedSettingsMap) {
        XCTAssertEqualObjects([blogSettings valueForKey:key], [migratedSettingsMap valueForKey:key], @"Oops");
    }
    
    XCTAssertNotNil([blogSettings valueForKey:@"blog"], @"Missing Blog");
}

- (void)testMigrate48to49DoesntLoosePersonEntities
{
    // Migrated Properties
    NSNumber *siteID = @(314);
    NSNumber *userID = @(4242);
    NSDictionary *propertiesMap = @{
        @"avatarURL"    : @"www.wordpress.com",
        @"displayName"  : @"tonystark",
        @"firstName"    : @"Tony",
        @"lastName"     : @"Stark",
        @"role"         : @"admin",
        @"username"     : @"tonystark",
        @"siteID"       : siteID,
        @"userID"       : userID,
    };

    // Paths
    NSURL *model48Url = [self urlForModelName:@"WordPress 48" inDirectory:nil];
    NSURL *model49Url = [self urlForModelName:@"WordPress 49" inDirectory:nil];
    NSURL *storeUrl = [self urlForStoreWithName:@"WordPress48to49.sqlite"];

    // Failsafe: Nuke previous DB
    [[NSFileManager defaultManager] removeItemAtURL:storeUrl error:nil];

    // Load Model 48 and 49
    NSManagedObjectModel *model48 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model48Url];
    NSManagedObjectModel *model49 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model49Url];

    [self cleanModelObjectClassnames:model48];
    [self cleanModelObjectClassnames:model49];

    // New Model 40 Stack
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model48];

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

    XCTAssertNil(error, @"Error while loading the PSC for Model 48");
    XCTAssertNotNil(context, @"Invalid NSManagedObjectContext");


    NSManagedObject *person = [NSEntityDescription insertNewObjectForEntityForName:@"Person" inManagedObjectContext:context];
    XCTAssertNoThrow([person setValuesForKeysWithDictionary:propertiesMap], @"Something is very very wrong");

    [context save:&error];
    XCTAssertNil(error, @"Error while saving context");

    // Cleanup
    XCTAssertNotNil(ps);
    psc = nil;

    // Migrate to Model 49
    BOOL migrateResult = [ALIterativeMigrator iterativeMigrateURL:storeUrl
                                                           ofType:NSSQLiteStoreType
                                                          toModel:model49
                                                orderedModelNames:@[@"WordPress 48", @"WordPress 49"]
                                                            error:&error];
    if (!migrateResult) {
        NSLog(@"Error while migrating: %@", error);
    }

    XCTAssertTrue(migrateResult);

    // Load a Model 42 Stack
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model49];
    ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil
                                     URL:storeUrl
                                 options:options
                                   error:&error];

    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;

    XCTAssertNil(error, @"Error while loading the PSC for Model 49");
    XCTAssertNotNil(ps);
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
    request.predicate = [NSPredicate predicateWithFormat:@"userID == %@", userID];
    
    // Verify the Heavyweight Migration: Blog Entity
    NSManagedObject *migratedBlog = [[context executeFetchRequest:request error:nil] firstObject];
    XCTAssertNotNil(migratedBlog, @"Oops");
    
    
    // Verify the Heavyweight Migration: Person Entity
    for (NSString *key in propertiesMap) {
        XCTAssertEqualObjects([migratedBlog valueForKey:key], [propertiesMap valueForKey:key], @"Oops");
    }
}

- (void)testMigrate52to53EffectivelyRemapsSimperiumKeyIntoNotificationIdProperty
{
    // Properties
    NSURL *model52Url = [self urlForModelName:@"WordPress 52" inDirectory:nil];
    NSURL *model53Url = [self urlForModelName:@"WordPress 53" inDirectory:nil];
    NSURL *storeUrl = [self urlForStoreWithName:@"WordPress52to53.sqlite"];

    // Load a Model 52 Stack
    NSManagedObjectModel *model52 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model52Url];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model52];

    NSDictionary *options = @{
        NSInferMappingModelAutomaticallyOption          : @(YES),
        NSMigratePersistentStoresAutomaticallyOption    : @(YES)
    };

    NSError *error = nil;
    [psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error];

    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;

    XCTAssertNil(error, @"Error while loading the PSC for Model 52");
    XCTAssertNotNil(context, @"Invalid NSManagedObjectContext");

    // Insert a Dummy Notification
    NSString *legacySimperiumKey = @"31337";

    NSManagedObject *note = [NSEntityDescription insertNewObjectForEntityForName:@"Notification" inManagedObjectContext:context];
    [note setValue:legacySimperiumKey forKey:@"simperiumKey"];
    [note setValue:@(true) forKey:@"read"];
    [context save:&error];
    XCTAssertNil(error, @"Error while saving context");

    // Migrate to Model 53
    NSManagedObjectModel *model53 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model53Url];
    BOOL migrateResult = [ALIterativeMigrator iterativeMigrateURL:storeUrl
                                                           ofType:NSSQLiteStoreType
                                                          toModel:model53
                                                orderedModelNames:@[@"WordPress 52", @"WordPress 53"]
                                                            error:&error];
    if (!migrateResult) {
        NSLog(@"Error while migrating: %@", error);
    }

    XCTAssertTrue(migrateResult);

    // Load a Model 53 Stack
    NSPersistentStoreCoordinator *psc53 = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model53];
    [psc53 addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:options error:&error];

    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc53;

    XCTAssertNil(error, @"Error while loading the PSC for Model 53");

    // Fetch the Notification
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Notification"];
    request.predicate = [NSPredicate predicateWithFormat:@"notificationId == %@", legacySimperiumKey];

    NSArray *results = [context executeFetchRequest:request error:nil];
    XCTAssert(results.count == 1, @"Error Fetching Note");

    NSManagedObject *migratedNote = [results firstObject];
    XCTAssertEqualObjects([migratedNote valueForKey:@"notificationId"], legacySimperiumKey, @"Oops?");
    XCTAssertEqualObjects([migratedNote valueForKey:@"read"], @(true), @"Oops?");
}

- (void)testMigrate74to75
{
    NSURL *model74Url = [self urlForModelName:@"WordPress 74" inDirectory:nil];
    NSURL *model75Url = [self urlForModelName:@"WordPress 75" inDirectory:nil];
    NSURL *storeUrl = [self urlForStoreWithName:@"WordPress74.sqlite"];

    // Load a Model 74 Stack
    NSManagedObjectModel *model74 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model74Url];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model74];

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

    XCTAssertNil(error, @"Error while loading the PSC for Model 74");
    XCTAssertNotNil(context, @"Invalid NSManagedObjectContext");

    // Pages and Media require a Blog, which requires an Account
    NSManagedObject *account1 = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:context];
    [account1 setValue:@"dotcomuser1" forKey:@"username"];

    NSManagedObject *blog1 = [NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:context];
    [blog1 setValue:@(1001) forKey:@"blogID"];
    [blog1 setValue:@"https://test1.wordpress.com" forKey:@"url"];
    [blog1 setValue:@"https://test1.wordpress.com/xmlrpc.php" forKey:@"xmlrpc"];
    [blog1 setValue:account1 forKey:@"account"];

    [context save:&error];
    XCTAssertNil(error, @"Error while saving context");

    // Cleanup
    XCTAssertNotNil(ps);
    psc = nil;

    // Migrate to Model 75
    NSManagedObjectModel *model75 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model75Url];
    BOOL migrateResult = [ALIterativeMigrator iterativeMigrateURL:storeUrl
                                                           ofType:NSSQLiteStoreType
                                                          toModel:model75
                                                orderedModelNames:@[@"WordPress 74", @"WordPress 75"]
                                                            error:&error];
    if (!migrateResult) {
        NSLog(@"Error while migrating: %@", error);
    }
    XCTAssertTrue(migrateResult);

    // Load a Model 75 Stack
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model75];
    ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil
                                     URL:storeUrl
                                 options:options
                                   error:&error];

    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;

    XCTAssertNil(error, @"Error while loading the PSC for Model 75");
    XCTAssertNotNil(ps);
}

- (void)testMigrate87to88
{
    NSURL *model87Url = [self urlForModelName:@"WordPress 87" inDirectory:nil];
    NSURL *model88Url = [self urlForModelName:@"WordPress 88" inDirectory:nil];
    NSURL *storeUrl = [self urlForStoreWithName:@"WordPress87.sqlite"];

        // Load a Model 74 Stack
    NSManagedObjectModel *model87 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model87Url];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model87];

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

    XCTAssertNil(error, @"Error while loading the PSC for Model 74");
    XCTAssertNotNil(context, @"Invalid NSManagedObjectContext");

    NSManagedObject *account1 = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:context];
    [account1 setValue:@"dotcomuser1" forKey:@"username"];

    //WPCom Blog
    NSManagedObject *blog1 = [NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:context];
    [blog1 setValue:@(1001) forKey:@"blogID"];
    [blog1 setValue:@"https://test1.wordpress.com" forKey:@"url"];
    [blog1 setValue:@"https://test1.wordpress.com/xmlrpc.php" forKey:@"xmlrpc"];
    [blog1 setValue:account1 forKey:@"account"];

    //SelfHosted Blog
    NSManagedObject *blog2 = [NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:context];
    [blog2 setValue:@(1002) forKey:@"blogID"];
    [blog2 setValue:@"https://test1.wordpress.com" forKey:@"url"];
    [blog2 setValue:@"https://test1.wordpress.com/xmlrpc.php" forKey:@"xmlrpc"];

    [context save:&error];
    XCTAssertNil(error, @"Error while saving context");

    // Cleanup
    XCTAssertNotNil(ps);
    psc = nil;

    // Migrate to Model 88
    NSManagedObjectModel *model88 = [[NSManagedObjectModel alloc] initWithContentsOfURL:model88Url];
    BOOL migrateResult = [ALIterativeMigrator iterativeMigrateURL:storeUrl
                                                           ofType:NSSQLiteStoreType
                                                          toModel:model88
                                                orderedModelNames:@[@"WordPress 87", @"WordPress 88"]
                                                            error:&error];
    if (!migrateResult) {
        NSLog(@"Error while migrating: %@", error);
    }
    XCTAssertTrue(migrateResult);

    // Load a Model 88 Stack
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model88];
    ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                           configuration:nil
                                     URL:storeUrl
                                 options:options
                                   error:&error];

    context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = psc;

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Blog"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"blogID" ascending:YES]];

    NSArray *results = [context executeFetchRequest:request error:nil];
    XCTAssert(results.count == 2, @"Error Fetching Blogs");

    // WPCom/Jetpack sites should migrate to Aztec

    NSManagedObject *wpcomBlog = [results firstObject];
    XCTAssertEqualObjects([wpcomBlog valueForKey:@"mobileEditor"], @"aztec");

    // SelfHosted (non-jetpack) should migrate to Aztec

    NSManagedObject *selfHostedBlog = [results lastObject];
    XCTAssertEqualObjects([selfHostedBlog valueForKey:@"mobileEditor"], @"aztec");

    XCTAssertNil(error, @"Error while loading the PSC for Model 88");
    XCTAssertNotNil(ps);
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
    BOOL migrateResult = [ALIterativeMigrator iterativeMigrateURL:storeUrl
                                                           ofType:NSSQLiteStoreType
                                                          toModel:model92
                                                orderedModelNames:@[@"WordPress 91", @"WordPress 92"]
                                                            error:&error];
    if (!migrateResult) {
        NSLog(@"Error while migrating: %@", error);
    }
    XCTAssertNil(error);
    XCTAssertTrue(migrateResult);

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
    request.predicate = [NSPredicate predicateWithFormat:predicate argumentArray:arguments];

    NSError *error = nil;
    NSArray *result = [self executeFetchRequest:request error:&error];

    if (error != nil) {
        NSLog(@"Fetch request returned error: %@", error);
    }
    NSCAssert(error == nil, @"Failed to execute fetch request.");

    return result;
}

@end
