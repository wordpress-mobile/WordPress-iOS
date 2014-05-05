#import <XCTest/XCTest.h>
#import "CoreDataTestHelper.h"
#import "Blog.h"
#import "AsyncTestHelper.h"
#import "WPAccount.h"
#import "AccountService.h"
#import "ContextManager.h"
#import <objc/runtime.h>



@interface CoreDataConcurrencyTest : XCTestCase
@end

@implementation CoreDataConcurrencyTest

- (void)setUp
{
    [super setUp];

    ATHStart();
    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:[ContextManager sharedInstance].mainContext];
    WPAccount *account = [service createOrUpdateWordPressComAccountWithUsername:@"test" password:@"test" authToken:@"token"];

    ATHEnd();
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

    [[CoreDataTestHelper sharedHelper] reset];
}

- (void)testObjectPermanence {
    ATHStart();
    
    NSManagedObjectContext *mainMOC = [[ContextManager sharedInstance] mainContext];
    Blog *blog = [self createTestBlogWithContext:mainMOC];
    [[ContextManager sharedInstance] saveContext:mainMOC withCompletionBlock:^{
		ATHNotify();
	}];
    
    // Wait on the save operation to be completed
    ATHEnd();
    
    XCTAssertFalse(blog.objectID.isTemporaryID, @"Object ID should be permanent");
}

- (void)testObjectExistenceInDerivedFromMainSave
{
    ATHStart();
    
    NSManagedObjectContext *mainMOC = [[ContextManager sharedInstance] mainContext];
    Blog *blog = [self createTestBlogWithContext:mainMOC];
    [[ContextManager sharedInstance] saveContext:mainMOC];

    // Wait on the merge to be completed
    ATHEnd();
    
    XCTAssertFalse(blog.objectID.isTemporaryID, @"Object ID should be permanent");
    NSManagedObjectContext *bgMOC = [[ContextManager sharedInstance] newDerivedContext];
    Blog *bgBlog = (Blog *)[bgMOC existingObjectWithID:blog.objectID error:nil];
    
    XCTAssertNotNil(bgBlog, @"Could not get object created in main context in background context");
    XCTAssertNotNil(bgBlog.url, @"Blog data should not be nil");
    XCTAssertEqualObjects(blog.objectID, bgBlog.objectID, @"Main context objectID and background context object ID differ");
}

- (void)testObjectExistenceInMainFromDerivedSave {
    ATHStart();
    
    NSManagedObjectContext *derivedMOC = [[ContextManager sharedInstance] newDerivedContext];
    Blog *blog = [self createTestBlogWithContext:derivedMOC];
    [[ContextManager sharedInstance] saveDerivedContext:derivedMOC withCompletionBlock:^{
		ATHNotify();
	}];
    
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
    NSManagedObjectContext *mainContext = [[ContextManager sharedInstance] mainContext];
    NSManagedObjectContext *derivedContext = [[ContextManager sharedInstance] newDerivedContext];

    // Create account in background context
    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:derivedContext];
    WPAccount *account = [service createOrUpdateWordPressComAccountWithUsername:@"test" password:@"test" authToken:@"token"];

    ATHStart();
    [[ContextManager sharedInstance] saveDerivedContext:derivedContext];
    ATHWait();
    
    // Check for existence in the main context
    WPAccount *mainAccount = (WPAccount *)[mainContext existingObjectWithID:account.objectID error:nil];
    XCTAssertNotNil(mainAccount, @"Could not retrieve account created in background context from main context");

    // Create a blog with the main context, add the main context account
    Blog *blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityIntoMainContextWithName:@"Blog"];
    blog.xmlrpc = @"http://test.wordpress.com/xmlrpc.php";
    blog.url = @"http://test.wordpress.com/";
    blog.account = mainAccount;
    
    // Check that the save completes
    ATHStart();

    XCTAssertNoThrow([[ContextManager sharedInstance] saveContext:mainContext withCompletionBlock:^{
		ATHNotify();
	}], @"Saving should be successful");
    
    ATHEnd();
    
    XCTAssertFalse(blog.objectID.isTemporaryID, @"Blog object ID should be permanent");
    Blog *backgroundBlog = (Blog *)[derivedContext existingObjectWithID:blog.objectID error:nil];
    
    XCTAssertNotNil(backgroundBlog, @"Blog should exist in background context");
}

- (void)testCrossContextDeletion {
    NSManagedObjectContext *mainContext = [ContextManager sharedInstance].mainContext;

    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:mainContext];
    XCTAssertNotNil([service defaultWordPressComAccount], @"Account should be present");
    XCTAssertEqualObjects([service defaultWordPressComAccount].managedObjectContext, [ContextManager sharedInstance].mainContext, @"Account should have been created on main context");
    
    ATHStart();
    NSManagedObjectID *accountID = [service defaultWordPressComAccount].objectID;
    [mainContext performBlockAndWait:^{
        [service removeDefaultWordPressComAccount];
    }];
    ATHEnd();

    // Ensure object deleted in background context as well
    ATHStart();
    NSManagedObjectContext *derivedContext = [[ContextManager sharedInstance] newDerivedContext];
    [derivedContext performBlockAndWait:^{
        WPAccount *backgroundAccount = (WPAccount *)[derivedContext existingObjectWithID:accountID error:nil];
        XCTAssertTrue(backgroundAccount == nil || backgroundAccount.isDeleted, @"Account should be considered deleted");
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
    __block AccountService *service;
    [derived performBlock:^{
        service = [[AccountService alloc] initWithManagedObjectContext:derived];
        WPAccount *derivedAccount = (WPAccount *)[derived objectWithID:[service defaultWordPressComAccount].objectID];
        XCTAssertNoThrow(derivedAccount.username, @"Should be able to access properties from this context");

        newBlog = [service findOrCreateBlogFromDictionary:@{@"xmlrpc": @"http://blog.com/xmlrpc.php", @"url": @"blog.com"} withAccount:derivedAccount];
        [[ContextManager sharedInstance] saveDerivedContext:derived withCompletionBlock:^{
            // object exists in main context after derived's save
            // don't notify, wait for main's save ATHNotify()
            
            Blog *mainContextBlog =  (Blog *)[[ContextManager sharedInstance].mainContext existingObjectWithID:newBlog.objectID error:nil];
            XCTAssertNotNil(mainContextBlog, @"The new blog should exist in the main (parent) context");
			ATHNotify();
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
    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *account = [service defaultWordPressComAccount];
    NSDictionary *blogDictionary = @{@"blogid": @(1),
                                     @"url": @"http://test.wordpress.com/",
                                     @"xmlrpc": @"http://test.wordpress.com/xmlrpc.php"};
    return [service findOrCreateBlogFromDictionary:blogDictionary withAccount:account];
}

@end
