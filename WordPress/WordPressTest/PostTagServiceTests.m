#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "Blog.h"
#import "PostTag.h"
#import "PostTagService.h"
#import "TestContextManager.h"
@import WordPressKit;
#import "WordPressTest-Swift.h"

@interface PostTagServiceForStubbing : PostTagService

@property (nonatomic, strong) TaxonomyServiceRemoteREST *remoteForStubbing;

@end

@interface WPAccount ()
@property (nonatomic, readwrite) WordPressComRestApi *wordPressComRestApi;
@end

@implementation PostTagServiceForStubbing

- (id <TaxonomyServiceRemote>)remoteForBlog:(Blog *)blog
{
    return self.remoteForStubbing;
}

@end

@interface PostTagServiceTests : XCTestCase

@property (nonatomic, strong) TestContextManager *manager;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) PostTagServiceForStubbing *service;

@end

@implementation PostTagServiceTests

- (void)setUp
{
    [super setUp];

    self.manager = [TestContextManager new];
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);

    Blog *blog = [ModelTestHelper insertDotComBlogWithContext:self.manager.mainContext];
    blog.account.wordPressComRestApi = api;
    blog.dotComID = @1;
    
    self.blog = blog;
    
    PostTagServiceForStubbing *service = [[PostTagServiceForStubbing alloc] initWithManagedObjectContext:self.manager.mainContext];
    
    TaxonomyServiceRemoteREST *remoteService = OCMStrictClassMock([TaxonomyServiceRemoteREST class]);
    service.remoteForStubbing = remoteService;
    
    self.service = service;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    self.service = nil;
    self.blog = nil;
    self.manager = nil;
}

- (void)testThatSyncTagsWorks
{
    TaxonomyServiceRemoteREST *remote = self.service.remoteForStubbing;
    OCMStub([remote getTagsWithSuccess:[OCMArg isNotNil]
                               failure:[OCMArg isNotNil]]);

    [self.service syncTagsForBlog:self.blog
                          success:^(NSArray<PostTag *> * _Nonnull tags) {}
                          failure:^(NSError * _Nonnull error) {}];
}

- (void)testThatSyncTagsWithPagingWorks
{
    TaxonomyServiceRemoteREST *remote = self.service.remoteForStubbing;
    
    NSNumber *number = @120;
    NSNumber *offset = @30;
    
    BOOL (^pagingCheckBlock)(id obj) = ^BOOL(RemoteTaxonomyPaging *paging) {
        if (![paging.number isEqual:number]) {
            return NO;
        }
        if (![paging.offset isEqual:offset]) {
            return NO;
        }
        return YES;
    };
    OCMStub([remote getTagsWithPaging:[OCMArg checkWithBlock:pagingCheckBlock]
                              success:[OCMArg isNotNil]
                              failure:[OCMArg isNotNil]]);
    
    [self.service syncTagsForBlog:self.blog
                           number:number
                           offset:offset
                          success:^(NSArray<PostTag *> * _Nonnull tags) {}
                          failure:^(NSError * _Nonnull error) {}];
}

- (void)testThatSearchTagsWithNameWorks
{
    TaxonomyServiceRemoteREST *remote = self.service.remoteForStubbing;
    
    NSString *name = @"tag name";
    OCMStub([remote searchTagsWithName:[OCMArg isEqual:name]
                               success:[OCMArg isNotNil]
                               failure:[OCMArg isNotNil]]);
    
    [self.service searchTagsWithName:name
                                blog:self.blog
                             success:^(NSArray<PostTag *> * _Nonnull tags) {}
                             failure:^(NSError * _Nonnull error) {}];
}

@end
