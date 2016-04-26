#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "Blog.h"
#import "WordPressComApi.h"
#import "TaxonomyServiceRemoteREST.h"
#import "RemotePostCategory.h"
#import "RemotePostTag.h"
#import "RemoteTaxonomyPaging.h"

@interface TaxonomyServiceRemoteRESTTests : XCTestCase

@property (nonatomic, strong) TaxonomyServiceRemoteREST *service;

@end

@implementation TaxonomyServiceRemoteRESTTests

- (void)setUp
{
    [super setUp];

    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog dotComID]).andReturn(@10);
    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    OCMStub([blog restApi]).andReturn(api);
    
    TaxonomyServiceRemoteREST *service = nil;
    XCTAssertNoThrow(service = [[TaxonomyServiceRemoteREST alloc] initWithApi:blog.restApi siteID:blog.dotComID]);
    
    self.service = service;
}

- (void)tearDown
{
    [super tearDown];
    
    self.service = nil;
}

- (NSString *)GETtaxonomyURLWithType:(NSString *)taxonomyTypeIdentifier
{
    return [NSString stringWithFormat:@"v1.1/sites/%@/%@?context=edit", self.service.siteID, taxonomyTypeIdentifier];
}

#pragma mark - Categories

- (void)testThatCreateCategoryWorks
{
    RemotePostCategory *category = OCMStrictClassMock([RemotePostCategory class]);
    OCMStub([category name]).andReturn(@"name");
    OCMStub([category parentID]).andReturn(nil);

    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/%@/new?context=edit", self.service.siteID, @"categories"];
    
    BOOL (^parametersCheckBlock)(id obj) = ^BOOL(NSDictionary *parameters) {
        return ([parameters isKindOfClass:[NSDictionary class]] && [[parameters objectForKey:@"name"] isEqualToString:category.name]);
    };
    
    WordPressComApi *api = self.service.api;
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg checkWithBlock:parametersCheckBlock]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    [self.service createCategory:category
                         success:^(RemotePostCategory * _Nonnull category) {}
                         failure:^(NSError * _Nonnull error) {}];
}

- (void)testThatGetCategoriesWorks
{
    NSString *url = [self GETtaxonomyURLWithType:@"categories"];
    
    WordPressComApi *api = self.service.api;
    OCMStub([api GET:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    [self.service getCategoriesWithSuccess:^(NSArray<RemotePostCategory *> * _Nonnull categories) {}
                                   failure:^(NSError * _Nonnull error) {}];
}

- (void)testThatGetCategoriesWithPagingWorks
{
    RemoteTaxonomyPaging *paging = OCMStrictClassMock([RemoteTaxonomyPaging class]);
    OCMStub([paging number]).andReturn(@100);
    OCMStub([paging offset]).andReturn(@0);
    OCMStub([paging page]).andReturn(@0);
    OCMStub([paging order]).andReturn(RemoteTaxonomyPagingOrderAscending);
    OCMStub([paging orderBy]).andReturn(RemoteTaxonomyPagingResultsOrderingByName);

    NSString *url = [self GETtaxonomyURLWithType:@"categories"];
    
    BOOL (^parametersCheckBlock)(id obj) = ^BOOL(NSDictionary *parameters) {
        if (![parameters isKindOfClass:[NSDictionary class]]) {
            return NO;
        }
        if (![[parameters objectForKey:@"number"] isEqual:paging.number]) {
            return NO;
        }
        if (![[parameters objectForKey:@"offset"] isEqual:paging.offset]) {
            return NO;
        }
        if (![[parameters objectForKey:@"page"] isEqual:paging.page]) {
            return NO;
        }
        if (![[parameters objectForKey:@"order"] isEqualToString:@"ASC"]) {
            return NO;
        }
        if (![[parameters objectForKey:@"order_by"] isEqualToString:@"name"]) {
            return NO;
        }
        return YES;
    };
    
    WordPressComApi *api = self.service.api;
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg checkWithBlock:parametersCheckBlock]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    [self.service getCategoriesWithPaging:paging
                                  success:^(NSArray<RemotePostCategory *> * _Nonnull categories) {}
                                  failure:^(NSError * _Nonnull error) {}];
}

- (void)testThatSearchCategoriesWithNameWorks
{
    NSString *url = [self GETtaxonomyURLWithType:@"categories"];
    NSString *searchName = @"category name";
    
    BOOL (^parametersCheckBlock)(id obj) = ^BOOL(NSDictionary *parameters) {
        if (![parameters isKindOfClass:[NSDictionary class]]) {
            return NO;
        }
        if (![[parameters objectForKey:@"search"] isEqualToString:searchName]) {
            return NO;
        }
        return YES;
    };
    
    WordPressComApi *api = self.service.api;
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg checkWithBlock:parametersCheckBlock]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    [self.service searchCategoriesWithName:searchName
                                   success:^(NSArray<RemotePostCategory *> * _Nonnull categories) {}
                                   failure:^(NSError * _Nonnull error) {}];
}

