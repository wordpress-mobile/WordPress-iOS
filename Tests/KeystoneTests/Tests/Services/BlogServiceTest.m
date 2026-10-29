#import <XCTest/XCTest.h>
#import "AccountService.h"
#import "BlogService.h"
#import "WordPressTest-Swift.h"

@import WordPressData;
@import WordPressKit;
@import WordPressKitModels;

@import OCMock;

@interface BlogService (Testing)

- (void)mergeBlogs:(NSArray<RemoteBlog *> *)blogs
      withAccountID:(NSManagedObjectID *)accountID
          inContext:(NSManagedObjectContext *)context;
- (nullable id<BlogServiceRemote>)remoteForBlog:(Blog *)blog;

@end

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

- (void)testMergeBlogsEvictsClientForDeletedBlog
{
    self.blog.dotComID = @1;
    WPAccount *account = self.blog.account;

    OCMExpect([self.blogServiceMock evictWordPressClientForBlog:self.blog]);

    [self.blogServiceMock mergeBlogs:@[]
                       withAccountID:account.objectID
                           inContext:self.coreDataStack.mainContext];

    OCMVerifyAll(self.blogServiceMock);
    XCTAssertTrue(self.blog.isDeleted);
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

#pragma mark - Remote selection

- (void)testRemoteForDotComBlogWithTokenUsesREST
{
    Blog *blog = [RemoteSelectionBlogFixture dotComBlogWithAuthToken:@"token" context:self.coreDataStack.mainContext];
    XCTAssertTrue([[self.blogService remoteForBlog:blog] isKindOfClass:[BlogServiceRemoteREST class]]);
}

- (void)testNoRemoteForDotComBlogWithoutToken
{
    Blog *blog = [RemoteSelectionBlogFixture dotComBlogWithAuthToken:nil context:self.coreDataStack.mainContext];
    XCTAssertNil([self.blogService remoteForBlog:blog]);
}

- (void)testNoRemoteForDotComBlogWithEmptyToken
{
    Blog *blog = [RemoteSelectionBlogFixture dotComBlogWithAuthToken:@"" context:self.coreDataStack.mainContext];
    XCTAssertNil([self.blogService remoteForBlog:blog]);
}

- (void)testRemoteForJetpackBlogWithoutTokenUsesStoredXMLRPCCredentials
{
    Blog *blog = [RemoteSelectionBlogFixture jetpackBlogWithAuthToken:nil xmlrpcPassword:@"password" context:self.coreDataStack.mainContext];
    XCTAssertTrue([[self.blogService remoteForBlog:blog] isKindOfClass:[BlogServiceRemoteXMLRPC class]]);
}

- (void)testNoRemoteForJetpackBlogWithoutTokenOrXMLRPCCredentials
{
    Blog *blog = [RemoteSelectionBlogFixture jetpackBlogWithAuthToken:nil xmlrpcPassword:nil context:self.coreDataStack.mainContext];
    XCTAssertNil([self.blogService remoteForBlog:blog]);
}

- (void)testRemoteForSelfHostedBlogIsUnaffected
{
    Blog *blog = [RemoteSelectionBlogFixture selfHostedBlogWithContext:self.coreDataStack.mainContext];
    XCTAssertTrue([[self.blogService remoteForBlog:blog] isKindOfClass:[BlogServiceRemoteXMLRPC class]]);
}

#pragma mark - Syncing without a remote

- (void)testSyncBlogAndAllMetadataCompletesWithoutRemote
{
    Blog *blog = [RemoteSelectionBlogFixture dotComBlogWithAuthToken:nil context:self.coreDataStack.mainContext];
    XCTestExpectation *completion = [self expectationWithDescription:@"completion"];

    [self.blogService syncBlogAndAllMetadata:blog completionHandler:^{
        [completion fulfill];
    }];

    [self waitForExpectations:@[completion] timeout:1];
}

- (void)testSyncPostFormatsFailsWithoutRemote
{
    Blog *blog = [RemoteSelectionBlogFixture dotComBlogWithAuthToken:nil context:self.coreDataStack.mainContext];
    XCTestExpectation *failure = [self expectationWithDescription:@"failure"];

    [self.blogService syncPostFormatsForBlog:blog success:^{
        XCTFail(@"Syncing without a remote must not succeed");
    } failure:^(NSError *error) {
        XCTAssertEqualObjects(error.domain, BlogServiceErrorDomain);
        XCTAssertEqual(error.code, BlogServiceErrorNoRemoteForBlog);
        [failure fulfill];
    }];

    [self waitForExpectations:@[failure] timeout:1];
}

@end
