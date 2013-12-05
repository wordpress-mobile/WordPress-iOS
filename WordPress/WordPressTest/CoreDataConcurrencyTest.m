//
//  CoreDataConcurrencyTest.m
//  WordPress
//
//  Copyright (c) 2013 WordPress. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CoreDataTestHelper.h"
#import "Blog.h"
#import "AsyncTestHelper.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import <objc/runtime.h>

@interface CoreDataConcurrencyTest : XCTestCase

@end

@interface ContextManager (Async)
@end

@implementation CoreDataConcurrencyTest

- (void)setUp
{
    [super setUp];

    ATHStart();
    
    [WPAccount createOrUpdateWordPressComAccountWithUsername:@"test" andPassword:@"test" withContext:[ContextManager sharedInstance].mainContext];
    
    ATHEnd();
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
    
    [[CoreDataTestHelper sharedHelper] reset];
    
    [WPAccount removeDefaultWordPressComAccountWithContext:[ContextManager sharedInstance].mainContext];
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

- (Blog *)createTestBlogWithContext:(NSManagedObjectContext *)context {
    WPAccount *account = [WPAccount defaultWordPressComAccount];
    NSDictionary *blogDictionary = @{@"blogid": @(1),
                                     @"url": @"http://test.wordpress.com/",
                                     @"xmlrpc": @"http://test.wordpress.com/xmlrpc.php"};
    return [account findOrCreateBlogFromDictionary:blogDictionary withContext:context];
}

@end

@implementation ContextManager (Async)

+ (void)load {
    Method originalMainToBg = class_getInstanceMethod([ContextManager class], @selector(mergeChangesIntoBackgroundContext:));
    Method testMainToBg = class_getInstanceMethod([ContextManager class], @selector(testMergeChangesIntoBackgroundContext:));
    Method originalBgToMain = class_getInstanceMethod([ContextManager class], @selector(mergeChangesIntoMainContext:));
    Method testBgToMain = class_getInstanceMethod([ContextManager class], @selector(testMergeChangesIntoMainContext:));
    
    method_exchangeImplementations(originalMainToBg, testMainToBg);
    method_exchangeImplementations(originalBgToMain, testBgToMain);
}

- (void)testMergeChangesIntoBackgroundContext:(NSNotification *)notification {
    [self testMergeChangesIntoBackgroundContext:notification];
    if (ATHSemaphore) {
        ATHNotify();
    }
}

- (void)testMergeChangesIntoMainContext:(NSNotification *)notification {
    [self testMergeChangesIntoMainContext:notification];
    if (ATHSemaphore) {
        ATHNotify();
    }
}

@end