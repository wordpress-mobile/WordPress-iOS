#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "SFHFKeychainUtils.h"

@interface KeychainTest : XCTestCase
{
    NSString *serviceName;
}


@end

@implementation KeychainTest

- (void)setUp {
    [super setUp];
    serviceName = @"public-api.wordpress.com";
    
    NSError *error;
    [SFHFKeychainUtils deleteItemForUsername:@"username" andServiceName:serviceName error:&error];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testNoPassword {
    NSError *error = nil;
    NSString *authToken = [SFHFKeychainUtils getPasswordForUsername:@"username" andServiceName:@"public-api.wordpress.com" error:&error];
    
    XCTAssertNil(authToken);
}

- (void)testAddPassword {
    NSError *error = nil;
    BOOL result = [SFHFKeychainUtils storeUsername:@"username" andPassword:@"testpasswordreallylong" forServiceName:serviceName updateExisting:YES error:&error];
    
    XCTAssertNil(error);
    XCTAssertTrue(result);
    
    NSString *authToken = [SFHFKeychainUtils getPasswordForUsername:@"username" andServiceName:serviceName error:&error];
    
    XCTAssertNotNil(authToken);
}

- (void)testChangePassword {
    NSError *error = nil;
    [SFHFKeychainUtils storeUsername:@"otherusername" andPassword:@"otherusernamespassword" forServiceName:serviceName updateExisting:YES error:&error];
    [SFHFKeychainUtils storeUsername:@"username" andPassword:@"testpasswordreallylong" forServiceName:serviceName updateExisting:YES error:&error];
    BOOL result = [SFHFKeychainUtils storeUsername:@"username" andPassword:@"thisisadifferentpassword" forServiceName:serviceName updateExisting:YES error:&error];
    
    XCTAssertNil(error);
    XCTAssertTrue(result);

    // https://github.com/wordpress-mobile/WordPress-iOS/issues/2756
    NSString *otherUsernamesPassword = [SFHFKeychainUtils getPasswordForUsername:@"otherusername" andServiceName:serviceName error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(@"otherusernamespassword", otherUsernamesPassword);
    
    NSString *authToken = [SFHFKeychainUtils getPasswordForUsername:@"username" andServiceName:serviceName error:&error];
    
    XCTAssertNil(error);
    XCTAssertTrue([@"thisisadifferentpassword" isEqualToString:authToken]);
}

@end
