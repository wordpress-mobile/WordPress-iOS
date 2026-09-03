#import <XCTest/XCTest.h>
#import "PostCategoryService.h"

@import WordPressData;
#import "WordPressTest-Swift.h"

@import WordPressKit;
@import OCMock;

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
    blog.account._private_wordPressComRestApi = api;
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

/// Regression: when the save context can't resolve the blog, `success` must not
/// also fire. Previously the completion called `success(nil)` alongside `failure`
/// (a double callback that passed nil into the non-null `PostCategory` block).
/// The blog is intentionally left unsaved (see `setUp`), so its temporary
/// objectID doesn't resolve in the background save context — the "no blog" path.
- (void)testThatCreateCategoryDoesNotAlsoCallSuccessWhenBlogIsMissing
{
    TaxonomyServiceRemoteREST *remote = self.service.remoteForStubbing;

    RemotePostCategory *received = [RemotePostCategory new];
    received.categoryID = @123;
    received.name = @"category name";
    received.parentID = @0;

    OCMStub([remote createCategory:[OCMArg any]
                           success:([OCMArg invokeBlockWithArgs:received, nil])
                           failure:[OCMArg any]]);

    XCTestExpectation *failed = [self expectationWithDescription:@"failure is called"];
    XCTestExpectation *successNotCalled = [self expectationWithDescription:@"success is not called"];
    successNotCalled.inverted = YES;

    [self.service createCategoryWithName:@"category name"
                 parentCategoryObjectID:nil
                        forBlogObjectID:self.blog.objectID
                                success:^(PostCategory * _Nonnull __unused category) {
        [successNotCalled fulfill];
    } failure:^(NSError * _Nonnull __unused error) {
        // Failure is delivered from the main-queue completion, not the background save context.
        XCTAssertTrue([NSThread isMainThread]);
        [failed fulfill];
    }];

    [self waitForExpectations:@[failed, successNotCalled] timeout:1];
}

/// Happy path: when the blog resolves in the save context, the created category
/// is looked up and handed to `success` exactly once (on the main queue) and
/// `failure` is not called. The blog is saved first — unlike the no-blog test
/// above — so its permanent objectID resolves in the background save context.
- (void)testThatCreateCategoryCallsSuccessWithTheCreatedCategory
{
    [self.manager saveContextAndWait:self.manager.mainContext];

    TaxonomyServiceRemoteREST *remote = self.service.remoteForStubbing;

    RemotePostCategory *received = [RemotePostCategory new];
    received.categoryID = @123;
    received.name = @"category name";
    received.parentID = @0;

    OCMStub([remote createCategory:[OCMArg any]
                           success:([OCMArg invokeBlockWithArgs:received, nil])
                           failure:[OCMArg any]]);

    XCTestExpectation *succeeded = [self expectationWithDescription:@"success is called with the created category"];
    XCTestExpectation *failureNotCalled = [self expectationWithDescription:@"failure is not called"];
    failureNotCalled.inverted = YES;

    [self.service createCategoryWithName:@"category name"
                 parentCategoryObjectID:nil
                        forBlogObjectID:self.blog.objectID
                                success:^(PostCategory * _Nonnull category) {
        // Success is delivered from the main-queue completion.
        XCTAssertTrue([NSThread isMainThread]);
        XCTAssertNotNil(category);
        XCTAssertEqualObjects(category.categoryID, @123);
        XCTAssertEqualObjects(category.categoryName, @"category name");
        XCTAssertEqualObjects(category.parentID, @0);
        [succeeded fulfill];
    } failure:^(NSError * _Nonnull __unused error) {
        [failureNotCalled fulfill];
    }];

    [self waitForExpectations:@[succeeded, failureNotCalled] timeout:1];
}

@end
