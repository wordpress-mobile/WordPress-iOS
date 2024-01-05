#import <XCTest/XCTest.h>
#import "WordPressTest-Swift.h"

@interface WPAccount_ObjCLookupTests : XCTestCase

@property(strong, nonatomic) id<CoreDataStack> contextManager;

@end

@implementation WPAccount_ObjCLookupTests

- (void) setUp {
    [super setUp];
    _contextManager = [self coreDataStackForTesting];
}

- (void) testLookupDefaultWordPressComAccountReturnsNilWhenNoAccountIsSet {
    [[[AccountBuilder alloc] initWithContext:self.contextManager.mainContext] build];
    XCTAssertNil([WPAccount lookupDefaultWordPressComAccountInContext: self.contextManager.mainContext]);
}

- (void) testLookupDefaultWordPressComAccountReturnsAccount {
    WPAccount *account = [[[AccountBuilder alloc] initWithContext:self.contextManager.mainContext] build];
    [UserSettings setDefaultDotComUUID: account.uuid];
    XCTAssertEqual([WPAccount lookupDefaultWordPressComAccountInContext:self.contextManager.mainContext].uuid, account.uuid);
}

- (void) testLookupNumberOfAccountsReturnsZeroByDefault {
    XCTAssertEqual([WPAccount lookupNumberOfAccountsInContext:self.contextManager.mainContext], 0);
}

- (void) testLookupNumberOfAccountsReturnsCorrectValue {
    [[[AccountBuilder alloc] initWithContext:self.contextManager.mainContext] build];
    [[[AccountBuilder alloc] initWithContext:self.contextManager.mainContext] build];
    [[[AccountBuilder alloc] initWithContext:self.contextManager.mainContext] build];

    XCTAssertEqual([WPAccount lookupNumberOfAccountsInContext: self.contextManager.mainContext], 3);
}

- (void) testLookupAccountByUsernameReturnsNilIfNotFound {
    [[[AccountBuilder alloc] initWithContext:self.contextManager.mainContext] build];
    XCTAssertNil([WPAccount lookupWithUsername:@"" context:self.contextManager.mainContext]);
}

- (void) testLookupAccountByUsernameReturnsAccountForUsername {
    NSString *username = [[NSUUID new] UUIDString];
    [[[[AccountBuilder alloc] initWithContext:self.contextManager.mainContext] withUsername:username] build];
    XCTAssertEqual([WPAccount lookupWithUsername:username context:self.contextManager.mainContext].username, username);
}

- (void) testLookupAccountByUsernameReturnsAccountForEmailAddress {
    NSString *email = [[NSUUID new] UUIDString];
    [[[[AccountBuilder alloc] initWithContext:self.contextManager.mainContext] withEmail:email] build];
    XCTAssertEqual([WPAccount lookupWithUsername:email context:self.contextManager.mainContext].email, email);
}

@end
