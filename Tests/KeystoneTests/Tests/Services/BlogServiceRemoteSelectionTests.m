#import <XCTest/XCTest.h>
#import "BlogService.h"
#import "WordPressTest-Swift.h"

@import WordPressData;
@import WordPressKit;

@interface BlogService (RemoteSelection)

- (nullable id<BlogServiceRemote>)remoteForBlog:(Blog *)blog;

@end

@interface BlogServiceRemoteSelectionTests : XCTestCase

@property (nonatomic, strong) id<CoreDataStack> coreDataStack;
@property (nonatomic, strong) BlogService *service;

@end

@implementation BlogServiceRemoteSelectionTests

- (void)setUp
{
    [super setUp];

    self.coreDataStack = [self coreDataStackForTesting];
    self.service = [[BlogService alloc] initWithCoreDataStack:self.coreDataStack];
}

- (void)tearDown
{
    self.service = nil;
    self.coreDataStack = nil;

    [super tearDown];
}

- (void)testRemoteForDotComBlogWithTokenUsesREST
{
    Blog *blog = [RemoteSelectionBlogFixture dotComBlogWithAuthToken:@"token" context:self.coreDataStack.mainContext];
    XCTAssertTrue([[self.service remoteForBlog:blog] isKindOfClass:[BlogServiceRemoteREST class]]);
}

- (void)testNoRemoteForDotComBlogWithoutToken
{
    Blog *blog = [RemoteSelectionBlogFixture dotComBlogWithAuthToken:nil context:self.coreDataStack.mainContext];
    XCTAssertNil([self.service remoteForBlog:blog]);
}

- (void)testNoRemoteForDotComBlogWithEmptyToken
{
    Blog *blog = [RemoteSelectionBlogFixture dotComBlogWithAuthToken:@"" context:self.coreDataStack.mainContext];
    XCTAssertNil([self.service remoteForBlog:blog]);
}

- (void)testRemoteForJetpackBlogWithoutTokenUsesStoredXMLRPCCredentials
{
    Blog *blog = [RemoteSelectionBlogFixture jetpackBlogWithAuthToken:nil xmlrpcPassword:@"password" context:self.coreDataStack.mainContext];
    XCTAssertTrue([[self.service remoteForBlog:blog] isKindOfClass:[BlogServiceRemoteXMLRPC class]]);
}

- (void)testNoRemoteForJetpackBlogWithoutTokenOrXMLRPCCredentials
{
    Blog *blog = [RemoteSelectionBlogFixture jetpackBlogWithAuthToken:nil xmlrpcPassword:nil context:self.coreDataStack.mainContext];
    XCTAssertNil([self.service remoteForBlog:blog]);
}

- (void)testRemoteForSelfHostedBlogIsUnaffected
{
    Blog *blog = [RemoteSelectionBlogFixture selfHostedBlogWithContext:self.coreDataStack.mainContext];
    XCTAssertTrue([[self.service remoteForBlog:blog] isKindOfClass:[BlogServiceRemoteXMLRPC class]]);
}

#pragma mark - Syncing without a remote

- (void)testSyncBlogAndAllMetadataCompletesWithoutRemote
{
    Blog *blog = [RemoteSelectionBlogFixture dotComBlogWithAuthToken:nil context:self.coreDataStack.mainContext];
    XCTestExpectation *completion = [self expectationWithDescription:@"completion"];

    [self.service syncBlogAndAllMetadata:blog completionHandler:^{
        [completion fulfill];
    }];

    [self waitForExpectations:@[completion] timeout:1];
}

- (void)testSyncPostFormatsFailsWithoutRemote
{
    Blog *blog = [RemoteSelectionBlogFixture dotComBlogWithAuthToken:nil context:self.coreDataStack.mainContext];
    XCTestExpectation *failure = [self expectationWithDescription:@"failure"];

    [self.service syncPostFormatsForBlog:blog success:^{
        XCTFail(@"Syncing without a remote must not succeed");
    } failure:^(NSError *error) {
        XCTAssertEqualObjects(error.domain, BlogServiceErrorDomain);
        XCTAssertEqual(error.code, BlogServiceErrorNoRemoteForBlog);
        [failure fulfill];
    }];

    [self waitForExpectations:@[failure] timeout:1];
}

@end
