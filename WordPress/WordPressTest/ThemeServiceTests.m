#import <OCMock/OCMock.h>
#import <XCTest/XCTest.h>
#import "Blog.h"
#import "TestContextManager.h"
#import "Theme.h"
#import "ThemeService.h"
#import "WPAccount.h"
#import "WordPressTest-Swift.h"
@import WordPressKit;

#pragma mark - Support classes

@interface WPAccount ()
@property (nonatomic, readwrite) WordPressComRestApi *wordPressComRestApi;
@end

#pragma mark - Tests

@interface ThemeServiceTests : XCTestCase
@property (nonatomic, strong) TestContextManager *manager;
@end

@implementation ThemeServiceTests

- (void)setUp
{
    [super setUp];
    self.manager = [TestContextManager new];
}

- (void)tearDown
{
    self.manager = nil;
    [super tearDown];
}

#pragma mark - Themes availability

- (void)testThatWordPressBlogSupportsThemeServices
{
    NSManagedObjectContext *context = self.manager.mainContext;
    
    Blog *blog = [ModelTestHelper insertDotComBlogWithContext:context];

    ThemeService *service = [[ThemeService alloc] initWithManagedObjectContext:context];
    BOOL result = NO;
    
    XCTAssertNoThrow(result = [service blogSupportsThemeServices:blog]);
    XCTAssertTrue(result);
}

- (void)testThatSelfHostedBlogDoesNotSupportThemeServices
{    
    NSManagedObjectContext *context = self.manager.mainContext;
    Blog *blog = [ModelTestHelper insertSelfHostedBlogWithContext:context];

    ThemeService *service = [[ThemeService alloc] initWithManagedObjectContext:context];
    BOOL result = NO;
    
    XCTAssertNoThrow(result = [service blogSupportsThemeServices:blog]);
    XCTAssertTrue(!result);
}

#pragma mark - Getting themes

- (void)testThatGetActiveThemeForBlogWorks
{
    NSManagedObjectContext *context = self.manager.mainContext;
    Blog *blog = [ModelTestHelper insertDotComBlogWithContext:context];
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    blog.account.wordPressComRestApi = api;
    ThemeService *service = nil;
    NSNumber *blogId = @1;
    NSString *url = [NSString stringWithFormat:@"rest/v1.1/sites/%@/themes/mine", blogId];

    blog.dotComID = blogId;

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
    NSManagedObjectContext *context = self.manager.mainContext;
    Blog *blog = [ModelTestHelper insertDotComBlogWithContext:context];
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    blog.account.wordPressComRestApi = api;
    ThemeService *service = nil;
    NSNumber *blogId = @1;
    NSString *url = [NSString stringWithFormat:@"rest/v1.1/sites/%@/themes/purchased", blogId];
    blog.dotComID = blogId;
    
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
    NSManagedObjectContext *context = self.manager.mainContext;
    WPAccount *account = [ModelTestHelper insertAccountWithContext:context];
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    account.wordPressComRestApi = api;
    ThemeService *service = nil;
    NSString *themeId = @"SomeTheme";
    NSString *url = [NSString stringWithFormat:@"rest/v1.1/themes/%@", themeId];
    
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
    NSManagedObjectContext *context = self.manager.mainContext;
    WPAccount *account = [ModelTestHelper insertAccountWithContext:context];
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    account.wordPressComRestApi = api;
    ThemeService *service = nil;

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
    NSManagedObjectContext *context = self.manager.mainContext;
    WPAccount *account = [ModelTestHelper insertAccountWithContext:context];
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    account.wordPressComRestApi = api;
    ThemeService *service = nil;
    NSString *url = @"rest/v1.2/themes";

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
    NSManagedObjectContext *context = self.manager.mainContext;
    Blog *blog = [ModelTestHelper insertDotComBlogWithContext:context];
    NSNumber *blogId = @1;
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    ThemeService *service = nil;
    NSString *url = [NSString stringWithFormat:@"rest/v1.2/sites/%@/themes", blogId];

    blog.dotComID = blogId;
    blog.account.wordPressComRestApi = api;

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
    NSManagedObjectContext *context = self.manager.mainContext;
    Blog *blog = [ModelTestHelper insertDotComBlogWithContext:context];
    Theme *theme = [NSEntityDescription insertNewObjectForEntityForName:[Theme entityName] inManagedObjectContext:context];
    NSNumber *blogId = @1;
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    ThemeService *service = nil;
    NSString *url = [NSString stringWithFormat:@"rest/v1.1/sites/%@/themes/mine", blogId];
    
    theme.themeId = @"SomeThemeId";

    blog.dotComID = blogId;
    blog.account.wordPressComRestApi = api;

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
    NSManagedObjectContext *context = self.manager.mainContext;
    Blog *blog = [ModelTestHelper insertDotComBlogWithContext:context];
    NSNumber *blogId = @1;
    WordPressComRestApi *api = OCMStrictClassMock([WordPressComRestApi class]);
    ThemeService *service = nil;

    blog.dotComID = blogId;
    blog.account.wordPressComRestApi = api;

    XCTAssertNoThrow(service = [[ThemeService alloc] initWithManagedObjectContext:context]);
    XCTAssertThrows([service activateTheme:nil
                                   forBlog:blog
                                   success:nil
                                   failure:nil]);
}

- (void)testThatActivateThemeThrowsExceptionWithoutBlog
{
    NSManagedObjectContext *context = self.manager.mainContext;
    Theme *theme = [NSEntityDescription insertNewObjectForEntityForName:[Theme entityName] inManagedObjectContext:context];
    ThemeService *service = nil;

    theme.themeId = @"SomeThemeId";

    XCTAssertNoThrow(service = [[ThemeService alloc] initWithManagedObjectContext:context]);
    XCTAssertThrows([service activateTheme:theme
                                   forBlog:nil
                                   success:nil
                                   failure:nil]);
}

@end

