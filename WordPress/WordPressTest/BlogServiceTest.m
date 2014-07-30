#import <XCTest/XCTest.h>
#import "CoreDataTestHelper.h"
#import "AsyncTestHelper.h"
#import "AccountService.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "Blog.h"
#import "WPAccount.h"

@interface BlogServiceTest : XCTestCase

@property (nonatomic, strong) BlogService *blogService;
@property (nonatomic, strong) Blog *blog;

@end

@implementation BlogServiceTest

- (void)setUp
{
    [super setUp];
    
    ATHStart();
    self.blogService = [[BlogService alloc] initWithManagedObjectContext:[[ContextManager sharedInstance] mainContext]];
    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:[ContextManager sharedInstance].mainContext];
    WPAccount *account = [service createOrUpdateWordPressComAccountWithUsername:@"test" password:@"test" authToken:@"token"];
    self.blog = (Blog *)[[CoreDataTestHelper sharedHelper] insertEntityIntoMainContextWithName:@"Blog"];
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

- (void)testTimeZoneForBlogNoTimeZoneInOptions
{
    NSTimeZone *timeZone = [self.blogService timeZoneForBlog:self.blog];
    
    XCTAssertNil(timeZone, @"No timezone should have been determined.");
}

- (void)testTimeZoneForBlogNilOptions
{
    self.blog.options = nil;
    
    NSTimeZone *timeZone = [self.blogService timeZoneForBlog:self.blog];
    
    XCTAssertNil(timeZone, @"No timezone should have been determined.");
}

- (void)testTimeZoneForBlogEmptyOptions
{
    self.blog.options = @{};
    
    NSTimeZone *timeZone = [self.blogService timeZoneForBlog:self.blog];
    
    XCTAssertNil(timeZone, @"No timezone should have been determined.");
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
    self.blog.options = @{ @"timezone" : @"America/Chicago" };
    
    NSTimeZone *timeZone = [self.blogService timeZoneForBlog:self.blog];
    
    XCTAssertNotNil(timeZone, @"A timezone should have been determined.");
    XCTAssertEqualObjects(timeZone, [NSTimeZone timeZoneWithName:@"America/Chicago"], @"Timezone should be central");
}

- (void)testTimeZoneForBlogRESTGMTOffsetOption
{
    self.blog.options = @{ @"gmt_offset" : @-5 };
    
    NSTimeZone *timeZone = [self.blogService timeZoneForBlog:self.blog];
    
    XCTAssertNotNil(timeZone, @"A timezone should have been determined.");
    XCTAssertEqualObjects(timeZone, [NSTimeZone timeZoneForSecondsFromGMT:(-5 * 60 * 60)], @"Timezone should be GMT-5");
}



@end
