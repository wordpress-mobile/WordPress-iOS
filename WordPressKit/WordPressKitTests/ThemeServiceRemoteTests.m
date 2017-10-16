#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "WordPressKitTests-Swift.h"
@import WordPressKit;

// OCMock helper typedefs
typedef BOOL (^DictionaryVerificationBlock)(NSDictionary *dictionary);

// AFHTTP helper typedefs
typedef void (^RequestSuccessBlock)(id responseObject, NSHTTPURLResponse *httpResponse);
typedef void (^RequestFailureBlock)(NSError *error, NSHTTPURLResponse *httpResponse);

// NSInvocation helper constants
static const NSInteger InvocationFirstParameterIndex = 2;

// JSON files
static NSString* const ThemeServiceRemoteTestGetMultipleThemesJson = @"get-multiple-themes-v1.2";
static NSString* const ThemeServiceRemoteTestGetPurchasedThemesJson = @"get-purchased-themes-v1.1";
static NSString* const ThemeServiceRemoteTestGetSingleThemeJson = @"get-single-theme-v1.1";

@interface ThemeServiceRemoteTests : XCTestCase
@end

@implementation ThemeServiceRemoteTests

#pragma mark - Getting the themes

- (void)testThatGetActiveThemeForBlogIdWorks
{
    NSNumber *blogId = @124;
    
    ThemeServiceRemoteThemeRequestSuccessBlock successBlock = ^void (RemoteTheme *theme) {
        NSCAssert([theme isKindOfClass:[RemoteTheme class]], @"Expected a theme to be returned");
    };
    
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    ThemeServiceRemote *service = nil;

    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:api]);

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/themes/mine", blogId];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    [OCMStub([api GET:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]) andDo:^(NSInvocation *invocation) {
        
        NSInteger successBlockParameterIndex = InvocationFirstParameterIndex + 2;
        RequestSuccessBlock successBlock;
        
        [invocation getArgument:&successBlock atIndex:successBlockParameterIndex];
        NSCAssert(successBlock != nil, @"Expected a success block");
        
        JSONLoader *loader = [[JSONLoader alloc] init];
        NSDictionary *jsonDictionary = [loader loadFile:ThemeServiceRemoteTestGetSingleThemeJson
                                                   type:@"json"];
        NSCAssert([jsonDictionary isKindOfClass:[NSDictionary class]],
                  @"Expected a json dictionary here.  Make sure the json file for this test is well formatted.");
        
        successBlock(jsonDictionary, nil);
    }];

    XCTAssertNoThrow([service getActiveThemeForBlogId:blogId
                                              success:successBlock
                                              failure:nil]);
}

- (void)testThatGetActiveThemeForBlogThrowsExceptionWithoutBlogId
{
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    ThemeServiceRemote *service = nil;

    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:api]);
    XCTAssertThrows([service getActiveThemeForBlogId:nil
                                             success:nil
                                             failure:nil]);
}

- (void)testThatGetPurchasedThemesForBlogIdWorks
{
    NSNumber *blogId = @124;
    
    ThemeServiceRemoteThemeIdentifiersRequestSuccessBlock successBlock = ^void (NSArray *themeIdentifiers) {
        NSCAssert([themeIdentifiers count] > 0, @"Expected themes to be returned");
    };
    
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    ThemeServiceRemote *service = nil;

    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:api]);

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/themes/purchased", blogId];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    [OCMStub([api GET:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]) andDo:^(NSInvocation *invocation) {
        
        NSInteger successBlockParameterIndex = InvocationFirstParameterIndex + 2;
        RequestSuccessBlock successBlock;
        
        [invocation getArgument:&successBlock atIndex:successBlockParameterIndex];
        NSCAssert(successBlock != nil, @"Expected a success block");
        
        JSONLoader *loader = [[JSONLoader alloc] init];
        NSDictionary *jsonDictionary = [loader loadFile:ThemeServiceRemoteTestGetPurchasedThemesJson
                                                   type:@"json"];
        NSCAssert([jsonDictionary isKindOfClass:[NSDictionary class]],
                  @"Expected a json dictionary here.  Make sure the json file for this test is well formatted.");
        
        successBlock(jsonDictionary, nil);
    }];

    XCTAssertNoThrow([service getPurchasedThemesForBlogId:blogId
                                                  success:successBlock
                                                  failure:nil]);
}

