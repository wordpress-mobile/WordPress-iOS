#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "Theme.h"
#import "ThemeServiceRemote.h"
#import "WordPressComApi.h"
#import "WordPress-Swift.h"

// OCMock helper typedefs
typedef BOOL (^DictionaryVerificationBlock)(NSDictionary *dictionary);

// AFHTTP helper typedefs
typedef void (^RequestSuccessBlock)(AFHTTPRequestOperation *operation, id responseObject);
typedef void (^RequestFailureBlock)(AFHTTPRequestOperation *, NSError *);

// NSInvocation helper constants
static const NSInteger InvocationFirstParameterIndex = 2;

@interface ThemeServiceRemoteTests : XCTestCase
@end

@implementation ThemeServiceRemoteTests

#pragma mark - Getting the themes

- (void)testThatGetActiveThemeForBlogIdWorks
{
    NSNumber *blogId = @124;

    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeServiceRemote *service = nil;

    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/themes/mine", blogId];

    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);

    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithApi:api]);
    XCTAssertNoThrow([service getActiveThemeForBlogId:blogId
                                              success:nil
                                              failure:nil]);
}

- (void)testThatGetActiveThemeForBlogThrowsExceptionWithoutBlogId
{
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeServiceRemote *service = nil;

    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithApi:api]);
    XCTAssertThrows([service getActiveThemeForBlogId:nil
                                             success:nil
                                             failure:nil]);
}

- (void)testThatGetPurchasedThemesForBlogIdWorks
{
    NSNumber *blogId = @124;

    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeServiceRemote *service = nil;

    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/themes/purchased", blogId];

    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);

    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithApi:api]);
    XCTAssertNoThrow([service getPurchasedThemesForBlogId:blogId
                                                  success:nil
                                                  failure:nil]);
}

- (void)testThatGetPurchasedThemesForBlogIdThrowsExceptionWithoutBlogId
{
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeServiceRemote *service = nil;

    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithApi:api]);
    XCTAssertThrows([service getPurchasedThemesForBlogId:nil
                                                 success:nil
                                                 failure:nil]);
}

- (void)testThatGetThemeIdWorks
{
    NSString *themeId = @"obsidian";
    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeServiceRemote *service = nil;
    
    NSString *url = [NSString stringWithFormat:@"v1.1/themes/%@", themeId];
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);
    
    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithApi:api]);
    XCTAssertNoThrow([service getThemeId:themeId
                                 success:nil
                                 failure:nil]);
}

- (void)testThatGetThemeIdThrowsExceptionWithoutThemeId
{
    NSString *themeId = @"obsidian";
    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeServiceRemote *service = nil;
    
    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithApi:api]);
    XCTAssertThrows([service getThemeId:themeId
                                success:nil
                                failure:nil]);
}

- (void)testThatGetThemesWorks
{
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeServiceRemote *service = nil;

    static NSString* const url = @"v1.1/themes";

    ThemeServiceRemoteThemesRequestSuccessBlock successBlock = ^void (NSArray *themes) {
    };
    
    [OCMStub([api GET:[OCMArg isEqual:url]
           parameters:[OCMArg isNil]
              success:[OCMArg isNotNil]
              failure:[OCMArg isNotNil]]) andDo:^(NSInvocation *invocation) {
        
        NSInteger successBlockParameterIndex = InvocationFirstParameterIndex + 2;
        RequestSuccessBlock successBlock;

        [invocation getArgument:&successBlock atIndex:successBlockParameterIndex];
        NSCAssert(successBlock != nil, @"Expected a success block");
        
        JSONLoader *loader = [JSONLoader alloc];
        NSDictionary *jsonDictionary = [loader load:@"get-themes-v1.1.json"];
        
        //successBlock(operation, responseObject);
    }];

    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithApi:api]);
    XCTAssertNoThrow([service getThemes:successBlock
                                failure:nil]);
}

- (void)testThatGetThemesForBlogIdWorks
{
    NSNumber *blogId = @124;

    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeServiceRemote *service = nil;

    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/themes", blogId];

    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg isNotNil]
             failure:[OCMArg isNotNil]]);

    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithApi:api]);
    XCTAssertNoThrow([service getThemesForBlogId:blogId
                                         success:nil
                                         failure:nil]);
}

- (void)testThatGetThemesForBlogIdThrowsExceptionWithoutBlogId
{
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeServiceRemote *service = nil;

    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithApi:api]);
    XCTAssertThrows([service getThemesForBlogId:nil
                                        success:nil
                                        failure:nil]);
}

#pragma mark - Activating themes

- (void)testThatActivateThemeIdWorks
{
    NSNumber *blogId = @124;
    NSString *themeId = @"obsidian";
    NSString *themeParameterKey = @"theme";
    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeServiceRemote *service = nil;
    
    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/themes/mine", blogId];

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
    
    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithApi:api]);
    XCTAssertNoThrow([service activateThemeId:themeId
                                    forBlogId:blogId
                                      success:nil
                                      failure:nil]);
}

- (void)testThatActivateThemeIdThrowsExceptionWithoutThemeId
{
    NSNumber *blogId = @124;

    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeServiceRemote *service = nil;
    
    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithApi:api]);
    XCTAssertThrows([service activateThemeId:nil
                                   forBlogId:blogId
                                     success:nil
                                     failure:nil]);
}

- (void)testThatActivateThemeIdThrowsExceptionWithoutBlogId
{
    NSString *themeId = @"obsidian";
    
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeServiceRemote *service = nil;
    
    XCTAssertNoThrow(service = [[ThemeServiceRemote alloc] initWithApi:api]);
    XCTAssertThrows([service activateThemeId:themeId
                                   forBlogId:nil
                                     success:nil
                                     failure:nil]);
}

@end
