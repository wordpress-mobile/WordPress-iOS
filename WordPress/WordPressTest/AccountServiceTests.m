#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "TestContextManager.h"
#import "AccountService.h"
#import "WPAccount.h"
#import "Blog.h"

@interface AccountService ()
- (void)fixDefaultAccount;
@end


@interface AccountServiceTests : XCTestCase
@property (nonatomic, strong) WPAccount *offsiteAccount;
@property (nonatomic, strong) WPAccount *rightAccount;
@property (nonatomic, strong) WPAccount *wrongAccount;
@end

@implementation AccountServiceTests

- (void)setUp {
    NSManagedObjectContext *context = [[TestContextManager new] mainContext];
    
    // Offsite account
    self.offsiteAccount         = [self newAccountInContext:context];
    self.offsiteAccount.isWpcom = false;
    
    // WordPress.com account with one blog
    self.rightAccount           = [self newAccountInContext:context];
    self.rightAccount.isWpcom   = true;
    
    Blog *rightBlog             = [self newBlogInContext:context];
    rightBlog.account           = self.rightAccount;
    
    [self.rightAccount addBlogsObject:rightBlog];
    
    // WordPress.com account with just one Jetpack Blog
    self.wrongAccount           = [self newAccountInContext:context];
    self.wrongAccount.isWpcom   = true;
    
    Blog *wrongBlog             = [self newBlogInContext:context];
    wrongBlog.account           = self.wrongAccount;
    
    [self.wrongAccount addJetpackBlogsObject:wrongBlog];
    
    // Save!
    [context save:nil];
}

- (void)testAccountFixDoesntModifyAnythingIfTheDefaultIsWPCOM {
    
    NSManagedObjectContext *context = [[TestContextManager sharedInstance] mainContext];
    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:context];
    [service setDefaultWordPressComAccount:self.wrongAccount];
    
    // Force the Account fix
    [service fixDefaultAccountIfNeeded];
    
    XCTAssertEqualObjects(service.defaultWordPressComAccount, self.wrongAccount, @"Invalid account picked up");
}

- (void)testAccountFixUpdatesDefaultAccountIfDefaultIsNotWordPressDotCom {
    
    NSManagedObjectContext *context = [[TestContextManager sharedInstance] mainContext];
    AccountService *service = [[AccountService alloc] initWithManagedObjectContext:context];
    
    // Hack: Bypass an assertion in the default WP account setter
    self.offsiteAccount.isWpcom = true;
    [service setDefaultWordPressComAccount:self.offsiteAccount];
    self.offsiteAccount.isWpcom = false;
    
    // Force the Account fix
    [service fixDefaultAccountIfNeeded];
    
    XCTAssertEqualObjects(service.defaultWordPressComAccount, self.rightAccount, @"Invalid account picked up");
}


#pragma mark - Helper Methods

- (WPAccount *)newAccountInContext:(NSManagedObjectContext *)context {
    WPAccount *account  = [NSEntityDescription insertNewObjectForEntityForName:@"Account" inManagedObjectContext:context];
    account.username    = [NSString string];
    account.password    = [NSString string];
    account.authToken   = @"123";
    account.uuid        = [NSUUID UUID].UUIDString;
    return account;
}

- (Blog *)newBlogInContext:(NSManagedObjectContext *)context {
    Blog *blog          = [NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:context];
    blog.xmlrpc         = @"http://test.blog/xmlrpc.php";
    blog.url            = @"http://test.blog/";
    return blog;
}

@end
