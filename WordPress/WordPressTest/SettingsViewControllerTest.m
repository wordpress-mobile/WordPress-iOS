#import <XCTest/XCTest.h>
#import "CoreDataTestHelper.h"
#import "WPAccount.h"
#import "Blog.h"
#import "NotificationsManager.h"
#import "SettingsViewController.h"
#import "ContextManager.h"
#import "AccountService.h"

@interface SettingsViewControllerTest : XCTestCase

@end

@implementation SettingsViewControllerTest

- (void)setUp
{
    [super setUp];

    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    if (defaultAccount) {
        [accountService removeDefaultWordPressComAccount];
    }
}

- (void)tearDown
{
    [super tearDown];
    [[CoreDataTestHelper sharedHelper] reset];
    [CoreDataTestHelper sharedHelper].testExpectation = nil;
}

- (void)testWpcomSection
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    XCTAssertNil(defaultAccount, @"There should be no default account");
    
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:NotificationsDeviceToken];
    SettingsViewController *controller = [self settingsViewController];
    [self present:controller];

    UITableView *table = controller.tableView;
    UITableViewCell *cell = [self tableView:table cellForRow:0];

    /*
     Signed out

     - Sign In
     */
    XCTAssertEqual(1, [table numberOfRowsInSection:0]);
    XCTAssertEqualObjects(@"Sign In", cell.accessibilityIdentifier);


    // Sign In
    XCTestExpectation *saveExpectation = [self expectationWithDescription:@"Context save expectation"];
    [CoreDataTestHelper sharedHelper].testExpectation = saveExpectation;

    WPAccount *account = [accountService createOrUpdateWordPressComAccountWithUsername:@"jacksparrow" password:@"piratesobrave" authToken:@"token"];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    /*
     Signed In, Notifications disabled, 1 blog

     - Username     jacksparrow
     - Sign Out
     */
    XCTAssertEqual(2, [table numberOfRowsInSection:0]);
    cell = [self tableView:table cellForRow:0];
    XCTAssertEqualObjects(@"Username", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:1];
    XCTAssertEqualObjects(@"Sign Out", cell.accessibilityIdentifier);

    [[NSUserDefaults standardUserDefaults] setObject:@"aFakeAPNSToken" forKey:NotificationsDeviceToken];
    [table reloadData];

    /*
     Signed In, Notifications enabled, 0 blogs

     - Username     jacksparrow
     - Manage Notifications
     - Sign Out
     */
    XCTAssertEqual(3, [table numberOfRowsInSection:0]);
    cell = [self tableView:table cellForRow:0];
    XCTAssertEqualObjects(@"Username", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:1];
    XCTAssertEqualObjects(@"Manage Notifications", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:2];
    XCTAssertEqualObjects(@"Sign Out", cell.accessibilityIdentifier);

    saveExpectation = [self expectationWithDescription:@"Context save expectation"];
    [CoreDataTestHelper sharedHelper].testExpectation = saveExpectation;
    
    NSString *xmlrpc = @"http://blog1.com/xmlrpc.php";
    NSString *url = @"blog1.com";
    Blog *blog = [accountService findBlogWithXmlrpc:xmlrpc inAccount:account];
    if (!blog) {
        blog = [accountService createBlogWithAccount:account];
        blog.xmlrpc = xmlrpc;
        blog.url = url;
    }
    [[ContextManager sharedInstance] saveContext:account.managedObjectContext];
    [self waitForExpectationsWithTimeout:2.0 handler:nil];

    [table reloadData];

    /*
     Signed In, Notifications enabled, 1 blogs

     - Username     jacksparrow
     - Manage Notifications
     - Sign Out
     */
    XCTAssertEqual(3, [table numberOfRowsInSection:0]);
    cell = [self tableView:table cellForRow:0];
    XCTAssertEqualObjects(@"Username", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:1];
    XCTAssertEqualObjects(@"Manage Notifications", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:2];
    XCTAssertEqualObjects(@"Sign Out", cell.accessibilityIdentifier);
    
    saveExpectation = [self expectationWithDescription:@"Context save expectation"];
    [CoreDataTestHelper sharedHelper].testExpectation = saveExpectation;

    xmlrpc = @"http://blog2.com/xmlrpc.php";
    url = @"blog2.com";
    blog = [accountService findBlogWithXmlrpc:xmlrpc inAccount:account];
    if (!blog) {
        blog = [accountService createBlogWithAccount:account];
        blog.xmlrpc = xmlrpc;
        blog.url = url;
    }
    [[ContextManager sharedInstance] saveContext:account.managedObjectContext];
    [self waitForExpectationsWithTimeout:2.0 handler:^(NSError *error) {
        NSLog(@"Error: %@", error);
    }];

    [table reloadData];

    /*
     Signed In, Notifications enabled, 2 blogs

     - Username     jacksparrow
     - Manage Notifications
     - Sign Out
     */
    XCTAssertEqual(3, [table numberOfRowsInSection:0]);
    cell = [self tableView:table cellForRow:0];
    XCTAssertEqualObjects(@"Username", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:1];
    XCTAssertEqualObjects(@"Manage Notifications", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:2];
    XCTAssertEqualObjects(@"Sign Out", cell.accessibilityIdentifier);

    [[NSUserDefaults standardUserDefaults] removeObjectForKey:NotificationsDeviceToken];
    [table reloadData];

    /*
     Signed In, Notifications disabled, 2 blogs

     - Username     jacksparrow
     - Sign Out
     */
    XCTAssertEqual(2, [table numberOfRowsInSection:0]);
    cell = [self tableView:table cellForRow:0];
    XCTAssertEqualObjects(@"Username", cell.accessibilityIdentifier);
    cell = [self tableView:table cellForRow:1];
    XCTAssertEqualObjects(@"Sign Out", cell.accessibilityIdentifier);
}

- (SettingsViewController *)settingsViewController {
    SettingsViewController *controller =  [SettingsViewController new];
    // Force view load
    [controller view];
    return controller;
}

- (void)present:(UIViewController *)controller {
    [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:controller animated:NO completion:nil];
}

- (void)dismiss:(UIViewController *)controller {
    [[[[[UIApplication sharedApplication] delegate] window] rootViewController] dismissViewControllerAnimated:NO completion:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRow:(NSInteger)row {
    return [tableView.dataSource tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
}

@end
