@import XCTest;
@import OHHTTPStubs;

#import "Blog.h"
#import "WPAccount.h"
#import "CoreDataStack.h"
#import "AccountService.h"
#import "BlogService.h"
#import "WordPressTest-Swift.h"

@import WordPressKit;

@interface BlogJetpackTest : XCTestCase
@end

@interface BlogJetpackTest ()

@property (nonatomic, strong) WPAccount *account;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) id<CoreDataStack> testContextManager;
@end

@implementation BlogJetpackTest

- (void)setUp {
    [super setUp];
    self.testContextManager = [self coreDataStackForTesting];

    _blog = (Blog *)[NSEntityDescription insertNewObjectForEntityForName:@"Blog"
                                                  inManagedObjectContext:self.testContextManager.mainContext];
    _blog.xmlrpc = @"http://test.blog/xmlrpc.php";
    _blog.username = @"admin";
    _blog.url = @"http://test.blog/";
    _blog.options = @{@"jetpack_version": @{
                              @"value": @"1.8.2",
                              @"desc": @"stub",
                              @"readonly": @YES,
                              },
                      @"jetpack_client_id": @{
                              @"value": @"3",
                              @"desc": @"stub",
                              @"readonly": @YES,
                              },
                      };
    _blog.settings = (BlogSettings *)[NSEntityDescription insertNewObjectForEntityForName:@"BlogSettings"
                                                                   inManagedObjectContext:self.testContextManager.mainContext];
}

- (void)tearDown {
    [super tearDown];

    _account = nil;
    _blog = nil;
    [HTTPStubs removeAllStubs];

    self.testContextManager = nil;
}

- (void)testJetpackInstalled {
    XCTAssertTrue(_blog.jetpack.isInstalled);
    _blog.options = nil;
    XCTAssertFalse(_blog.jetpack.isInstalled);
}

- (void)testJetpackVersion {
    XCTAssertEqualObjects(_blog.jetpack.version, @"1.8.2");
}

- (void)testJetpackSiteId {
    XCTAssertEqualObjects(_blog.jetpack.siteID, @3);
}

- (void)testJetpackUsername {
    XCTAssertNil(_blog.jetpack.connectedUsername);
}

- (void)testJetpackSetupDoesntReplaceDotcomAccount {
    AccountService *accountService = [[AccountService alloc] initWithCoreDataStack:self.testContextManager];
    NSManagedObjectID *accountID = [accountService createOrUpdateAccountWithUsername:@"user" authToken:@"token"];
    WPAccount *wpComAccount = [self.testContextManager.mainContext existingObjectWithID:accountID error:nil];

    WPAccount * defaultAccount = [WPAccount lookupDefaultWordPressComAccountInContext:self.testContextManager.mainContext];
    XCTAssertEqualObjects(wpComAccount, defaultAccount);

    [accountService createOrUpdateAccountWithUsername:@"test1" authToken:@"token1"];

    defaultAccount = [WPAccount lookupDefaultWordPressComAccountInContext:self.testContextManager.mainContext];;
    XCTAssertEqualObjects(wpComAccount, defaultAccount);
}

