#import <OCMock/OCMock.h>
#import <OHHTTPStubs/OHHTTPStubs.h>
#import <OHHTTPStubs/OHPathHelpers.h>
#import <XCTest/XCTest.h>
#import "Blog.h"
#import "BlogServiceRemoteREST.h"
#import "WordPressTest-Swift.h"

static NSTimeInterval const TestExpectationTimeout = 5;

@interface BlogServiceRemoteRESTTests : XCTestCase
@end

@implementation BlogServiceRemoteRESTTests

#pragma mark - Overriden Methods

- (void)tearDown
{
    [super tearDown];
    [OHHTTPStubs removeAllStubs];
}


#pragma mark - Checking multi author for a blog

- (void)testThatCheckMultiAuthorForBlogWorks
{
    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog dotComID]).andReturn(@10);
    
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    BlogServiceRemoteREST *service = nil;
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/users", blog.dotComID];

    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isKindOfClass:[NSDictionary class]]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:blog.dotComID]);
    
    [service checkMultiAuthorWithSuccess:^(BOOL isMultiAuthor) {}
                                 failure:^(NSError *error) {}];
}

#pragma mark - Synchronizing site details for a blog

- (void)testThatSyncSiteDetailsForBlogWorks
{
    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog dotComID]).andReturn(@10);

    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    BlogServiceRemoteREST *service = nil;

    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@", blog.dotComID];

    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);

    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:blog.dotComID]);

    [service syncBlogWithSuccess:^(RemoteBlog *remoteBlog) {}
                         failure:^(NSError *error) {}];
}

#pragma mark - Synchronizing post types for a blog

- (void)testThatSyncPostTypesForBlogWorks
{
    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog dotComID]).andReturn(@10);
    
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    BlogServiceRemoteREST *service = nil;
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/post-types", blog.dotComID];
    NSDictionary *parameters = @{@"context": @"edit"};
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isEqual:parameters]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:blog.dotComID]);

    [service syncPostTypesWithSuccess:^(NSArray<RemotePostType *> *postTypes) {}
                              failure:^(NSError *error) {}];
}

#pragma mark - Synchronizing post formats for a blog

- (void)testThatSyncPostFormatsForBlogWorks
{
    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog dotComID]).andReturn(@10);
    
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    BlogServiceRemoteREST *service = nil;
    
    NSString* url = [NSString stringWithFormat:@"v1.1/sites/%@/post-formats", blog.dotComID];
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[BlogServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:blog.dotComID]);
    
    [service syncPostFormatsWithSuccess:^(NSDictionary *options) {}
                                failure:^(NSError *error) {}];
}


#pragma mark - Blog Settings

- (void)testSyncBlogSettingsParsesCorrectlyEveryField
{
    NSNumber *blogID                = @(123);
    NSString *endpoint              = [NSString stringWithFormat:@"v1.1/sites/%@/settings", blogID];
    NSString *responsePath          = OHPathForFile(@"rest-site-settings.json", self.class);

    WordPressComRestApi *api        = [[WordPressComRestApi alloc] initWithOAuthToken:nil userAgent:nil];
    BlogServiceRemoteREST *service  = [[BlogServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:blogID];
    XCTAssertNotNil(service, @"Error while creating the new service");

    [OHHTTPStubs stubRequestForEndpoint:endpoint withFileAtPath:responsePath];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Site Settings"];
    
    [service syncBlogSettingsWithSuccess:^(RemoteBlogSettings *settings) {
        // General
        XCTAssertEqualObjects(settings.name, @"My Epic Blog", @"");
        XCTAssertEqualObjects(settings.tagline, @"Definitely, the best blog out there", @"");
        XCTAssertEqualObjects(settings.privacy, @(1), @"Invalid Privacy Value");
        XCTAssertEqualObjects(settings.languageID, @(31337), @"Invalid Language ID");
        
        // Writing
        XCTAssertEqualObjects(settings.defaultCategoryID, @(8), @"");
        XCTAssertEqualObjects(settings.defaultPostFormat, @"standard", @"");
        
        // Comments
        XCTAssertEqualObjects(settings.commentsAllowed, @(true), @"");
        XCTAssertEqualObjects(settings.commentsBlacklistKeys, @"some evil keywords", @"");
        XCTAssertEqualObjects(settings.commentsCloseAutomatically, @(false), @"");
        XCTAssertEqualObjects(settings.commentsCloseAutomaticallyAfterDays, @(3000), @"");

        XCTAssertEqualObjects(settings.commentsFromKnownUsersWhitelisted, @(true), @"");
        XCTAssertEqualObjects(settings.commentsMaximumLinks, @(42), @"");

        XCTAssertEqualObjects(settings.commentsModerationKeys, @"moderation keys", @"");

        XCTAssertEqualObjects(settings.commentsPagingEnabled, @(true), @"");
        XCTAssertEqualObjects(settings.commentsPageSize, @(5), @"");

        XCTAssertEqualObjects(settings.commentsRequireManualModeration, @(true), @"");
        XCTAssertEqualObjects(settings.commentsRequireNameAndEmail, @(false), @"");
        XCTAssertEqualObjects(settings.commentsRequireRegistration, @(true), @"");
        XCTAssertEqualObjects(settings.commentsSortOrder, @"desc", @"");
        XCTAssertEqualObjects(settings.commentsThreadingDepth, @(5), @"");
        XCTAssertEqualObjects(settings.commentsThreadingEnabled, @(true), @"");
        XCTAssertEqualObjects(settings.pingbackInboundEnabled, @(true), @"");
        XCTAssertEqualObjects(settings.pingbackOutboundEnabled, @(true), @"");

        // Related Posts
        XCTAssertEqualObjects(settings.relatedPostsAllowed, @(true), @"");
        XCTAssertEqualObjects(settings.relatedPostsEnabled, @(false), @"");
        XCTAssertEqualObjects(settings.relatedPostsShowHeadline, @(true), @"");
        XCTAssertEqualObjects(settings.relatedPostsShowThumbnails, @(false), @"");
        
        [expectation fulfill];
        
    } failure:^(NSError *error) {
        XCTAssertNil(error, @"We shouldn't be getting any errors");
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:TestExpectationTimeout handler:nil];
}

@end
