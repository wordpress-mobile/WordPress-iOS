#import <XCTest/XCTest.h>
#import "Blog.h"
#import "Theme.h"
#import "ThemeService.h"
#import "WPAccount.h"
#import "WordPressTest-Swift.h"

@import WordPressKit;
@import OCMock;

#pragma mark - Support classes

#pragma mark - Tests

@interface ThemeServiceTests : XCTestCase
@property (nonatomic, strong) id<CoreDataStack> manager;
@end

@implementation ThemeServiceTests

- (void)setUp
{
    [super setUp];
    self.manager = [self coreDataStackForTesting];
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

    ThemeService *service = [[ThemeService alloc] initWithCoreDataStack:self.manager];
    BOOL result = NO;
    
    XCTAssertNoThrow(result = [service blogSupportsThemeServices:blog]);
    XCTAssertTrue(result);
}

- (void)testThatSelfHostedBlogDoesNotSupportThemeServices
{    
    NSManagedObjectContext *context = self.manager.mainContext;
    Blog *blog = [ModelTestHelper insertSelfHostedBlogWithContext:context];

    ThemeService *service = [[ThemeService alloc] initWithCoreDataStack:self.manager];
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
    blog.account._private_wordPressComRestApi = api;
    ThemeService *service = nil;
    NSNumber *blogId = @1;
    NSString *url = [NSString stringWithFormat:@"rest/v1.1/sites/%@/themes/mine", blogId];

    blog.dotComID = blogId;

    OCMStub([api get:[OCMArg isEqual:url]
          parameters:[OCMArg isNil]
             success:[OCMArg any]
             failure:[OCMArg any]]);
    
    XCTAssertNoThrow(service = [[ThemeService alloc] initWithCoreDataStack:self.manager]);
    XCTAssertNoThrow([service getActiveThemeForBlog:blog
                                            success:nil
                                            failure:nil]);
}

- (void)testThatGetActiveThemeForBlogThrowsExceptionWithoutBlog
{
    ThemeService *service = nil;
    
    XCTAssertNoThrow(service = [[ThemeService alloc] initWithCoreDataStack:self.manager]);
    XCTAssertThrows([service getActiveThemeForBlog:nil
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
    blog.account._private_wordPressComRestApi = api;

    OCMStub([api get:[OCMArg isEqual:url]
          parameters:[OCMArg isNotNil]
             success:[OCMArg any]
             failure:[OCMArg any]]);
    
    XCTAssertNoThrow(service = [[ThemeService alloc] initWithCoreDataStack:self.manager]);
    XCTAssertNoThrow([service getThemesForBlog:blog
                                          page:1
                                          sync:NO
                                       success:nil
                                       failure:nil]);
}

- (void)testThatGetThemesForBlogThrowsExceptionWithoutBlog
{
    ThemeService *service = nil;
    
    XCTAssertNoThrow(service = [[ThemeService alloc] initWithCoreDataStack:self.manager]);
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
    blog.account._private_wordPressComRestApi = api;

    OCMStub([api post:[OCMArg isEqual:url]
           parameters:[OCMArg isNotNil]
              success:[OCMArg any]
              failure:[OCMArg any]]);
    
    XCTAssertNoThrow(service = [[ThemeService alloc] initWithCoreDataStack:self.manager]);
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
    blog.account._private_wordPressComRestApi = api;

    XCTAssertNoThrow(service = [[ThemeService alloc] initWithCoreDataStack:self.manager]);
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

    XCTAssertNoThrow(service = [[ThemeService alloc] initWithCoreDataStack:self.manager]);
    XCTAssertThrows([service activateTheme:theme
                                   forBlog:nil
                                   success:nil
                                   failure:nil]);
}

@end

