#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>


@interface PushNotificationsManagerTests : XCTestCase

@end

@implementation PushNotificationsManagerTests

- (void)testDeviceTokenAndDeviceIdentifierArePersistedAcrossSessions
{
    // Store
    PushNotificationsManager *manager = [PushNotificationsManager new];
    manager.deviceId = @"1234";
    manager.deviceToken = @"4567";
    
    // Verify persistance
    manager = [PushNotificationsManager new];
    XCTAssertEqualObjects(manager.deviceId, @"1234");
    XCTAssertEqualObjects(manager.deviceToken, @"4567");
    
    // Nuke
    manager.deviceId = nil;
    manager.deviceToken = nil;
    
    // Verify persistance
    manager = [PushNotificationsManager new];
    XCTAssert([manager.deviceId isEmpty]);
    XCTAssert([manager.deviceToken isEmpty]);
}

- (void)testRegisterForRemoteNotificationsCallsSharedApplicationRegisterForRemoteNotifications
{
    // Note:
    // PushNotifications registration methods don't crash the sim, anymore, as per iOS 9.
    // We'll override the check just for evil unit testing purposes.
    
    id mockApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMExpect([mockApplication registerForRemoteNotifications]);
    
    PushNotificationsManager *manager = [PushNotificationsManager new];
    id mockManager = OCMPartialMock(manager);
    [OCMStub([mockManager sharedApplication]) andReturn:mockApplication];
    
    [mockManager registerForRemoteNotifications];
    OCMVerify(mockApplication);
}

- (void)testHandleNotificationUpdatesApplicationBadgeNumber
{
    NSInteger badgeCount = 5;
    NSDictionary *userInfo = @{ @"aps" : @{ @"badge" : @(badgeCount) }};
    
    id mockApplication = OCMPartialMock([UIApplication sharedApplication]);
    OCMExpect([mockApplication setApplicationIconBadgeNumber:5]);
    
    PushNotificationsManager *manager = [PushNotificationsManager new];
    id mockManager = OCMPartialMock(manager);
    [OCMStub([mockManager sharedApplication]) andReturn:mockApplication];
    [OCMStub([mockManager applicationState]) andReturnValue:OCMOCK_VALUE(UIApplicationStateActive)];
    
    [mockManager handleNotification:userInfo completionHandler:nil];
    OCMVerify(mockManager);
}

- (void)testBadgeResetNotificationDoesntAttemptToHandleAnyNotificationKind
{
    NSDictionary *userInfo = @{ @"type" : @"badge-reset"};
    PushNotificationsManager *manager = [PushNotificationsManager new];
    id mockManager = OCMPartialMock(manager);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-result"
    [[mockManager reject] handleAuthenticationNotification:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[mockManager reject] handleSupportNotification:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[mockManager reject] handleInactiveNotification:OCMOCK_ANY completionHandler:OCMOCK_ANY];
    [[mockManager reject] handleBackgroundNotification:OCMOCK_ANY completionHandler:OCMOCK_ANY];
#pragma clang diagnostic pop
    
    [mockManager handleNotification:userInfo completionHandler:nil];
    OCMVerify(mockManager);
}

- (void)testZendeskNotificationIsProperlyHandled
{
    NSDictionary *userInfo = @{ @"type" : @"zendesk" };
    PushNotificationsManager *manager = [PushNotificationsManager new];
    id mockManager = OCMPartialMock(manager);
    
    XCTAssertTrue([mockManager handleSupportNotification:userInfo completionHandler:nil], @"Error handling Zendesk");
    XCTAssertFalse([mockManager handleAuthenticationNotification:userInfo completionHandler:nil], @"Error handling Zendesk");
    XCTAssertFalse([mockManager handleInactiveNotification:userInfo completionHandler:nil], @"Error handling Zendesk");
    XCTAssertFalse([mockManager handleBackgroundNotification:userInfo completionHandler:nil], @"Error handling Zendesk");
    
    OCMExpect([manager handleSupportNotification:userInfo completionHandler:nil]);
    [mockManager handleNotification:userInfo completionHandler:nil];
    OCMVerify(mockManager);
}

