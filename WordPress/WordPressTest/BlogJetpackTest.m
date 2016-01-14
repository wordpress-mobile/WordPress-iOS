@import XCTest;
@import OHHTTPStubs;
@import OHHTTPStubs.OHPathHelpers;

#import "Blog.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "AccountService.h"
#import "BlogService.h"
#import "JetpackService.h"
#import "JetpackServiceRemote.h"
#import "TestContextManager.h"

@interface BlogJetpackTest : XCTestCase
@end

@interface BlogJetpackTest ()

@property (nonatomic, strong) WPAccount *account;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) TestContextManager *testContextManager;
@end

@implementation BlogJetpackTest

- (void)setUp {
    [super setUp];
    self.testContextManager = [[TestContextManager alloc] init];
    
    _blog = (Blog *)[NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:self.testContextManager.mainContext];
    _blog.xmlrpc = @"http://test.blog/xmlrpc.php";
    _blog.username = @"admin";
    _blog.url = @"http://test.blog/";
    _blog.options = @{@"jetpack_version": @{
                              @"value": @"1.8.2",
                              @"desc": @"stub",
                              @"readonly": @YES,
                              },
                      @"jetpack_client_id": @{
                              @"value": @"1",
                              @"desc": @"stub",
                              @"readonly": @YES,
                              },
                      };
    _blog.settings = (BlogSettings *)[NSEntityDescription insertNewObjectForEntityForName:@"BlogSettings" inManagedObjectContext:self.testContextManager.mainContext];
}

- (void)tearDown {
    [super tearDown];
    
    _account = nil;
    _blog = nil;
    [OHHTTPStubs removeAllStubs];

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
    XCTAssertEqualObjects(_blog.jetpack.siteID, @1);
}

- (void)testJetpackUsername {
    XCTAssertNil(_blog.jetpack.connectedUsername);
}

