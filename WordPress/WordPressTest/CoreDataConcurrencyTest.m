#import <XCTest/XCTest.h>
#import "Blog.h"
#import "WPAccount.h"
#import "AccountService.h"
#import "ContextManager.h"
#import <objc/runtime.h>
#import "TestContextManager.h"

@implementation WPAccount (CoreDataFakeApi)

- (WordPressComApi *)restApi {
    return nil;
}

@end

@interface CoreDataConcurrencyTest : XCTestCase

@property (nonatomic, strong) TestContextManager *testContextManager;

@end

@implementation CoreDataConcurrencyTest

- (void)setUp
{
    [super setUp];
    
    self.testContextManager = [TestContextManager new];

    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:[ContextManager sharedInstance].mainContext];
    WPAccount *account = [service createOrUpdateWordPressComAccountWithUsername:@"test" password:@"test" authToken:@"token"];

    [service setDefaultWordPressComAccount:account];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];

    // Cleans up values saved in NSUserDefaults
    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:[ContextManager sharedInstance].mainContext];
    if ([service defaultWordPressComAccount]) {
        [service removeDefaultWordPressComAccount];
    }

    self.testContextManager = nil;
}

- (void)testObjectPermanence {
    XCTestExpectation *saveExpectation = [self expectationWithDescription:@"Context save expectation"];
    self.testContextManager.testExpectation = saveExpectation;

    NSManagedObjectContext *derivedContext = [[ContextManager sharedInstance] newDerivedContext];
    Blog *blog = [self createTestBlogWithContext:derivedContext];
    [[ContextManager sharedInstance] saveDerivedContext:derivedContext];

    // Wait on the merge to be completed
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    XCTAssertFalse(blog.objectID.isTemporaryID, @"Object ID should be permanent");
}

- (void)testObjectExistenceInBackgroundFromMainSave
{
    XCTestExpectation *saveExpectation = [self expectationWithDescription:@"Context save expectation"];
    self.testContextManager.testExpectation = saveExpectation;
    
    NSManagedObjectContext *mainMOC = [[ContextManager sharedInstance] mainContext];
    Blog *blog = [self createTestBlogWithContext:mainMOC];
    [[ContextManager sharedInstance] saveContext:mainMOC];

    // Wait on the merge to be completed
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    XCTAssertFalse(blog.objectID.isTemporaryID, @"Object ID should be permanent");
    NSManagedObjectContext *bgMOC = [[ContextManager sharedInstance] newDerivedContext];
    Blog *bgBlog = (Blog *)[bgMOC existingObjectWithID:blog.objectID error:nil];
    
    XCTAssertNotNil(bgBlog, @"Could not get object created in main context in background context");
    XCTAssertNotNil(bgBlog.url, @"Blog data should not be nil");
    XCTAssertEqualObjects(blog.objectID, bgBlog.objectID, @"Main context objectID and background context object ID differ");
}

- (void)testObjectExistenceInMainFromBackgroundSave {
    NSManagedObjectContext *derivedContext = [[ContextManager sharedInstance] newDerivedContext];
    Blog *blog = [self createTestBlogWithContext:derivedContext];
    
    XCTestExpectation *saveExpectation = [self expectationWithDescription:@"Context save expectation"];
    self.testContextManager.testExpectation = saveExpectation;

    [[ContextManager sharedInstance] saveDerivedContext:derivedContext];
    
    // Wait on the merge to be completed
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    XCTAssertFalse(blog.objectID.isTemporaryID, @"Object ID should be permanent");
    
    NSManagedObjectContext *mainMOC = [[ContextManager sharedInstance] mainContext];
    Blog *mainBlog = (Blog *)[mainMOC existingObjectWithID:blog.objectID error:nil];
    
    XCTAssertNotNil(mainBlog, @"Could not get object created in background context in main context");
    XCTAssertNotNil(mainBlog.url, @"Blog should not be nil");
    XCTAssertEqualObjects(blog.objectID, mainBlog.objectID, @"Background context objectID and main context object ID differ");
}

