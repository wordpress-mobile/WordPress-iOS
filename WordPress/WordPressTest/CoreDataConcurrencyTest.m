#import <XCTest/XCTest.h>
#import "CoreDataTestHelper.h"
#import "Blog.h"
#import "AsyncTestHelper.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import <objc/runtime.h>



@interface CoreDataConcurrencyTest : XCTestCase
@end

@implementation CoreDataConcurrencyTest

- (void)setUp
{
    [super setUp];
    
    WPAccount *account = [WPAccount createOrUpdateWordPressComAccountWithUsername:@"test" password:@"test" authToken:@"token"];
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
    [WPAccount removeDefaultWordPressComAccount];
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
    [[ContextManager sharedInstance] saveContext:mainMOC withCompletionBlock:^{
		ATHNotify();
	}];
    
    // Wait on the save to be completed
    ATHEnd();
    
    XCTAssertFalse(blog.objectID.isTemporaryID, @"Object ID should be permanent");
    
    NSManagedObjectContext *derivedMOC = [[ContextManager sharedInstance] newDerivedContext];
	[derivedMOC performBlockAndWait:^{
		Blog *bgBlog = (Blog *)[derivedMOC existingObjectWithID:blog.objectID error:nil];
		
		XCTAssertNotNil(bgBlog, @"Could not get object created in main context in background context");
		XCTAssertNotNil(bgBlog.url, @"Blog data should not be nil");
		XCTAssertEqualObjects(blog.objectID, bgBlog.objectID, @"Main context objectID and background context object ID differ");
	}];
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
    NSManagedObjectContext *mainMOC = [[ContextManager sharedInstance] mainContext];
	NSManagedObjectContext *derivedMOC = [[ContextManager sharedInstance] newDerivedContext];
    
    // Create account in main context
    WPAccount *account = [WPAccount createOrUpdateWordPressComAccountWithUsername:@"test" password:@"test" authToken:@"token"];
    
    // Check for existence in a BG context
	[derivedMOC performBlockAndWait:^{
		WPAccount *derivedAccount = (WPAccount *)[mainMOC existingObjectWithID:account.objectID error:nil];
		XCTAssertNotNil(derivedAccount, @"Could not retrieve account created in background context from main context");
	}];

    // Create a blog with the main context, add the main context account
    Blog *blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityIntoMainContextWithName:@"Blog"];
    blog.xmlrpc = @"http://test.wordpress.com/xmlrpc.php";
    blog.url = @"http://test.wordpress.com/";
    blog.account = account;
    
    // Check that the save completes
    ATHStart();

    XCTAssertNoThrow([[ContextManager sharedInstance] saveContext:mainMOC withCompletionBlock:^{
		ATHNotify();
	}], @"Saving should be successful");
    
    ATHEnd();
    
    XCTAssertFalse(blog.objectID.isTemporaryID, @"Blog object ID should be permanent");
}

- (void)testCrossContextDeletion {
    XCTAssertNotNil([WPAccount defaultWordPressComAccount], @"Account should be present");
    XCTAssertEqualObjects([WPAccount defaultWordPressComAccount].managedObjectContext, [ContextManager sharedInstance].mainContext, @"Account should have been created on main context");
    
    NSManagedObjectContext *mainContext = [ContextManager sharedInstance].mainContext;
	NSManagedObject *mainAccount = [WPAccount defaultWordPressComAccount];
	[mainContext deleteObject:mainAccount];
	
	ATHStart();
	[[ContextManager sharedInstance] saveContext:mainContext withCompletionBlock:^{
		ATHNotify();
	}];
	ATHEnd();
	
    // Ensure object deleted in background context as well
    ATHStart();
    NSManagedObjectContext *derivedContext = [[ContextManager sharedInstance] newDerivedContext];
    [derivedContext performBlock:^{
        WPAccount *backgroundAccount = (WPAccount *)[derivedContext existingObjectWithID:mainAccount.objectID error:nil];
        XCTAssertNil(backgroundAccount, @"Account should be considered deleted");
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
    WPAccount *account = [WPAccount defaultWordPressComAccount];
    NSDictionary *blogDictionary = @{@"blogid": @(1),
                                     @"url": @"http://test.wordpress.com/",
                                     @"xmlrpc": @"http://test.wordpress.com/xmlrpc.php"};
    return [account findOrCreateBlogFromDictionary:blogDictionary withContext:context];
}

@end