#import <XCTest/XCTest.h>
#import "AccountService.h"
#import "Blog.h"
#import "WPAccount.h"
#import "TestContextManager.h"

@interface BlogTimeZoneTests : XCTestCase
    @property (nonatomic, strong) TestContextManager *testContextManager;
    @property (nonatomic, strong) Blog *blog;
@end

@implementation BlogTimeZoneTests

- (void)setUp
{
    [super setUp];

    self.testContextManager = [[TestContextManager alloc] init];

    AccountService *service = [[AccountService alloc] initWithManagedObjectContext: self.testContextManager.mainContext];
    WPAccount *account = [service createOrUpdateAccountWithUsername:@"test" authToken:@"token"];
    self.blog = (Blog *)[NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:self.testContextManager.mainContext];
    self.blog.account = account;
    self.blog.settings = (BlogSettings *)[NSEntityDescription insertNewObjectForEntityForName:@"BlogSettings" inManagedObjectContext:self.testContextManager.mainContext];
}

- (void)tearDown
{
    [ContextManager overrideSharedInstance:nil];

    self.blog = nil;
    self.testContextManager = nil;

    [self cleanUpNSUserDefaultValues];

    [super tearDown];
}


- (void)testTimeZoneForBlogNoTimeZoneInOptions
{
    NSTimeZone *timeZone = self.blog.timeZone;

    XCTAssertNotNil(timeZone, @"Timezone should never be nil.");
    XCTAssertEqualObjects(timeZone, [NSTimeZone timeZoneForSecondsFromGMT:0], @"Timezone should be GMT+0");
}

- (void)testTimeZoneForBlogNilOptions
{
    self.blog.options = nil;

    NSTimeZone *timeZone = self.blog.timeZone;

    XCTAssertNotNil(timeZone, @"Timezone should never be nil.");
    XCTAssertEqualObjects(timeZone, [NSTimeZone timeZoneForSecondsFromGMT:0], @"Timezone should be GMT+0");
}

- (void)testTimeZoneForBlogEmptyOptions
{
    self.blog.options = @{};

    NSTimeZone *timeZone = self.blog.timeZone;

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

    NSTimeZone *timeZone = self.blog.timeZone;

    XCTAssertNotNil(timeZone, @"A timezone should have been determined.");
    XCTAssertEqualObjects(timeZone, [NSTimeZone timeZoneForSecondsFromGMT:(-11 * 60 * 60)], @"Timezone should be GMT-11");
}

- (void)testTimeZoneForBlogRESTTimeZoneOption
{
    self.blog.options = @{ @"timezone" : @{ @"value" : @"America/Chicago" }};

    NSTimeZone *timeZone = self.blog.timeZone;

    XCTAssertNotNil(timeZone, @"A timezone should have been determined.");
    XCTAssertEqualObjects(timeZone, [NSTimeZone timeZoneWithName:@"America/Chicago"], @"Timezone should be central");
}

- (void)testTimeZoneForBlogRESTGMTOffsetOption
{
    self.blog.options = @{ @"gmt_offset" : @{ @"value" : @-5 }};

    NSTimeZone *timeZone = self.blog.timeZone;

    XCTAssertNotNil(timeZone, @"A timezone should have been determined.");
    XCTAssertEqualObjects(timeZone, [NSTimeZone timeZoneForSecondsFromGMT:(-5 * 60 * 60)], @"Timezone should be GMT-5");
}

- (void)cleanUpNSUserDefaultValues
{
    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:[ContextManager sharedInstance].mainContext];
    if ([service defaultWordPressComAccount]) {
        [service removeDefaultWordPressComAccount];
    }
}

@end
