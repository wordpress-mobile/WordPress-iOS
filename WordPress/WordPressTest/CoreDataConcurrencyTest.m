#import <XCTest/XCTest.h>
#import "CoreDataTestHelper.h"
#import "Blog.h"
#import "AsyncTestHelper.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import <objc/runtime.h>

@implementation WPAccount (CoreDataFakeApi)

- (WordPressComApi *)restApi {
    return nil;
}

@end

@interface CoreDataConcurrencyTest : XCTestCase
@end

@implementation CoreDataConcurrencyTest

- (void)setUp
{
    [super setUp];

    ATHStart();
    
    WPAccount *account = [WPAccount createOrUpdateWordPressComAccountWithUsername:@"test" password:@"test" authToken:@"token" context:[ContextManager sharedInstance].mainContext];
    
    ATHEnd();
    [WPAccount setDefaultWordPressComAccount:account];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
    
    [[CoreDataTestHelper sharedHelper] reset];
    
    // Remove cached __defaultDotcomAccount, no need to remove core data value
    // Exception occurs if attempted: the persistent stores are swapped in reset
    // and the contexts are destroyed
    [WPAccount removeDefaultWordPressComAccountWithContext:nil];
}

- (void)testObjectPermanence {
    ATHStart();
    
    NSManagedObjectContext *backgroundMOC = [[ContextManager sharedInstance] mainContext];
    Blog *blog = [self createTestBlogWithContext:backgroundMOC];
    [[ContextManager sharedInstance] saveContext:backgroundMOC];
    
    // Wait on the merge to be completed
    ATHEnd();
    
    XCTAssertFalse(blog.objectID.isTemporaryID, @"Object ID should be permanent");
}

- (void)testObjectExistenceInBackgroundFromMainSave
{
    ATHStart();
    
    NSManagedObjectContext *mainMOC = [[ContextManager sharedInstance] mainContext];
    Blog *blog = [self createTestBlogWithContext:mainMOC];
    [[ContextManager sharedInstance] saveContext:mainMOC];
    
    // Wait on the merge to be completed
    ATHEnd();
    
    XCTAssertFalse(blog.objectID.isTemporaryID, @"Object ID should be permanent");
    
    NSManagedObjectContext *bgMOC = [[ContextManager sharedInstance] backgroundContext];
    Blog *bgBlog = (Blog *)[bgMOC existingObjectWithID:blog.objectID error:nil];
    
    XCTAssertNotNil(bgBlog, @"Could not get object created in main context in background context");
    XCTAssertNotNil(bgBlog.url, @"Blog data should not be nil");
    XCTAssertEqualObjects(blog.objectID, bgBlog.objectID, @"Main context objectID and background context object ID differ");
}

- (void)testObjectExistenceInMainFromBackgroundSave {
    ATHStart();
    
    NSManagedObjectContext *backgroundMOC = [[ContextManager sharedInstance] backgroundContext];
    Blog *blog = [self createTestBlogWithContext:backgroundMOC];
    [[ContextManager sharedInstance] saveContext:backgroundMOC];
    
    // Wait on the merge to be completed
    ATHEnd();
    
    XCTAssertFalse(blog.objectID.isTemporaryID, @"Object ID should be permanent");
    
    NSManagedObjectContext *mainMOC = [[ContextManager sharedInstance] mainContext];
    Blog *mainBlog = (Blog *)[mainMOC existingObjectWithID:blog.objectID error:nil];
    
    XCTAssertNotNil(mainBlog, @"Could not get object created in background context in main context");
    XCTAssertNotNil(mainBlog.url, @"Blog should not be nil");
    XCTAssertEqualObjects(blog.objectID, mainBlog.objectID, @"Background context objectID and main context object ID differ");
}