- (void)testAuthenticationNotificationIsProperlyHandled
{
    NSDictionary *userInfo = @{ @"type" : @"push_auth" };
    PushNotificationsManager *manager = [PushNotificationsManager new];
    id mockManager = OCMPartialMock(manager);
    
    XCTAssertTrue([mockManager handleAuthenticationNotification:userInfo completionHandler:nil], @"Error handling PushAuth");
    XCTAssertFalse([mockManager handleSupportNotification:userInfo completionHandler:nil], @"Error handling PushAuth");
    XCTAssertFalse([mockManager handleInactiveNotification:userInfo completionHandler:nil], @"Error handling PushAuth");
    XCTAssertFalse([mockManager handleBackgroundNotification:userInfo completionHandler:nil], @"Error handling PushAuth");
    
    OCMExpect([manager handleAuthenticationNotification:userInfo completionHandler:nil]);
    [mockManager handleNotification:userInfo completionHandler:nil];
    OCMVerify(mockManager);
}

- (void)testInactiveNotificationIsProperlyHandled
{
    NSDictionary *userInfo = @{ @"type" : @"note", @"note_id" : @(1234) };
    
    id mockApplication = OCMPartialMock([UIApplication sharedApplication]);
    [OCMStub([mockApplication applicationState]) andReturnValue:OCMOCK_VALUE(UIApplicationStateInactive)];
    
    PushNotificationsManager *manager = [PushNotificationsManager new];
    id mockManager = OCMPartialMock(manager);
    [OCMStub([mockManager sharedApplication]) andReturn:mockApplication];
    
    XCTAssert([mockManager applicationState] == UIApplicationStateInactive);
    XCTAssertTrue([mockManager handleInactiveNotification:userInfo completionHandler:nil], @"Error handling Note");
    XCTAssertFalse([mockManager handleAuthenticationNotification:userInfo completionHandler:nil], @"Error handling Note");
    XCTAssertFalse([mockManager handleSupportNotification:userInfo completionHandler:nil], @"Error handling Note");
    XCTAssertFalse([mockManager handleBackgroundNotification:userInfo completionHandler:nil], @"Error handling Note");
    
    OCMExpect([manager handleInactiveNotification:userInfo completionHandler:nil]);
    [mockManager handleNotification:userInfo completionHandler:nil];
    OCMVerify(mockManager);
}

- (void)testBackgroundNotificationIsProperlyHandled
{
    NSDictionary *userInfo = @{ @"type" : @"note", @"note_id" : @(1234) };
    
    id mockApplication = OCMPartialMock([UIApplication sharedApplication]);
    [OCMStub([mockApplication applicationState]) andReturnValue:OCMOCK_VALUE(UIApplicationStateBackground)];
    
    PushNotificationsManager *manager = [PushNotificationsManager new];
    id mockManager = OCMPartialMock(manager);
    [OCMStub([mockManager sharedApplication]) andReturn:mockApplication];
    
    XCTAssert([mockManager applicationState] == UIApplicationStateBackground);
    
    XCTAssertTrue([mockManager handleBackgroundNotification:userInfo completionHandler:nil], @"Error handling Note");
    XCTAssertFalse([mockManager handleInactiveNotification:userInfo completionHandler:nil], @"Error handling Note");
    XCTAssertFalse([mockManager handleAuthenticationNotification:userInfo completionHandler:nil], @"Error handling Note");
    XCTAssertFalse([mockManager handleSupportNotification:userInfo completionHandler:nil], @"Error handling Note");
    
    OCMExpect([manager handleBackgroundNotification:userInfo completionHandler:nil]);
    [mockManager handleNotification:userInfo completionHandler:nil];
    OCMVerify(mockManager);
}

@end
