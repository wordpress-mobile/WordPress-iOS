#import <OHHTTPStubs/OHHTTPStubs.h>
#import "BlogJetpackTest.h"
#import "CoreDataTestHelper.h"
#import "AsyncTestHelper.h"
#import "Blog+Jetpack.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "AccountService.h"

@interface BlogJetpackTest ()

@property (nonatomic, strong) WPAccount *account;
@property (nonatomic, strong) Blog *blog;

@end

@implementation BlogJetpackTest

- (void)setUp {
    ATHStart();
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:[ContextManager sharedInstance].mainContext];
    _account = [accountService createOrUpdateSelfHostedAccountWithXmlrpc:@"http://blog1.com/xmlrpc.php" username:@"admin" andPassword:@"password!"];
    ATHEnd();

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
    _blog = nil;
    [OHHTTPStubs removeAllRequestHandlers];
    
    [[CoreDataTestHelper sharedHelper] reset];
}

- (void)testAssertionsOnWPcom {
    ATHStart();
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:[ContextManager sharedInstance].mainContext];
    WPAccount *wpComAccount = [accountService createOrUpdateWordPressComAccountWithUsername:@"user" password:@"pass" authToken:@"token"];
    ATHEnd();

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

    ATHStart();
    [_blog validateJetpackUsername:@"test1" password:@"test1" success:^{
        XCTFail(@"User test1 shouldn't have access to test.blog");
        ATHNotify();
    } failure:^(NSError *error) {
        XCTAssertEqual(error.domain, BlogJetpackErrorDomain);
        XCTAssertEqual(error.code, BlogJetpackErrorCodeNoRecordForBlog);
        ATHNotify();
    }];
    ATHEnd();

    ATHStart();
    [_blog validateJetpackUsername:@"test2" password:@"test2" success:^{
        ATHNotify();
    } failure:^(NSError *error) {
        XCTFail(@"User test2 should have access to test.blog");
        ATHNotify();
    }];
    ATHEnd();
}

@end
