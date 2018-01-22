#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "TaxonomyServiceRemoteREST.h"
#import "RemotePostTag.h"
@import WordPressKit;

@interface TaxonomyServiceRemoteRESTTests : XCTestCase

@property (nonatomic, strong) TaxonomyServiceRemoteREST *service;

@end

@implementation TaxonomyServiceRemoteRESTTests

- (void)setUp
{
    [super setUp];

    NSNumber *dotComID = @10;
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);

    TaxonomyServiceRemoteREST *service = nil;
    XCTAssertNoThrow(service = [[TaxonomyServiceRemoteREST alloc] initWithWordPressComRestApi:api siteID:dotComID]);
    
    self.service = service;
}

- (void)tearDown
{
    [super tearDown];
    
    self.service = nil;
}

- (NSString *)GETtaxonomyURLWithType:(NSString *)taxonomyTypeIdentifier
{
    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/%@?context=edit", self.service.siteID, taxonomyTypeIdentifier];
    NSString *url = [self.service pathForEndpoint:endpoint
                                      withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    return url;
}

#pragma mark - Categories

- (void)testThatCreateCategoryWorks
{
    RemotePostCategory *category = OCMStrictClassMock([RemotePostCategory class]);
    OCMStub([category name]).andReturn(@"name");
    OCMStub([category parentID]).andReturn(nil);

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/%@/new?context=edit", self.service.siteID, @"categories"];
    NSString *url = [self.service pathForEndpoint:endpoint
                                      withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    BOOL (^parametersCheckBlock)(id obj) = ^BOOL(NSDictionary *parameters) {
        return ([parameters isKindOfClass:[NSDictionary class]] && [[parameters objectForKey:@"name"] isEqualToString:category.name]);
    };
    
    WordPressComRestApi *api = self.service.wordPressComRestApi;
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

    BOOL (^parametersCheckBlock)(id obj) = ^BOOL(NSDictionary *parameters) {
        return ([parameters isKindOfClass:[NSDictionary class]] && [[parameters objectForKey:@"number"] integerValue] == 1000);
    };

    WordPressComRestApi *api = self.service.wordPressComRestApi;
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg checkWithBlock:parametersCheckBlock]
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
    
    WordPressComRestApi *api = self.service.wordPressComRestApi;
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
    
    WordPressComRestApi *api = self.service.wordPressComRestApi;
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
    OCMStub([tag tagDescription]).andReturn(@"description");

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/%@/new?context=edit", self.service.siteID, @"tags"];
    NSString *url = [self.service pathForEndpoint:endpoint
                                      withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];
    
    BOOL (^parametersCheckBlock)(id obj) = ^BOOL(NSDictionary *parameters) {
        return ([parameters isKindOfClass:[NSDictionary class]] && [[parameters objectForKey:@"name"] isEqualToString:tag.name]);
    };

    WordPressComRestApi *api = self.service.wordPressComRestApi;
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

    BOOL (^parametersCheckBlock)(id obj) = ^BOOL(NSDictionary *parameters) {
        return ([parameters isKindOfClass:[NSDictionary class]] && [[parameters objectForKey:@"number"] integerValue] == 1000);
    };

    WordPressComRestApi *api = self.service.wordPressComRestApi;
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg checkWithBlock:parametersCheckBlock]
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
    
    WordPressComRestApi *api = self.service.wordPressComRestApi;
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
    
    WordPressComRestApi *api = self.service.wordPressComRestApi;
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg checkWithBlock:parametersCheckBlock]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    [self.service searchTagsWithName:searchName
                             success:^(NSArray<RemotePostTag *> * _Nonnull tags) {}
                             failure:^(NSError * _Nonnull error) {}];
}

@end
