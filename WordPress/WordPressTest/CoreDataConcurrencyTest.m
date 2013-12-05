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

    [WPAccount createOrUpdateWordPressComAccountWithUsername:@"test" andPassword:@"test" withContext:[ContextManager sharedInstance].mainContext];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
    
    [[CoreDataTestHelper sharedHelper] reset];
    [WPAccount removeDefaultWordPressComAccount];
}

- (void)testObjectExistenceInBackgroundFromMainSave
{
    ATHStart();
    
    Blog *blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityIntoMainContextWithName:@"Blog"];
    blog.xmlrpc = @"http://test.wordpress.com/xmlrpc.php";
    blog.url = @"http://test.wordpress.com/";
    blog.account = [WPAccount defaultWordPressComAccount];
    
    NSManagedObjectContext *mainMOC = [[ContextManager sharedInstance] mainContext];
    [[ContextManager sharedInstance] saveContext:mainMOC];
    
    ATHWait();
    
    XCTAssertFalse(blog.objectID.isTemporaryID, @"Object ID should be permanent");
    
    NSManagedObjectContext *bgMOC = [[ContextManager sharedInstance] backgroundContext];
    Blog *bgBlog = (Blog *)[bgMOC existingObjectWithID:blog.objectID error:nil];
    
    XCTAssertNotNil(bgBlog, @"Could not get object created in main thread in bg context");
    XCTAssertEqualObjects(bgBlog.url, @"http://test.wordpress.com/", @"Blog URLs not equal");
    XCTAssertEqualObjects(blog.objectID, bgBlog.objectID, @"BG cntxt obid diff");
    
    ATHEnd();
}

@end

@implementation ContextManager (Async)

+ (void)load {
    Method original = class_getInstanceMethod([ContextManager class], @selector(mergeChangesIntoBackgroundContext:));
    Method test = class_getInstanceMethod([ContextManager class], @selector(testMergeChangesIntoBackgroundContext:));
    
    method_exchangeImplementations(original, test);
}

- (void)testMergeChangesIntoBackgroundContext:(NSNotification *)notification {
    [self testMergeChangesIntoBackgroundContext:notification];
    ATHNotify();
}

@end