- (void)testWPCCShouldntDuplicateBlogs {
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.path hasSuffix:@"me/sites"];
    } withStubResponse:^HTTPStubsResponse *(NSURLRequest *request) {
        NSString* fixture = OHPathForFile(@"me-sites-with-jetpack.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:fixture
                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];

    AccountService *accountService = [[AccountService alloc] initWithCoreDataStack:self.testContextManager];
    BlogService *blogService = [[BlogService alloc] initWithCoreDataStack:self.testContextManager];
    NSManagedObjectID *accountID = [accountService createOrUpdateAccountWithUsername:@"user" authToken:@"token"];
    WPAccount *wpComAccount = [self.testContextManager.mainContext existingObjectWithID:accountID error:nil];

    Blog *dotcomBlog = [Blog createBlankBlogWithAccount:wpComAccount];
    dotcomBlog.xmlrpc = @"https://dotcom1.wordpress.com/xmlrpc.php";
    dotcomBlog.url = @"https://dotcom1.wordpress.com/";
    dotcomBlog.dotComID = @1;

    Blog *jetpackLegacyBlog = [Blog createBlankBlogInContext:self.testContextManager.mainContext];
    jetpackLegacyBlog.username = @"jetpack";
    jetpackLegacyBlog.xmlrpc = @"http://jetpack.example.com/xmlrpc.php";
    jetpackLegacyBlog.url = @"http://jetpack.example.com/";
    jetpackLegacyBlog.options = @{@"jetpack_version": @{
                                          @"value": @"1.8.2",
                                          @"desc": @"stub",
                                          @"readonly": @YES,
                                          },
                                  @"jetpack_client_id": @{
                                          @"value": @"2",
                                          @"desc": @"stub",
                                          @"readonly": @YES,
                                          },
                                  };

    [self.testContextManager saveContextAndWait:self.testContextManager.mainContext];

    // test.blog + wp.com + jetpack
    XCTAssertEqual(1, [WPAccount lookupNumberOfAccountsInContext:self.testContextManager.mainContext]);
    // test.blog + wp.com + jetpack (legacy)
    XCTAssertEqual(3, [Blog countInContext:self.testContextManager.mainContext]);
    // dotcom1.wordpress.com
    XCTAssertEqual(1, wpComAccount.blogs.count);
    Blog *testBlog = [[wpComAccount.blogs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"blogID = 1"]] anyObject];
    XCTAssertNotNil(testBlog);

    XCTestExpectation *syncExpectation = [self expectationWithDescription:@"Blogs sync"];
    [blogService syncBlogsForAccount:wpComAccount success:^{
        [syncExpectation fulfill];
    } failure:^(NSError *error) {
        XCTFail(@"Sync blogs shouldn't fail");
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    // test.blog + wp.com
    XCTAssertEqual(1, [WPAccount lookupNumberOfAccountsInContext:self.testContextManager.mainContext]);
    // dotcom1.wordpress.com + jetpack.example.com
    XCTAssertEqual(2, wpComAccount.blogs.count);
    // test.blog + wp.com + jetpack (wpcc)
    XCTAssertEqual(3, [Blog countInContext:self.testContextManager.mainContext]);

    testBlog = [[wpComAccount.blogs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"blogID = 1"]] anyObject];
    XCTAssertNotNil(testBlog);
    XCTAssertEqualObjects(testBlog.xmlrpc, @"https://dotcom1.wordpress.com/xmlrpc.php");
    testBlog = [[wpComAccount.blogs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"blogID = 2"]] anyObject];
    XCTAssertNotNil(testBlog);
    XCTAssertEqualObjects(testBlog.xmlrpc, @"http://jetpack.example.com/xmlrpc.php");
}

- (void)testSyncBlogsMigratesJetpackSSL
{
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.path hasSuffix:@"me/sites"];
    } withStubResponse:^HTTPStubsResponse *(NSURLRequest *request) {
        NSString* fixture = OHPathForFile(@"me-sites-with-jetpack.json", self.class);
        return [HTTPStubsResponse responseWithFileAtPath:fixture
                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];

    AccountService *accountService = [[AccountService alloc] initWithCoreDataStack:self.testContextManager];
    BlogService *blogService = [[BlogService alloc] initWithCoreDataStack:self.testContextManager];
    NSManagedObjectID *accountID = [accountService createOrUpdateAccountWithUsername:@"user" authToken:@"token"];
    WPAccount *wpComAccount = [self.testContextManager.mainContext existingObjectWithID:accountID error:nil];

    Blog *dotcomBlog = [Blog createBlankBlogWithAccount:wpComAccount];
    dotcomBlog.xmlrpc = @"http://dotcom1.wordpress.com/xmlrpc.php";
    dotcomBlog.url = @"http://dotcom1.wordpress.com/";
    dotcomBlog.dotComID = @1;

    Blog *jetpackBlog = [Blog createBlankBlogInContext:self.testContextManager.mainContext];
    jetpackBlog.username = @"jetpack";
    jetpackBlog.xmlrpc = @"https://jetpack.example.com/xmlrpc.php";
    jetpackBlog.url = @"https://jetpack.example.com/";

    [self.testContextManager saveContextAndWait:self.testContextManager.mainContext];

    XCTAssertEqual(1, [WPAccount lookupNumberOfAccountsInContext:self.testContextManager.mainContext]);
    // test.blog + wp.com + jetpack (legacy)
    XCTAssertEqual(3, [Blog countInContext:self.testContextManager.mainContext]);
    // dotcom1.wordpress.com
    XCTAssertEqual(1, wpComAccount.blogs.count);

    XCTestExpectation *syncExpectation = [self expectationWithDescription:@"Blogs sync"];
    [blogService syncBlogsForAccount:wpComAccount success:^{
        [syncExpectation fulfill];
    } failure:^(NSError *error) {
        XCTFail(@"Sync blogs shouldn't fail");
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    // test.blog + wp.com
    XCTAssertEqual(1, [WPAccount lookupNumberOfAccountsInContext:self.testContextManager.mainContext]);
    // dotcom1.wordpress.com + jetpack.example.com
    XCTAssertEqual(2, wpComAccount.blogs.count);
    // test.blog + wp.com + jetpack (wpcc)
    XCTAssertEqual(3, [Blog countInContext:self.testContextManager.mainContext]);
}

@end