- (void)testCrossContextObjects {
    NSManagedObjectContext *mainContext = [[ContextManager sharedInstance] mainContext];
    NSManagedObjectContext *derivedContext = [[ContextManager sharedInstance] newDerivedContext];

    // Create account in background context
    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:derivedContext];
    WPAccount *account = [service createOrUpdateWordPressComAccountWithUsername:@"test" password:@"test" authToken:@"token"];

    XCTestExpectation *saveExpectation = [self expectationWithDescription:@"Context save expectation"];
    self.testContextManager.testExpectation = saveExpectation;

    [[ContextManager sharedInstance] saveDerivedContext:derivedContext];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    // Check for existence in the main context
    WPAccount *mainAccount = (WPAccount *)[mainContext existingObjectWithID:account.objectID error:nil];
    XCTAssertNotNil(mainAccount, @"Could not retrieve account created in background context from main context");

    // Create a blog with the main context, add the main context account
    Blog *blog = (Blog *)[NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:self.testContextManager.mainContext];
    blog.xmlrpc = @"http://test.wordpress.com/xmlrpc.php";
    blog.url = @"http://test.wordpress.com/";
    blog.account = mainAccount;
    
    saveExpectation = [self expectationWithDescription:@"Context save expectation"];
    self.testContextManager.testExpectation = saveExpectation;

    // Check that the save completes
    XCTAssertNoThrow([[ContextManager sharedInstance] saveContext:mainContext], @"Saving should be successful");
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    XCTAssertFalse(blog.objectID.isTemporaryID, @"Blog object ID should be permanent");
    Blog *backgroundBlog = (Blog *)[derivedContext existingObjectWithID:blog.objectID error:nil];

    XCTAssertNotNil(backgroundBlog, @"Blog should exist in background context");
}

- (void)testCrossContextDeletion {
    NSManagedObjectContext *mainContext = [ContextManager sharedInstance].mainContext;

    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:mainContext];
    XCTAssertNotNil([service defaultWordPressComAccount], @"Account should be present");
    XCTAssertEqualObjects([service defaultWordPressComAccount].managedObjectContext, [ContextManager sharedInstance].mainContext, @"Account should have been created on main context");
    
    XCTestExpectation *saveExpectation = [self expectationWithDescription:@"Context save expectation"];
    self.testContextManager.testExpectation = saveExpectation;

    NSManagedObjectID *accountID = [service defaultWordPressComAccount].objectID;
    [mainContext performBlockAndWait:^{
        [service removeDefaultWordPressComAccount];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // Ensure object deleted in background context as well
    saveExpectation = [self expectationWithDescription:@"Context save expectation"];
    
    NSManagedObjectContext *derivedContext = [[ContextManager sharedInstance] newDerivedContext];
    [derivedContext performBlockAndWait:^{
        WPAccount *backgroundAccount = (WPAccount *)[derivedContext existingObjectWithID:accountID error:nil];
        XCTAssertTrue(backgroundAccount == nil || backgroundAccount.isDeleted, @"Account should be considered deleted");
        [saveExpectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
}

- (void)testDerivedContext {
    // Create a new derived context, which the mainContext is the parent
    XCTestExpectation *saveExpectation = [self expectationWithDescription:@"Context save expectation"];
    XCTestExpectation *derivedSaveExpectation = [self expectationWithDescription:@"Derived context save expectation"];
    self.testContextManager.testExpectation = saveExpectation;

    NSManagedObjectContext *derived = [[ContextManager sharedInstance] newDerivedContext];
    __block NSManagedObjectID *blogObjectID;
    __block Blog *newBlog;
    __block AccountService *service;
    [derived performBlock:^{
        service = [[AccountService alloc] initWithManagedObjectContext:derived];
        WPAccount *derivedAccount = (WPAccount *)[derived objectWithID:[service defaultWordPressComAccount].objectID];
        XCTAssertNoThrow(derivedAccount.username, @"Should be able to access properties from this context");

        NSString *xmlrpc = @"http://blog.com/xmlrpc.php";
        NSString *url = @"blog.com";
        newBlog = [service findBlogWithXmlrpc:xmlrpc inAccount:derivedAccount];
        if (!newBlog) {
            newBlog = [service createBlogWithAccount:derivedAccount];
            newBlog.xmlrpc = xmlrpc;
            newBlog.url = url;
        }
        [[ContextManager sharedInstance] saveDerivedContext:derived withCompletionBlock:^{
            // object exists in main context after derived's save
            // don't notify, wait for main's save ATHNotify()
            
            Blog *mainContextBlog =  (Blog *)[[ContextManager sharedInstance].mainContext existingObjectWithID:newBlog.objectID error:nil];
            XCTAssertNotNil(mainContextBlog, @"The new blog should exist in the main (parent) context");
            [derivedSaveExpectation fulfill];
        }];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

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
    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *account = [service defaultWordPressComAccount];

    NSString *xmlrpc = @"http://test.wordpress.com/xmlrpc.php";
    NSString *url = @"http://test.wordpress.com/";
    NSNumber *blogid = @(1);
    Blog *newBlog = [service findBlogWithXmlrpc:xmlrpc inAccount:account];
    if (!newBlog) {
        newBlog = [service createBlogWithAccount:account];
        newBlog.xmlrpc = xmlrpc;
        newBlog.url = url;
        newBlog.blogID = blogid;
    }

    return newBlog;
}

@end
