#import <XCTest/XCTest.h>
#import "AccountService.h"
#import "BlogService.h"
#import "WordPressTest-Swift.h"

@import WordPressData;
@import WordPressKitModels;

@import OCMock;

@interface BlogServiceTest : XCTestCase

@property (nonatomic, strong) BlogService *blogService;
@property (nonatomic, strong) id blogServiceMock;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) id<CoreDataStack> coreDataStack;

@end

@implementation BlogServiceTest

- (void)setUp
{
    [super setUp];

    self.coreDataStack = [self coreDataStackForTesting];

    self.blogService = [[BlogService alloc] initWithCoreDataStack:self.coreDataStack];
    AccountService *service = [[AccountService alloc] initWithCoreDataStack:self.coreDataStack];
    NSManagedObjectID *accountID = [service createOrUpdateAccountWithUsername:@"test" authToken:@"token"];
    WPAccount *account = [self.coreDataStack.mainContext existingObjectWithID:accountID error:nil];
    self.blog = (Blog *)[NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:self.coreDataStack.mainContext];
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
    self.blog.settings = (BlogSettings *)[NSEntityDescription insertNewObjectForEntityForName:@"BlogSettings"
                                                                       inManagedObjectContext:self.coreDataStack.mainContext];

    self.blogServiceMock = OCMPartialMock(self.blogService);

    [service setDefaultWordPressComAccount:account];
}

- (void)tearDown
{
    [self cleanUpNSUserDefaultValues];

    self.blogService = nil;
    self.blogServiceMock = nil;
    self.blog = nil;
    self.coreDataStack = nil;

    [super tearDown];
}

- (void)cleanUpNSUserDefaultValues
{
    [UserSettings setDefaultDotComUUID:nil];
}

- (void)testUpdateSettingsAppliesPresentValuesIncludingFalse
{
    self.blog.settings.commentsAllowed = @YES;
    self.blog.settings.commentsCloseAutomatically = YES;
    self.blog.settings.pingbackOutboundEnabled = YES;
    self.blog.settings.relatedPostsEnabled = YES;
    self.blog.settings.ampEnabled = YES;
    self.blog.settings.sharingDisabledLikes = YES;

    RemoteBlogSettings *remoteSettings = [RemoteBlogSettings new];
    remoteSettings.commentsAllowed = @NO;
    remoteSettings.commentsCloseAutomatically = @NO;
    remoteSettings.pingbackOutboundEnabled = @NO;
    remoteSettings.relatedPostsEnabled = @NO;
    remoteSettings.ampEnabled = @NO;
    remoteSettings.sharingDisabledLikes = @NO;
    remoteSettings.tagline = @"New tagline";

    [self.blogService updateSettings:self.blog.settings withRemoteSettings:remoteSettings];

    XCTAssertEqualObjects(self.blog.settings.commentsAllowed, @NO);
    XCTAssertFalse(self.blog.settings.commentsCloseAutomatically);
    XCTAssertFalse(self.blog.settings.pingbackOutboundEnabled);
    XCTAssertFalse(self.blog.settings.relatedPostsEnabled);
    XCTAssertFalse(self.blog.settings.ampEnabled);
    XCTAssertFalse(self.blog.settings.sharingDisabledLikes);
    XCTAssertEqualObjects(self.blog.settings.tagline, @"New tagline");
}

@end
