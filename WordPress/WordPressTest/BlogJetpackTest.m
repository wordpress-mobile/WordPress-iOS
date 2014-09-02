#import <OHHTTPStubs/OHHTTPStubs.h>
#import "CoreDataTestHelper.h"
#import "Blog+Jetpack.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "AccountService.h"
#import <XCTest/XCTest.h>

@interface BlogJetpackTest : XCTestCase
@end

@interface BlogJetpackTest ()

@property (nonatomic, strong) WPAccount *account;
@property (nonatomic, strong) Blog *blog;

@end

@implementation BlogJetpackTest

- (void)setUp {
    [super setUp];
    
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:[ContextManager sharedInstance].mainContext];
    _account = [accountService createOrUpdateSelfHostedAccountWithXmlrpc:@"http://blog1.com/xmlrpc.php" username:@"admin" andPassword:@"password!"];

    _blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityIntoMainContextWithName:@"Blog"];
    _blog.xmlrpc = @"http://test.blog/xmlrpc.php";
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
    _blog.account = _account;
}

- (void)tearDown {
    [super tearDown];
    
    _account = nil;
    _blog = nil;
    [OHHTTPStubs removeAllRequestHandlers];
    
    [[CoreDataTestHelper sharedHelper] reset];
    [CoreDataTestHelper sharedHelper].testExpectation = nil;
}

- (void)testAssertionsOnWPcom {
    XCTestExpectation *saveExpectation = [self expectationWithDescription:@"Context save expectation"];
    [CoreDataTestHelper sharedHelper].testExpectation = saveExpectation;

    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:[ContextManager sharedInstance].mainContext];
    WPAccount *wpComAccount = [accountService createOrUpdateWordPressComAccountWithUsername:@"user" password:@"pass" authToken:@"token"];

    // Wait on the merge to be completed
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    _blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityIntoMainContextWithName:@"Blog"];
    _blog.xmlrpc = @"http://test.wordpress.com/xmlrpc.php";
    _blog.url = @"http://test.wordpress.com/";
    _blog.account = wpComAccount;
    
    XCTAssertThrows([_blog hasJetpack], @"WordPress.com blogs don't support Jetpack methods");
    XCTAssertThrows([_blog jetpackVersion], @"WordPress.com blogs don't support Jetpack methods");
    XCTAssertThrows([_blog jetpackUsername], @"WordPress.com blogs don't support Jetpack methods");
    XCTAssertThrows([_blog jetpackPassword], @"WordPress.com blogs don't support Jetpack methods");
    XCTAssertThrows([_blog jetpackBlogID], @"WordPress.com blogs don't support Jetpack methods");
    XCTAssertThrows([_blog removeJetpackCredentials], @"WordPress.com blogs don't support Jetpack methods");
    XCTAssertThrows([_blog validateJetpackUsername:@"test" password:@"test" success:nil failure:nil], @"WordPress.com blogs don't support Jetpack methods");
}

- (void)testHasJetpack {
    XCTAssertTrue([_blog hasJetpack]);
    _blog.options = nil;
    XCTAssertFalse([_blog hasJetpack]);
}

- (void)testJetpackVersion {
    XCTAssertEqualObjects([_blog jetpackVersion], @"1.8.2");
}

- (void)testJetpackBlogId {
    XCTAssertEqualObjects([_blog jetpackBlogID], @1);
}

- (void)testJetpackUsername {
    XCTAssertNil([_blog jetpackUsername]);
}

- (void)testJetpackPassword {
    XCTAssertNil([_blog jetpackPassword]);
}

- (void)testValidateCredentials {
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] isEqualToString:@"https://public-api.wordpress.com/get-user-blogs/1.0?f=json"] &&
        [[request valueForHTTPHeaderField:@"Authorization"] isEqualToString:@"Basic dGVzdDE6dGVzdDE="]; // test1:test1
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFile:@"get-user-blogs_doesnt-have-blog.json" contentType:@"application/json" responseTime:OHHTTPStubsDownloadSpeedWifi];
    }];

    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] isEqualToString:@"https://public-api.wordpress.com/get-user-blogs/1.0?f=json"] &&
        [[request valueForHTTPHeaderField:@"Authorization"] isEqualToString:@"Basic dGVzdDI6dGVzdDI="]; // test2:test2
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFile:@"get-user-blogs_has-blog.json" contentType:@"application/json" responseTime:OHHTTPStubsDownloadSpeedWifi];
    }];
    
    [OHHTTPStubs shouldStubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [[request.URL absoluteString] isEqualToString:@"https://public-api.wordpress.com/oauth2/token"];
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        return [OHHTTPStubsResponse responseWithFile:@"authtoken.json" contentType:@"application/json" responseTime:OHHTTPStubsDownloadSpeedWifi];
    }];
    
    XCTestExpectation *validateJetpackExpectation = [self expectationWithDescription:@"Validate Jetpack expectation"];
    
    [_blog validateJetpackUsername:@"test1" password:@"test1" success:^{
        XCTFail(@"User test1 shouldn't have access to test.blog");
        [validateJetpackExpectation fulfill];
    } failure:^(NSError *error) {
        XCTAssertEqual(error.domain, BlogJetpackErrorDomain);
        XCTAssertEqual(error.code, BlogJetpackErrorCodeNoRecordForBlog);
        [validateJetpackExpectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    validateJetpackExpectation = [self expectationWithDescription:@"Validate Jetpack expectation"];
    [_blog validateJetpackUsername:@"test2" password:@"test2" success:^{
        [validateJetpackExpectation fulfill];
    } failure:^(NSError *error) {
        XCTFail(@"User test2 should have access to test.blog");
        [validateJetpackExpectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testJetpackSetupDoesntReplaceDotcomAccount {
    XCTestExpectation *saveExpectation = [self expectationWithDescription:@"Context save expectation"];
    [CoreDataTestHelper sharedHelper].testExpectation = saveExpectation;

    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:[ContextManager sharedInstance].mainContext];
    WPAccount *wpComAccount = [accountService createOrUpdateWordPressComAccountWithUsername:@"user" password:@"pass" authToken:@"token"];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    XCTAssertEqualObjects(wpComAccount, [accountService defaultWordPressComAccount]);

    saveExpectation = [self expectationWithDescription:@"Context save expectation"];
    [CoreDataTestHelper sharedHelper].testExpectation = saveExpectation;
    [accountService createOrUpdateWordPressComAccountWithUsername:@"test1" password:@"test1" authToken:@"token1"];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    XCTAssertEqualObjects(wpComAccount, [accountService defaultWordPressComAccount]);
}

@end