- (void)testThatGetPurchasedThemesForBlogIdThrowsExceptionWithoutBlogId
{
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    ThemeServiceRemote *service = nil;

    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:api]);
    XCTAssertThrows([service getPurchasedThemesForBlogId:nil
                                                 success:nil
                                                 failure:nil]);
}

- (void)testThatGetThemeIdWorks
{
    NSString *themeId = @"obsidian";
    
    ThemeServiceRemoteThemeRequestSuccessBlock successBlock = ^void (RemoteTheme *theme) {
        NSCAssert([theme isKindOfClass:[RemoteTheme class]], @"Expected a theme to be returned");
    };
    
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    ThemeServiceRemote *service = nil;
    
    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:api]);

    NSString *endpoint = [NSString stringWithFormat:@"themes/%@", themeId];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    [OCMStub([api GET:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]) andDo:^(NSInvocation *invocation) {
        
        NSInteger successBlockParameterIndex = InvocationFirstParameterIndex + 2;
        RequestSuccessBlock successBlock;
        
        [invocation getArgument:&successBlock atIndex:successBlockParameterIndex];
        NSCAssert(successBlock != nil, @"Expected a success block");
        
        JSONLoader *loader = [[JSONLoader alloc] init];
        NSDictionary *jsonDictionary = [loader loadFile:ThemeServiceRemoteTestGetSingleThemeJson
                                                   type:@"json"];
        NSCAssert([jsonDictionary isKindOfClass:[NSDictionary class]],
                  @"Expected a json dictionary here.  Make sure the json file for this test is well formatted.");
        
        successBlock(jsonDictionary, nil);
    }];
    
    XCTAssertNoThrow([service getThemeId:themeId
                                 success:successBlock
                                 failure:nil]);
}

- (void)testThatGetThemeIdThrowsExceptionWithoutThemeId
{
    NSString *themeId = @"obsidian";
    
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    ThemeServiceRemote *service = nil;
    
    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:api]);
    XCTAssertThrows([service getThemeId:themeId
                                success:nil
                                failure:nil]);
}

- (void)testThatGetThemesWorks
{
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    ThemeServiceRemote *service = nil;

    static NSInteger const expectedThemes = 20;

    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:api]);

    NSString *url = [service pathForEndpoint:@"themes"
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_2];

    ThemeServiceRemoteThemesRequestSuccessBlock successBlock = ^void (NSArray<RemoteTheme *> *themes, BOOL hasMore, NSInteger totalThemeCount) {
        NSCAssert([themes count] == expectedThemes, @"Expected %ld themes to be returned", expectedThemes);
        NSCAssert(totalThemeCount == expectedThemes, @"Expected %ld themes to be found", expectedThemes);
    };
    
    [OCMStub([api GET:[OCMArg isEqual:url]
           parameters:[OCMArg isNotNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]) andDo:^(NSInvocation *invocation) {

        NSInteger successBlockParameterIndex = InvocationFirstParameterIndex + 2;
        RequestSuccessBlock successBlock;

        [invocation getArgument:&successBlock atIndex:successBlockParameterIndex];
        NSCAssert(successBlock != nil, @"Expected a success block");

        JSONLoader *loader = [[JSONLoader alloc] init];
        NSDictionary *jsonDictionary = [loader loadFile:ThemeServiceRemoteTestGetMultipleThemesJson
                                                   type:@"json"];
        NSCAssert([jsonDictionary isKindOfClass:[NSDictionary class]],
                  @"Expected a json dictionary here.  Make sure the json file for this test is well formatted.");
        
        successBlock(jsonDictionary, nil);
    }];

    XCTAssertNoThrow([service getWPThemesPage:1
                                     freeOnly:NO
                                      success:successBlock
                                      failure:nil]);
}

