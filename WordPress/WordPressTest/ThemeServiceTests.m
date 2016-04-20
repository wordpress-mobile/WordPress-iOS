#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "Blog.h"
#import "Theme.h"
#import "ThemeService.h"
#import "ThemeServiceRemote.h"
#import "WPAccount.h"

#pragma mark - Support classes

// OCMock doesn't properly support CoreData dynamic properties yet.  We can use a subclass
// to fix this for the tests that need such support.
//
// REF: http://stackoverflow.com/questions/24225300/cannot-stub-method-title-because-no-such-method-exist-in-the-mocked-class-ocmo
//
@interface ThemeForStubbing : Theme
@property (nonatomic, strong, readwrite) NSString *themeId;
@end

@implementation ThemeForStubbing
@synthesize themeId;
@end

#pragma mark - Tests

@interface ThemeServiceTests : XCTestCase
@end

@implementation ThemeServiceTests

#pragma mark - Initialization

- (void)testThatInitializationFailsWithoutAManagedObjectContext
{
    XCTAssertThrows([[ThemeService alloc] initWithManagedObjectContext:nil]);
}

#pragma mark - Themes availability

- (void)testThatWordPressBlogSupportsThemeServices
{
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    
    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog restApi]).andReturn(api);
    OCMStub([blog dotComID]).andReturn(@1);
    
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    
    ThemeService *service = [[ThemeService alloc] initWithManagedObjectContext:context];
    BOOL result = NO;
    
    XCTAssertNoThrow(result = [service blogSupportsThemeServices:blog]);
    XCTAssertTrue(result);
}

- (void)testThatSelfHostedBlogDoesNotSupportThemeServices
{    
    Blog *blog = OCMStrictClassMock([Blog class]);
    OCMStub([blog restApi]).andReturn(nil);
    OCMStub([blog dotComID]).andReturn(nil);
    
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    
    ThemeService *service = [[ThemeService alloc] initWithManagedObjectContext:context];
    BOOL result = NO;
    
    XCTAssertNoThrow(result = [service blogSupportsThemeServices:blog]);
    XCTAssertTrue(!result);
}

#pragma mark - Getting themes

- (void)testThatGetActiveThemeForBlogWorks
{
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    Blog *blog = OCMStrictClassMock([Blog class]);
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeService *service = nil;
    NSNumber *blogId = @1;
    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/themes/mine", blogId];
    
    OCMStub([blog restApi]).andReturn(api);
    OCMStub([blog dotComID]).andReturn(blogId);
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg any]
             failure:[OCMArg any]]);
    
    XCTAssertNoThrow(service = [[ThemeService alloc] initWithManagedObjectContext:context]);
    XCTAssertNoThrow([service getActiveThemeForBlog:blog
                                            success:nil
                                            failure:nil]);
}

- (void)testThatGetActiveThemeForBlogThrowsExceptionWithoutBlog
{
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    ThemeService *service = nil;
    
    XCTAssertNoThrow(service = [[ThemeService alloc] initWithManagedObjectContext:context]);
    XCTAssertThrows([service getActiveThemeForBlog:nil
                                           success:nil
                                           failure:nil]);
}
    
- (void)testThatGetPurchasedThemesForBlogWorks
{
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    Blog *blog = OCMStrictClassMock([Blog class]);
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeService *service = nil;
    NSNumber *blogId = @1;
    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/themes/purchased", blogId];
    
    OCMStub([blog restApi]).andReturn(api);
    OCMStub([blog dotComID]).andReturn(blogId);
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg any]
             failure:[OCMArg any]]);
    
    XCTAssertNoThrow(service = [[ThemeService alloc] initWithManagedObjectContext:context]);
    XCTAssertNoThrow([service getPurchasedThemesForBlog:blog
                                                success:nil
                                                failure:nil]);
}

- (void)testThatGetPurchasedThemesForBlogThrowsExceptionWithoutBlog
{
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    ThemeService *service = nil;
    
    XCTAssertNoThrow(service = [[ThemeService alloc] initWithManagedObjectContext:context]);
    XCTAssertThrows([service getPurchasedThemesForBlog:nil
                                               success:nil
                                               failure:nil]);
}

- (void)testThatGetThemeIdWorks
{
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    WPAccount *account = OCMStrictClassMock([WPAccount class]);
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeService *service = nil;
    NSString *themeId = @"SomeTheme";
    NSString *url = [NSString stringWithFormat:@"v1.1/themes/%@", themeId];
    
    OCMStub([account restApi]).andReturn(api);
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg any]
             failure:[OCMArg any]]);
    
    XCTAssertNoThrow(service = [[ThemeService alloc] initWithManagedObjectContext:context]);
    XCTAssertNoThrow([service getThemeId:themeId
                              forAccount:account
                                 success:nil
                                 failure:nil]);
}

- (void)testThatGetThemeIdThrowsExceptionWithoutThemeId
{
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    WPAccount *account = OCMStrictClassMock([WPAccount class]);
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeService *service = nil;
    
    OCMStub([account restApi]).andReturn(api);
    
    XCTAssertNoThrow(service = [[ThemeService alloc] initWithManagedObjectContext:context]);
    XCTAssertThrows([service getThemeId:nil
                             forAccount:account
                                success:nil
                                failure:nil]);
}