#pragma mark - Tags

- (void)testThatCreateTagWorks
{
    RemotePostTag *tag = OCMStrictClassMock([RemotePostTag class]);
    OCMStub([tag name]).andReturn(@"name");
    
    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/%@/new?context=edit", self.service.siteID, @"tags"];
    
    BOOL (^parametersCheckBlock)(id obj) = ^BOOL(NSDictionary *parameters) {
        return ([parameters isKindOfClass:[NSDictionary class]] && [[parameters objectForKey:@"name"] isEqualToString:tag.name]);
    };
    
    WordPressComApi *api = self.service.api;
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg checkWithBlock:parametersCheckBlock]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]);
    
    [self.service createTag:tag
                    success:^(RemotePostTag * _Nonnull tag) {}
                    failure:^(NSError * _Nonnull error) {}];
}

- (void)testThatGetTagsWorks
{
    NSString *url = [self GETtaxonomyURLWithType:@"tags"];
    
    WordPressComApi *api = self.service.api;
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    [self.service getTagsWithSuccess:^(NSArray<RemotePostTag *> * _Nonnull tags) {}
                             failure:^(NSError * _Nonnull error) {}];
}

- (void)testThatGetTagsWithPagingWorks
{
    RemoteTaxonomyPaging *paging = OCMStrictClassMock([RemoteTaxonomyPaging class]);
    OCMStub([paging number]).andReturn(@100);
    OCMStub([paging offset]).andReturn(@0);
    OCMStub([paging page]).andReturn(@0);
    OCMStub([paging order]).andReturn(RemoteTaxonomyPagingOrderAscending);
    OCMStub([paging orderBy]).andReturn(RemoteTaxonomyPagingResultsOrderingByName);
    
    NSString *url = [self GETtaxonomyURLWithType:@"tags"];
    
    BOOL (^parametersCheckBlock)(id obj) = ^BOOL(NSDictionary *parameters) {
        if (![parameters isKindOfClass:[NSDictionary class]]) {
            return NO;
        }
        if (![[parameters objectForKey:@"number"] isEqual:paging.number]) {
            return NO;
        }
        if (![[parameters objectForKey:@"offset"] isEqual:paging.offset]) {
            return NO;
        }
        if (![[parameters objectForKey:@"page"] isEqual:paging.page]) {
            return NO;
        }
        if (![[parameters objectForKey:@"order"] isEqualToString:@"ASC"]) {
            return NO;
        }
        if (![[parameters objectForKey:@"order_by"] isEqualToString:@"name"]) {
            return NO;
        }
        return YES;
    };
    
    WordPressComApi *api = self.service.api;
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg checkWithBlock:parametersCheckBlock]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    [self.service getTagsWithPaging:paging
                            success:^(NSArray<RemotePostTag *> * _Nonnull tags) {}
                            failure:^(NSError * _Nonnull error) {}];
}

- (void)testThatSearchTagsWithNameWorks
{
    NSString *url = [self GETtaxonomyURLWithType:@"tags"];
    NSString *searchName = @"tag name";
    
    BOOL (^parametersCheckBlock)(id obj) = ^BOOL(NSDictionary *parameters) {
        if (![parameters isKindOfClass:[NSDictionary class]]) {
            return NO;
        }
        if (![[parameters objectForKey:@"search"] isEqualToString:searchName]) {
            return NO;
        }
        return YES;
    };
    
    WordPressComApi *api = self.service.api;
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg checkWithBlock:parametersCheckBlock]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    [self.service searchTagsWithName:searchName
                             success:^(NSArray<RemotePostTag *> * _Nonnull tags) {}
                             failure:^(NSError * _Nonnull error) {}];
}

@end
