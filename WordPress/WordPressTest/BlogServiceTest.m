#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "AccountService.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "Blog.h"
#import "WPAccount.h"
#import "TestContextManager.h"

@interface BlogServiceTest : XCTestCase

@property (nonatomic, strong) BlogService *blogService;
@property (nonatomic, strong) id blogServiceMock;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) TestContextManager *testContextManager;

@end

@implementation BlogServiceTest

- (void)setUp
{
    [super setUp];
 
    self.testContextManager = [[TestContextManager alloc] init];
    
    self.blogService = [[BlogService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:[ContextManager sharedInstance].mainContext];
    WPAccount *account = [service createOrUpdateAccountWithUsername:@"test" authToken:@"token"];
    self.blog = (Blog *)[NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:self.testContextManager.mainContext];
    self.blog.xmlrpc = @"http://test.blog/xmlrpc.php";
    self.blog.url = @"http://test.blog/";
    self.blog.options = @{@"jetpack_version": @{
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
    self.blog.account = account;

    self.blogServiceMock = OCMPartialMock(self.blogService);
    
    [service setDefaultWordPressComAccount:account];
}

- (void)tearDown
{
    self.blogService = nil;
    self.blogServiceMock = nil;
    self.blog = nil;
    self.testContextManager = nil;
    
    [self cleanUpNSUserDefaultValues];
    
    [super tearDown];
}

- (void)testTimeZoneForBlogNoTimeZoneInOptions
{
    NSTimeZone *timeZone = [self.blogService timeZoneForBlog:self.blog];
    
    XCTAssertNotNil(timeZone, @"Timezone should never be nil.");
    XCTAssertEqualObjects(timeZone, [NSTimeZone timeZoneForSecondsFromGMT:0], @"Timezone should be GMT+0");
}

- (void)testTimeZoneForBlogNilOptions
{
    self.blog.options = nil;
    
    NSTimeZone *timeZone = [self.blogService timeZoneForBlog:self.blog];
    
    XCTAssertNotNil(timeZone, @"Timezone should never be nil.");
    XCTAssertEqualObjects(timeZone, [NSTimeZone timeZoneForSecondsFromGMT:0], @"Timezone should be GMT+0");
}

- (void)testTimeZoneForBlogEmptyOptions
{
    self.blog.options = @{};
    
    NSTimeZone *timeZone = [self.blogService timeZoneForBlog:self.blog];
    
    XCTAssertNotNil(timeZone, @"Timezone should never be nil.");
    XCTAssertEqualObjects(timeZone, [NSTimeZone timeZoneForSecondsFromGMT:0], @"Timezone should be GMT+0");
}

- (void)testTimeZoneForBlogXMLRPCTimeZoneOption
{
    self.blog.options = @{ @"time_zone" : @{
                                   @"value": @"-11",
                                   @"desc": @"stub",
                                   @"readonly": @YES,
                                   }
                           };
    
    NSTimeZone *timeZone = [self.blogService timeZoneForBlog:self.blog];
    
    XCTAssertNotNil(timeZone, @"A timezone should have been determined.");
    XCTAssertEqualObjects(timeZone, [NSTimeZone timeZoneForSecondsFromGMT:(-11 * 60 * 60)], @"Timezone should be GMT-11");
}

- (void)testTimeZoneForBlogRESTTimeZoneOption
{
    self.blog.options = @{ @"timezone" : @{ @"value" : @"America/Chicago" }};
    
    NSTimeZone *timeZone = [self.blogService timeZoneForBlog:self.blog];
    
    XCTAssertNotNil(timeZone, @"A timezone should have been determined.");
    XCTAssertEqualObjects(timeZone, [NSTimeZone timeZoneWithName:@"America/Chicago"], @"Timezone should be central");
}

- (void)testTimeZoneForBlogRESTGMTOffsetOption
{
    self.blog.options = @{ @"gmt_offset" : @{ @"value" : @-5 }};
    
    NSTimeZone *timeZone = [self.blogService timeZoneForBlog:self.blog];
    
    XCTAssertNotNil(timeZone, @"A timezone should have been determined.");
    XCTAssertEqualObjects(timeZone, [NSTimeZone timeZoneForSecondsFromGMT:(-5 * 60 * 60)], @"Timezone should be GMT-5");
}

- (void)testHasVisibleWPComAccountsWithVisibleWPComAccounts
{
    OCMStub([self.blogServiceMock blogCountVisibleForWPComAccounts]).andReturn(1);
    
    XCTAssertTrue([self.blogService hasVisibleWPComAccounts]);
}

- (void)testHasVisibleWPComAccountsWithNoVisibleWPComAccounts
{
    OCMStub([self.blogServiceMock blogCountVisibleForWPComAccounts]).andReturn(0);
    
    XCTAssertFalse([self.blogService hasVisibleWPComAccounts]);
}

- (void)cleanUpNSUserDefaultValues
{
    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:[ContextManager sharedInstance].mainContext];
    if ([service defaultWordPressComAccount]) {
        [service removeDefaultWordPressComAccount];
    }
}

@end