- (void)testCrossContextObjects {
    NSManagedObjectContext *mainMOC = [[ContextManager sharedInstance] mainContext];
    NSManagedObjectContext *backgroundMOC = [[ContextManager sharedInstance] backgroundContext];
    
    ATHStart();
    
    // Create account in background context
    WPAccount *account = [WPAccount createOrUpdateWordPressComAccountWithUsername:@"test" password:@"test" authToken:@"token"
                                                                      context:backgroundMOC];

    ATHWait();
    
    // Check for existence in the main context
    WPAccount *mainAccount = (WPAccount *)[mainMOC existingObjectWithID:account.objectID error:nil];
    XCTAssertNotNil(mainAccount, @"Could not retrieve account created in background context from main context");

    // Create a blog with the main context, add the main context account
    Blog *blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityIntoMainContextWithName:@"Blog"];
    blog.xmlrpc = @"http://test.wordpress.com/xmlrpc.php";
    blog.url = @"http://test.wordpress.com/";
    blog.account = mainAccount;
    
    // Check that the save completes
    XCTAssertNoThrow([[ContextManager sharedInstance] saveContext:mainMOC], @"Saving should be successful");
    
    ATHEnd();
    
    XCTAssertFalse(blog.objectID.isTemporaryID, @"Blog object ID should be permanent");
    Blog *backgroundBlog = (Blog *)[backgroundMOC existingObjectWithID:blog.objectID error:nil];

    XCTAssertNotNil(backgroundBlog, @"Blog should exist in background context");
}

- (void)testCrossContextDeletion {
    NSManagedObjectContext *mainContext = [ContextManager sharedInstance].mainContext;
    
    XCTAssertNotNil([WPAccount defaultWordPressComAccount], @"Account should be present");
    XCTAssertEqualObjects([WPAccount defaultWordPressComAccount].managedObjectContext, [ContextManager sharedInstance].mainContext, @"Account should have been created on main context");
    
    ATHStart();
    NSManagedObjectID *accountID = [WPAccount defaultWordPressComAccount].objectID;
    [mainContext performBlock:^{
        [WPAccount removeDefaultWordPressComAccountWithContext:mainContext];
    }];
    ATHEnd();

    // Ensure object deleted in background context as well
    ATHStart();
    NSManagedObjectContext *backgroundContext = [ContextManager sharedInstance].backgroundContext;
    [backgroundContext performBlock:^{
        WPAccount *backgroundAccount = (WPAccount *)[backgroundContext objectWithID:accountID];
        XCTAssertTrue(backgroundAccount.isDeleted, @"Account should be considered deleted");
        ATHNotify();
    }];
    ATHEnd();
}

- (void)testDerivedContext {
    // Create a new derived context, which the mainContext is the parent
    ATHStart();
    NSManagedObjectContext *derived = [[ContextManager sharedInstance] newDerivedContext];
    __block NSManagedObjectID *blogObjectID;
    __block Blog *newBlog;
    [derived performBlock:^{
        WPAccount *derivedAccount = (WPAccount *)[derived objectWithID:[WPAccount defaultWordPressComAccount].objectID];
        XCTAssertNoThrow(derivedAccount.username, @"Should be able to access properties from this context");
        
        newBlog = [derivedAccount findOrCreateBlogFromDictionary:@{@"xmlrpc": @"http://blog.com/xmlrpc.php", @"url": @"blog.com"} withContext:derived];
        [[ContextManager sharedInstance] saveDerivedContext:derived withCompletionBlock:^{
            // object exists in main context after derived's save
            // don't notify, wait for main's save ATHNotify()
            
            Blog *mainContextBlog =  (Blog *)[[ContextManager sharedInstance].mainContext existingObjectWithID:newBlog.objectID error:nil];
            XCTAssertNotNil(mainContextBlog, @"The new blog should exist in the main (parent) context");
        }];
    }];
    ATHEnd();
    
    // Should be accessible in both contexts: main, background
    blogObjectID = newBlog.objectID;
    XCTAssertFalse(blogObjectID.isTemporaryID, @"Object should be permanent");
    
    // Check the object exists in the parent context: mainContext
    Blog *existingBlog = (Blog *)[[ContextManager sharedInstance].mainContext existingObjectWithID:blogObjectID error:nil];
    XCTAssertNotNil(existingBlog, @"Object should exist in parent context");
    XCTAssertNoThrow(existingBlog.url, @"Object should be accessible");
    XCTAssertEqualObjects(existingBlog.url, @"blog.com", @"Data should be maintained between contexts");
}


#pragma mark - Helpers

- (Blog *)createTestBlogWithContext:(NSManagedObjectContext *)context {
    WPAccount *account = [WPAccount defaultWordPressComAccount];
    NSDictionary *blogDictionary = @{@"blogid": @(1),
                                     @"url": @"http://test.wordpress.com/",
                                     @"xmlrpc": @"http://test.wordpress.com/xmlrpc.php"};
    return [account findOrCreateBlogFromDictionary:blogDictionary withContext:context];
}

@end