- (void)testThatGetThemesForBlogIdWorks
{
    NSNumber *blogId = @124;

    ThemeServiceRemoteThemesRequestSuccessBlock successBlock = ^void (NSArray<RemoteTheme *> *themes, BOOL hasMore, NSInteger totalThemeCount) {
        NSCAssert([themes count] > 0, @"Expected themes to be returned");
        NSCAssert(totalThemeCount > 0, @"Expected total themes count to be > 0");
    };
    
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    ThemeServiceRemote *service = nil;

    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:api]);

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/themes", blogId];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_2];

    [OCMStub([api GET:[OCMArg isEqual:url]
           parameters:[OCMArg isNotNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]) andDo:^(NSInvocation *invocation) {
        
        NSInteger successBlockParameterIndex = InvocationFirstParameterIndex + 2;
        RequestSuccessBlock successBlock;
        
        [invocation getArgument:&successBlock atIndex:successBlockParameterIndex];
        NSCAssert(successBlock != nil, @"Expected a success block");
        
        JSONLoader *loader = [[JSONLoader alloc] init];
        NSDictionary *jsonDictionary = [loader loadFile:ThemeServiceRemoteTestGetMultipleThemesJson
                                                   type:@"json"];
        NSCAssert([jsonDictionary isKindOfClass:[NSDictionary class]],
                  @"Expected a json dictionary here.  Make sure the json file for this test is well formatted.");
        
        successBlock(jsonDictionary, nil);
    }];

    XCTAssertNoThrow([service getThemesForBlogId:blogId
                                            page:1
                                         success:successBlock
                                         failure:nil]);
}

- (void)testThatGetThemesForBlogIdThrowsExceptionWithoutBlogId
{
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    ThemeServiceRemote *service = nil;

    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:api]);
    XCTAssertThrows([service getThemesForBlogId:nil
                                           page:1
                                        success:nil
                                        failure:nil]);
}

#pragma mark - Activating themes

- (void)testThatActivateThemeIdWorks
{
    NSNumber *blogId = @124;
    NSString *themeId = @"obsidian";
    NSString *themeParameterKey = @"theme";
    
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    ThemeServiceRemote *service = nil;

    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:api]);

    NSString *endpoint = [NSString stringWithFormat:@"sites/%@/themes/mine", blogId];
    NSString *url = [service pathForEndpoint:endpoint
                                 withVersion:ServiceRemoteWordPressComRESTApiVersion_1_1];

    DictionaryVerificationBlock checkBlock = ^BOOL(NSDictionary *parameters) {
        NSCAssert([parameters isKindOfClass:[NSDictionary class]],
                  @"Type mistmatch for the 'parameters' param.");
        
        NSString* themeIdParameter = [parameters objectForKey:themeParameterKey];
        
        return [themeIdParameter isEqualToString:themeId];
    };

    [OCMStub([api POST:[OCMArg isEqual:url]
            parameters:[OCMArg checkWithBlock:checkBlock]
               success:[OCMArg isNotNil]
               failure:[OCMArg isNotNil]]) andDo:^(NSInvocation *invocation) {
       
        RequestSuccessBlock successBlock;
        RequestFailureBlock failureBlock;
        
        NSInteger successBlockParameterIndex = InvocationFirstParameterIndex + 2;
        NSInteger failureBlockParameterIndex = InvocationFirstParameterIndex + 3;
        
        [invocation getArgument:&successBlock atIndex:successBlockParameterIndex];
        [invocation getArgument:&failureBlock atIndex:failureBlockParameterIndex];
        
        NSCAssert(successBlock != nil, @"Expected a success block");
        NSCAssert(failureBlock != nil, @"Expected a failure block");
    }];
    
    XCTAssertNoThrow([service activateThemeId:themeId
                                    forBlogId:blogId
                                      success:nil
                                      failure:nil]);
}

- (void)testThatActivateThemeIdThrowsExceptionWithoutThemeId
{
    NSNumber *blogId = @124;

    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    ThemeServiceRemote *service = nil;
    
    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:api]);
    XCTAssertThrows([service activateThemeId:nil
                                   forBlogId:blogId
                                     success:nil
                                     failure:nil]);
}

- (void)testThatActivateThemeIdThrowsExceptionWithoutBlogId
{
    NSString *themeId = @"obsidian";
    
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    ThemeServiceRemote *service = nil;
    
    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithWordPressComRestApi:api]);
    XCTAssertThrows([service activateThemeId:themeId
                                   forBlogId:nil
                                     success:nil
                                     failure:nil]);
}

@end
