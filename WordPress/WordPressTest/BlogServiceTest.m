#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "AccountService.h"
#import "BlogService.h"
#import "ContextManager.h"
#import "Blog.h"
#import "WPAccount.h"
#import "WordPressTest-Swift.h"

@interface BlogServiceTest : XCTestCase

@property (nonatomic, strong) BlogService *blogService;
@property (nonatomic, strong) id blogServiceMock;
@property (nonatomic, strong) Blog *blog;
@property (nonatomic, strong) ContextManagerMock *coreDataStack;

@end

@implementation BlogServiceTest

- (void)setUp
{
    [super setUp];

    self.coreDataStack = [[ContextManagerMock alloc] init];

    self.blogService = [[BlogService alloc] initWithManagedObjectContext:[self.coreDataStack mainContext]];
    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:self.coreDataStack.mainContext];
    WPAccount *account = [service createOrUpdateAccountWithUsername:@"test" authToken:@"token"];
    self.blog = (Blog *)[NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:self.coreDataStack.mainContext];
    self.blog.xmlrpc = @"http://test.blog/xmlrpc.php";
    self.blog.url = @"http://test.blog/";
    self.blog.options = @{@"jetpack_version": @{
                                  @"value": @"1.8.2",
                                  @"desc": @"stub",
                                  @"readonly": @YES,
                                  },
                          @"jetpack_client_id": @{
                                  @"value": @"1",
                                  @"desc": @"stub",
                                  @"readonly": @YES,
                                  },
                          };
    self.blog.account = account;
    self.blog.settings = (BlogSettings *)[NSEntityDescription insertNewObjectForEntityForName:@"BlogSettings"
                                                                       inManagedObjectContext:self.coreDataStack.mainContext];

    self.blogServiceMock = OCMPartialMock(self.blogService);

    [service setDefaultWordPressComAccount:account];
}

- (void)tearDown
{
    [self cleanUpNSUserDefaultValues];

    self.blogService = nil;
    self.blogServiceMock = nil;
    self.blog = nil;
    self.coreDataStack = nil;

    [super tearDown];
}

- (void)cleanUpNSUserDefaultValues
{
    [UserSettings setDefaultDotComUUID:nil];
}

@end