- (void)testValidateCredentials {
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] isEqualToString:@"https://public-api.wordpress.com/get-user-blogs/1.0?f=json"] &&
        [[request valueForHTTPHeaderField:@"Authorization"] isEqualToString:@"Basic dGVzdDE6dGVzdDE="]; // test1:test1
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString* fixture = OHPathForFile(@"get-user-blogs_doesnt-have-blog.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:fixture
                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];

    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] isEqualToString:@"https://public-api.wordpress.com/get-user-blogs/1.0?f=json"] &&
        [[request valueForHTTPHeaderField:@"Authorization"] isEqualToString:@"Basic dGVzdDI6dGVzdDI="]; // test2:test2
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString* fixture = OHPathForFile(@"get-user-blogs_has-blog.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:fixture
                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] isEqualToString:@"https://public-api.wordpress.com/oauth2/token"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString* fixture = OHPathForFile(@"authtoken.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:fixture
                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];
    
    XCTestExpectation *validateJetpackExpectation = [self expectationWithDescription:@"Validate Jetpack expectation"];

    JetpackService *jetpackService = [[JetpackService alloc] initWithManagedObjectContext:[ContextManager sharedInstance].mainContext];
    [jetpackService validateAndLoginWithUsername:@"test1"
                                        password:@"test1"
                                 multifactorCode:nil
                                          siteID:_blog.jetpack.siteID
                                         success:^(WPAccount *account) {
                                             XCTFail(@"User test1 shouldn't have access to test.blog");
                                             [validateJetpackExpectation fulfill];
                                         } failure:^(NSError *error) {
                                             XCTAssertEqual(error.domain, JetpackServiceRemoteErrorDomain);
                                             XCTAssertEqual(error.code, JetpackServiceRemoteErrorNoRecordForBlog);
                                             [validateJetpackExpectation fulfill];
                                         }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    validateJetpackExpectation = [self expectationWithDescription:@"Validate Jetpack expectation"];
    [jetpackService validateAndLoginWithUsername:@"test2"
                                        password:@"test2"
                                 multifactorCode:nil
                                          siteID:_blog.jetpack.siteID
                                         success:^(WPAccount *account) {
                                             [validateJetpackExpectation fulfill];
                                         } failure:^(NSError *error) {
                                             XCTFail(@"User test2 should have access to test.blog");
                                             [validateJetpackExpectation fulfill];
                                         }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testJetpackSetupDoesntReplaceDotcomAccount {
    XCTestExpectation *saveExpectation = [self expectationWithDescription:@"Context save expectation"];
    self.testContextManager.testExpectation = saveExpectation;

    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:[ContextManager sharedInstance].mainContext];
    WPAccount *wpComAccount = [accountService createOrUpdateAccountWithUsername:@"user" authToken:@"token"];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    WPAccount * defaultAccount = [accountService defaultWordPressComAccount];
    XCTAssertEqualObjects(wpComAccount, defaultAccount);

    saveExpectation = [self expectationWithDescription:@"Context save expectation"];
    self.testContextManager.testExpectation = saveExpectation;
    [accountService createOrUpdateAccountWithUsername:@"test1" authToken:@"token1"];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    defaultAccount = [accountService defaultWordPressComAccount];
    XCTAssertEqualObjects(wpComAccount, defaultAccount);
}

- (void)testWPCCShouldntDuplicateBlogs {
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.path hasSuffix:@"me/sites"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString* fixture = OHPathForFile(@"me-sites-with-jetpack.json", self.class);
        return [OHHTTPStubsResponse responseWithFileAtPath:fixture
                                                statusCode:200 headers:@{@"Content-Type":@"application/json"}];
    }];

    XCTestExpectation *saveExpectation = [self expectationWithDescription:@"Context save expectation"];
    self.testContextManager.testExpectation = saveExpectation;

    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:self.testContextManager.mainContext];
    BlogService *blogService = [[BlogService alloc] initWithManagedObjectContext:self.testContextManager.mainContext];
    WPAccount *wpComAccount = [accountService createOrUpdateAccountWithUsername:@"user" authToken:@"token"];

    Blog *dotcomBlog = [blogService createBlogWithAccount:wpComAccount];
    dotcomBlog.xmlrpc = @"http://dotcom1.wordpress.com/xmlrpc.php";
    dotcomBlog.url = @"http://dotcom1.wordpress.com/";
    dotcomBlog.dotComID = @1;

    Blog *jetpackLegacyBlog = [blogService createBlogWithAccount:nil];
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
    jetpackLegacyBlog.jetpackAccount = wpComAccount;

    // Wait on the merge to be completed
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    // test.blog + wp.com + jetpack
    XCTAssertEqual(1, [accountService numberOfAccounts]);
    // test.blog + wp.com + jetpack (legacy)
    XCTAssertEqual(3, [blogService blogCountForAllAccounts]);
    // dotcom1.wordpress.com
    XCTAssertEqual(1, wpComAccount.blogs.count);
    Blog *testBlog = [[wpComAccount.blogs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"blogID = 1"]] anyObject];
    XCTAssertNotNil(testBlog);
    XCTAssertEqual(1, wpComAccount.jetpackBlogs.count);
    XCTAssertEqual(wpComAccount.jetpackBlogs.anyObject, jetpackLegacyBlog);

    XCTestExpectation *syncExpectation = [self expectationWithDescription:@"Blogs sync"];
    [blogService syncBlogsForAccount:wpComAccount success:^{
        [syncExpectation fulfill];
    } failure:^(NSError *error) {
        XCTFail(@"Sync blogs shouldn't fail");
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    // test.blog + wp.com
    XCTAssertEqual(1, [accountService numberOfAccounts]);
    // dotcom1.wordpress.com + jetpack.example.com
    XCTAssertEqual(2, wpComAccount.blogs.count);
    XCTAssertEqual(0, wpComAccount.jetpackBlogs.count);
    // test.blog + wp.com + jetpack (wpcc)
    XCTAssertEqual(3, [blogService blogCountForAllAccounts]);

    testBlog = [[wpComAccount.blogs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"blogID = 1"]] anyObject];
    XCTAssertNotNil(testBlog);
    XCTAssertEqualObjects(testBlog.xmlrpc, @"https://dotcom1.wordpress.com/xmlrpc.php");
    testBlog = [[wpComAccount.blogs filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"blogID = 2"]] anyObject];
    XCTAssertNotNil(testBlog);
    XCTAssertEqualObjects(testBlog.xmlrpc, @"http://jetpack.example.com/xmlrpc.php");
}

@end
