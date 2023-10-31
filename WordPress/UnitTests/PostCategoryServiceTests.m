#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "Blog.h"
#import "PostCategory.h"
#import "PostCategoryService.h"
#import "UnitTests-Swift.h"
@import WordPressKit;

@interface WPAccount ()
@property (nonatomic, readwrite) WordPressComRestApi *wordPressComRestApi;
@end

@interface PostCategoryServiceForStubbing : PostCategoryService

@property (nonatomic, strong) TaxonomyServiceRemoteREST *remoteForStubbing;

@end

@implementation PostCategoryServiceForStubbing

- (id <TaxonomyServiceRemote>)remoteForBlog:(Blog *)blog
{
    return self.remoteForStubbing;
}

@end

@interface PostCategoryServiceTests : XCTestCase

@property (nonatomic, strong) id<CoreDataStack> manager;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) PostCategoryServiceForStubbing *service;

@end

@implementation PostCategoryServiceTests

- (void)setUp
{
    [super setUp];

    self.manager = [self coreDataStackForTesting];
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);

    Blog *blog = [ModelTestHelper insertDotComBlogWithContext:self.manager.mainContext];
    blog.account.wordPressComRestApi = api;
    blog.dotComID = @1;
    self.blog = blog;

    PostCategoryServiceForStubbing *service = [[PostCategoryServiceForStubbing alloc] initWithCoreDataStack:self.manager];
    
    TaxonomyServiceRemoteREST *remoteService = OCMStrictClassMock([TaxonomyServiceRemoteREST class]);
    service.remoteForStubbing = remoteService;
    
    self.service = service;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    self.blog = nil;
    self.service = nil;
    self.manager = nil;
}

- (void)testThatSyncCategoriesWorks
{
    TaxonomyServiceRemoteREST *remote = self.service.remoteForStubbing;
    OCMStub([remote getCategoriesWithSuccess:[OCMArg isNotNil]
                                     failure:[OCMArg isNotNil]]);
    
    [self.service syncCategoriesForBlog:self.blog
                                success:^{}
                                failure:^(NSError * _Nonnull __unused error) {}];
}

- (void)testThatSyncCategoriesWithPagingWorks
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
    OCMStub([remote getCategoriesWithPaging:[OCMArg checkWithBlock:pagingCheckBlock]
                                    success:[OCMArg isNotNil]
                                    failure:[OCMArg isNotNil]]);
    
    [self.service syncCategoriesForBlog:self.blog
                                 number:number
                                 offset:offset
                                success:^(NSArray<PostCategory *> * _Nonnull __unused tags) {}
                                failure:^(NSError * _Nonnull __unused error) {}];
}

- (void)testThatCreateCategoryWithNameWorks
{
    TaxonomyServiceRemoteREST *remote = self.service.remoteForStubbing;

    NSString *name = @"category name";
    
    BOOL (^remoteCategoryCheckBlock)(id obj) = ^BOOL(RemotePostCategory *category) {
        if (![category.name isEqualToString:name]) {
            return NO;
        }
        return YES;
    };
    OCMStub([remote createCategory:[OCMArg checkWithBlock:remoteCategoryCheckBlock]
                           success:[OCMArg isNotNil]
                           failure:[OCMArg isNotNil]]);
    
    [self.service createCategoryWithName:name
                  parentCategoryObjectID:nil
                         forBlogObjectID:self.blog.objectID
                                 success:^(PostCategory * _Nonnull __unused category) {}
                                 failure:^(NSError * _Nonnull __unused error) {}];
}

- (void)testSyncSuccessShouldBeCalledOnce
{
    TaxonomyServiceRemoteREST *remote = self.service.remoteForStubbing;

    XCTestExpectation *completion = [self expectationWithDescription:@"Only the success block is called"];
    OCMStub([remote getCategoriesWithSuccess:[OCMArg invokeBlock]
                                     failure:[OCMArg isNotNil]]);
    [self.service syncCategoriesForBlog:self.blog
                                success:^{ [completion fulfill]; }
                                failure:^(NSError * _Nonnull __unused error) {[completion fulfill]; }];
    [self waitForExpectations:@[completion] timeout:1];
}

- (void)testSyncFailureShouldBeCalledOnce
{
    TaxonomyServiceRemoteREST *remote = self.service.remoteForStubbing;

    XCTestExpectation *completion = [self expectationWithDescription:@"Only the failure block is called"];
    OCMStub([remote getCategoriesWithSuccess:[OCMArg isNotNil]
                                     failure:[OCMArg invokeBlock]]);
    [self.service syncCategoriesForBlog:self.blog
                                success:^{ [completion fulfill]; }
                                failure:^(NSError * _Nonnull __unused error) {[completion fulfill]; }];
    [self waitForExpectations:@[completion] timeout:1];
}

@end
