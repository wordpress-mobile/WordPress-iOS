#import <XCTest/XCTest.h>
#import "AccountService.h"
#import "Blog.h"
#import "WPAccount.h"
#import "UnitTests-Swift.h"

@interface BlogTimeZoneTests : XCTestCase
@property (nonatomic, strong) id<CoreDataStack> coreDataStack;
@property (nonatomic, strong) Blog *blog;
@end

@implementation BlogTimeZoneTests

- (void)setUp
{
    [super setUp];

    self.coreDataStack = [self coreDataStackForTesting];

    AccountService *service = [[AccountService alloc] initWithCoreDataStack:self.coreDataStack];
    NSManagedObjectID *accountID = [service createOrUpdateAccountWithUsername:@"test" authToken:@"token"];
    WPAccount *account = [self.coreDataStack.mainContext existingObjectWithID:accountID error:nil];
    self.blog = (Blog *)[NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:self.coreDataStack.mainContext];
    self.blog.account = account;
    self.blog.settings = (BlogSettings *)[NSEntityDescription insertNewObjectForEntityForName:@"BlogSettings" inManagedObjectContext:self.coreDataStack.mainContext];
}

- (void)tearDown
{
    [self cleanUpNSUserDefaultValues];

    self.blog = nil;
    self.coreDataStack = nil;

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
    [UserSettings setDefaultDotComUUID:nil];
}

@end