- (void)testThatGetThemeIdThrowsExceptionWithoutAccount
{
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    ThemeService *service = nil;
    NSString *themeId = @"SomeTheme";
    
    XCTAssertNoThrow(service = [[ThemeService alloc] initWithManagedObjectContext:context]);
    XCTAssertThrows([service getThemeId:themeId
                             forAccount:nil
                                success:nil
                                failure:nil]);
}

- (void)testThatGetThemesForAccountWorks
{
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    WPAccount *account = OCMStrictClassMock([WPAccount class]);
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeService *service = nil;
    NSString *url = @"v1.2/themes";
    
    OCMStub([account restApi]).andReturn(api);
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNotNil]
             success:[OCMArg any]
             failure:[OCMArg any]]);
    
    XCTAssertNoThrow(service = [[ThemeService alloc] initWithManagedObjectContext:context]);
    XCTAssertNoThrow([service getThemesForAccount:account
                                             page:1
                                          success:nil
                                          failure:nil]);
}

- (void)testThatGetThemesForAccountThrowsExceptionWithoutAccount
{
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    ThemeService *service = nil;
    
    XCTAssertNoThrow(service = [[ThemeService alloc] initWithManagedObjectContext:context]);
    XCTAssertThrows([service getThemesForAccount:nil
                                            page:1
                                         success:nil
                                         failure:nil]);
}

- (void)testThatGetThemesForBlogWorks
{
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    Blog *blog = OCMStrictClassMock([Blog class]);
    NSNumber *blogId = @1;
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeService *service = nil;
    NSString *url = [NSString stringWithFormat:@"v1.2/sites/%@/themes", blogId];
    
    OCMStub([blog restApi]).andReturn(api);
    OCMStub([blog dotComID]).andReturn(blogId);
    
    OCMStub([api GET:[OCMArg isEqual:url]
          parameters:[OCMArg isNotNil]
             success:[OCMArg any]
             failure:[OCMArg any]]);
    
    XCTAssertNoThrow(service = [[ThemeService alloc] initWithManagedObjectContext:context]);
    XCTAssertNoThrow([service getThemesForBlog:blog
                                          page:1
                                          sync:NO
                                       success:nil
                                       failure:nil]);
}

- (void)testThatGetThemesForBlogThrowsExceptionWithoutBlog
{
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    ThemeService *service = nil;
    
    XCTAssertNoThrow(service = [[ThemeService alloc] initWithManagedObjectContext:context]);
    XCTAssertThrows([service getThemesForBlog:nil
                                         page:1
                                         sync:NO
                                      success:nil
                                      failure:nil]);
}

- (void)testThatActivateThemeWorks
{
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    Blog *blog = OCMStrictClassMock([Blog class]);
    Theme *theme = OCMStrictClassMock([ThemeForStubbing class]);
    NSNumber *blogId = @1;
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeService *service = nil;
    NSString *url = [NSString stringWithFormat:@"v1.1/sites/%@/themes/mine", blogId];
    
    OCMStub([theme themeId]).andReturn(@"SomeThemeId");
    
    OCMStub([blog restApi]).andReturn(api);
    OCMStub([blog dotComID]).andReturn(blogId);
    
    OCMStub([api POST:[OCMArg isEqual:url]
           parameters:[OCMArg isNotNil]
              success:[OCMArg any]
              failure:[OCMArg any]]);
    
    XCTAssertNoThrow(service = [[ThemeService alloc] initWithManagedObjectContext:context]);
    XCTAssertNoThrow([service activateTheme:theme
                                    forBlog:blog
                                    success:nil
                                    failure:nil]);
}

- (void)testThatActivateThemeThrowsExceptionWithoutTheme
{
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    Blog *blog = OCMStrictClassMock([Blog class]);
    NSNumber *blogId = @1;
    WordPressComApi *api = OCMStrictClassMock([WordPressComApi class]);
    ThemeService *service = nil;
    
    OCMStub([blog restApi]).andReturn(api);
    OCMStub([blog dotComID]).andReturn(blogId);
    
    XCTAssertNoThrow(service = [[ThemeService alloc] initWithManagedObjectContext:context]);
    XCTAssertThrows([service activateTheme:nil
                                   forBlog:blog
                                   success:nil
                                   failure:nil]);
}

- (void)testThatActivateThemeThrowsExceptionWithoutBlog
{
    NSManagedObjectContext *context = OCMStrictClassMock([NSManagedObjectContext class]);
    Theme *theme = OCMStrictClassMock([ThemeForStubbing class]);
    ThemeService *service = nil;
    
    OCMStub([theme themeId]).andReturn(@"SomeThemeId");
    
    XCTAssertNoThrow(service = [[ThemeService alloc] initWithManagedObjectContext:context]);
    XCTAssertThrows([service activateTheme:theme
                                   forBlog:nil
                                   success:nil
                                   failure:nil]);
}

@end

