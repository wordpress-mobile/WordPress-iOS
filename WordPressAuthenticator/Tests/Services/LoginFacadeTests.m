#import "WordPressAuthenticatorTests-Swift.h"
#import "LoginFacade.h"
#import "WordPressXMLRPCAPIFacade.h"

@import OCMock;
@import XCTest;
@import WordPressShared;
@import WordPressAuthenticator;
@import WordPressKit;

@interface LoginFacadeTests: XCTestCase

@property (nonatomic) LoginFacade *loginFacade;
@property (nonatomic) id mockOAuthFacade;
@property (nonatomic) id mockXMLRPCAPIFacade;
@property (nonatomic) id mockLoginFacade;
@property (nonatomic) id mockLoginFacadeDelegate;
@property (nonatomic) LoginFields *loginFields;
@property (nonatomic) NSURL *xmlrpc;
@property (nonatomic) NSMutableDictionary *xmlrpcOptions;

@end

@implementation LoginFacadeTests

- (void)setUp {
    [super setUp];

    [WordpressAuthenticatorProvider initializeWordPressAuthenticator];

    self.mockOAuthFacade = [OCMockObject niceMockForProtocol:@protocol(WordPressComOAuthClientFacadeProtocol)];
    self.mockXMLRPCAPIFacade = [OCMockObject niceMockForProtocol:@protocol(WordPressXMLRPCAPIFacade)];
    self.mockLoginFacadeDelegate = [OCMockObject niceMockForProtocol:@protocol(LoginFacadeDelegate)];

    self.loginFacade = [LoginFacade new];
    self.loginFacade.wordpressComOAuthClientFacade = self.mockOAuthFacade;
    self.loginFacade.wordpressXMLRPCAPIFacade = self.mockXMLRPCAPIFacade;
    self.loginFacade.delegate = self.mockLoginFacadeDelegate;

    self.mockLoginFacade = OCMPartialMock(self.loginFacade);
    OCMStub([[self.mockLoginFacade ignoringNonObjectArgs] track:0]);
    OCMStub([[self.mockLoginFacade ignoringNonObjectArgs] track:0 error:[OCMArg any]]);

    self.loginFields = [LoginFields new];
    self.loginFields.username = @"username";
    self.loginFields.password = @"password";
    self.loginFields.siteAddress = @"www.mysite.com";
    self.loginFields.multifactorCode = @"123456";
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

// MARK: - WordPress.com

- (void)testDotComExampleShouldDisplayMessageAboutConnectinToWordPressCom {
    self.loginFields.userIsDotCom = YES;

    [[self.mockLoginFacadeDelegate expect] displayLoginMessage:NSLocalizedString(@"Connecting to WordPress.com", nil)];
    [self.loginFacade signInWithLoginFields:self.loginFields];
    [self.mockLoginFacadeDelegate verify];
}

- (void)testDotComShouldAuthenticateUserCredentials {
    self.loginFields.userIsDotCom = YES;

    [[self.mockOAuthFacade expect] authenticateWithUsername:self.loginFields.username password:self.loginFields.password multifactorCode:self.loginFields.multifactorCode success:OCMOCK_ANY needsMultifactor:OCMOCK_ANY failure:OCMOCK_ANY];

    [self.loginFacade signInWithLoginFields:self.loginFields];

    [self.mockOAuthFacade verify];
}

- (void)testDotComShouldCallLoginFacadeDelegateFinishedLoginWithUsername {
    self.loginFields.userIsDotCom = YES;

    NSString *authToken = @"auth-token";
    [OCMStub([self.mockOAuthFacade authenticateWithUsername:self.loginFields.username password:self.loginFields.password multifactorCode:self.loginFields.multifactorCode success:OCMOCK_ANY needsMultifactor:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        void (^ __unsafe_unretained successStub)(NSString *);
        [invocation getArgument:&successStub atIndex:5];

        successStub(authToken);
    }];
    [[self.mockLoginFacadeDelegate expect] finishedLoginWithAuthToken:authToken requiredMultifactorCode:self.loginFields.requiredMultifactor];

    [self.loginFacade signInWithLoginFields:self.loginFields];

    [self.mockLoginFacadeDelegate verify];
}

- (void)testDotComShouldCallLoginFacadeNeedsMultifactorCodeWhenAuthentificationRequired {
    self.loginFields.userIsDotCom = YES;

    [OCMStub([self.mockOAuthFacade authenticateWithUsername:self.loginFields.username password:self.loginFields.password multifactorCode:self.loginFields.multifactorCode success:OCMOCK_ANY needsMultifactor:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        void (^ __unsafe_unretained needsMultifactorStub)(NSInteger, SocialLogin2FANonceInfo *);
        [invocation getArgument:&needsMultifactorStub atIndex:6];

        needsMultifactorStub(0, nil);
    }];
    [[self.mockLoginFacadeDelegate expect] needsMultifactorCode];

    [self.loginFacade signInWithLoginFields:self.loginFields];

    [self.mockLoginFacadeDelegate verify];
}

- (void)testDotComShouldCallLoginFacadeNeedsMultifactorCode {
    self.loginFields.userIsDotCom = YES;

    // Expected parameters
    NSInteger userID = 1234;
    SocialLogin2FANonceInfo * info = [SocialLogin2FANonceInfo new];

    // Intercept success callback and execute it when appropriate
    [OCMStub([self.mockOAuthFacade authenticateWithUsername:self.loginFields.username password:self.loginFields.password multifactorCode:self.loginFields.multifactorCode success:OCMOCK_ANY needsMultifactor:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        void (^ __unsafe_unretained needsMultifactorStub)(NSInteger, SocialLogin2FANonceInfo *);
        [invocation getArgument:&needsMultifactorStub atIndex:6];

        needsMultifactorStub(userID, info);
    }];
    [[self.mockLoginFacadeDelegate expect] needsMultifactorCodeForUserID:userID andNonceInfo:info];

    [self.loginFacade signInWithLoginFields:self.loginFields];

    [self.mockLoginFacadeDelegate verify];
}

- (void)testDotComShouldCallLoginFacadeDisplayRemoteError {
    self.loginFields.userIsDotCom = YES;

    NSError *error = [NSError errorWithDomain:@"org.wordpress" code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"Error" }];
    // Intercept success callback and execute it when appropriate
    [OCMStub([self.mockOAuthFacade authenticateWithUsername:self.loginFields.username password:self.loginFields.password multifactorCode:self.loginFields.multifactorCode success:OCMOCK_ANY needsMultifactor:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        void (^ __unsafe_unretained failureStub)(NSError *);
        [invocation getArgument:&failureStub atIndex:7];

        failureStub(error);
    }];
    [[self.mockLoginFacadeDelegate expect] displayRemoteError:error];

    [self.loginFacade signInWithLoginFields:self.loginFields];

    [self.mockLoginFacadeDelegate verify];
}

// MARK: - Self-Hosted

- (void)testSelfHostedShoulDisplayAuthentificatingMessage {
    self.loginFields.userIsDotCom = NO;

    [[self.mockLoginFacadeDelegate expect] displayLoginMessage:NSLocalizedString(@"Authenticating", nil)];

    [self.loginFacade signInWithLoginFields:self.loginFields];

    [self.mockLoginFacadeDelegate verify];
}

- (void)testSelfHostedShouldGuessingXMLRPCForSite {
    self.loginFields.userIsDotCom = NO;

    [[self.mockXMLRPCAPIFacade expect] guessXMLRPCURLForSite:self.loginFields.siteAddress success:OCMOCK_ANY failure:OCMOCK_ANY];

    [self.loginFacade signInWithLoginFields:self.loginFields];

    [self.mockXMLRPCAPIFacade verify];
}

- (void)testSelfHostedShouldRetrieveBlogOptions {
    [self mockXMLRPCFacade];

    [[self.mockXMLRPCAPIFacade expect] getBlogOptionsWithEndpoint:self.xmlrpc username:self.loginFields.username password:self.loginFields.password success:OCMOCK_ANY failure:OCMOCK_ANY];

    [self.loginFacade signInWithLoginFields:self.loginFields];

    [self.mockXMLRPCAPIFacade verify];
}

- (void)testSelfHostedShouldIndicateLoginFacadeDelegateAfterRetrievingBlogOptions {
    [self mockXMLRPCSuccessfulBlogOptions];

    [[self.mockLoginFacadeDelegate expect] finishedLoginWithUsername:self.loginFields.username password:self.loginFields.password xmlrpc:[self.xmlrpc absoluteString] options:self.xmlrpcOptions];

    [self.loginFacade signInWithLoginFields:self.loginFields];

    [self.mockLoginFacadeDelegate verify];
}

- (void)testSelfHostedShouldAttemptAuthentificateDotComAfterRetrievingBlogOptions {
    [self mockXMLRPCSuccessfulBlogOptions];

    self.xmlrpcOptions[@"wordpress.com"] = @YES;
    [[self.mockOAuthFacade expect] authenticateWithUsername:self.loginFields.username password:self.loginFields.password multifactorCode:self.loginFields.multifactorCode success:OCMOCK_ANY needsMultifactor:OCMOCK_ANY failure:OCMOCK_ANY];

    [self.loginFacade signInWithLoginFields:self.loginFields];

    [self.mockOAuthFacade verify];
}

- (void)testSelfHostedShouldDisplayErrorOnFailureRetrievingBlogOptions {
    [self mockXMLRPCFacade];

    NSError *error = [NSError errorWithDomain:@"org.wordpress" code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"Error" }];

    // Intercept failure callback and execute it when appropriate
    [OCMStub([self.mockXMLRPCAPIFacade getBlogOptionsWithEndpoint:self.xmlrpc username:self.loginFields.username password:self.loginFields.password success:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        void (^ __unsafe_unretained failureStub)(NSError *);
        [invocation getArgument:&failureStub atIndex:6];

        failureStub(error);
    }];

    [[self.mockLoginFacadeDelegate expect] displayRemoteError:error];

    [self.loginFacade signInWithLoginFields:self.loginFields];

    [self.mockLoginFacadeDelegate verify];
}

- (void)testSelfHostedShouldDisplayErrorOnGuessXMLRPC {
    self.loginFields.userIsDotCom = NO;

    NSError *error = [NSError errorWithDomain:@"org.wordpress" code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"Error" }];

    // Intercept failure callback and execute it when appropriate
    [OCMStub([self.mockXMLRPCAPIFacade guessXMLRPCURLForSite:self.loginFields.siteAddress success:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        void (^ __unsafe_unretained failureStub)(NSError *);
        [invocation getArgument:&failureStub atIndex:4];

        failureStub(error);
    }];

    [[self.mockLoginFacadeDelegate expect] displayRemoteError:error];

    [self.loginFacade signInWithLoginFields:self.loginFields];

    [self.mockLoginFacadeDelegate verify];
}

// MARK: - Mocks

- (void)mockXMLRPCFacade {
    self.loginFields.userIsDotCom = NO;

    self.xmlrpc = [NSURL URLWithString:@"http://www.selfhosted.com/xmlrpc.php"];
    // Intercept success callback and execute it when appropriate
    [OCMStub([self.mockXMLRPCAPIFacade guessXMLRPCURLForSite:self.loginFields.siteAddress success:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        void (^ __unsafe_unretained successStub)(NSURL *);
        [invocation getArgument:&successStub atIndex:3];

        successStub(self.xmlrpc);
    }];
}

- (void)mockXMLRPCSuccessfulBlogOptions {
    [self mockXMLRPCFacade];

    self.xmlrpcOptions = [NSMutableDictionary dictionaryWithDictionary:@{@"software_version":@{@"value":@"4.2"}}];

    // Intercept success callback and execute it when appropriate
    [OCMStub([self.mockXMLRPCAPIFacade getBlogOptionsWithEndpoint:self.xmlrpc username:self.loginFields.username password:self.loginFields.password success:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        void (^ __unsafe_unretained successStub)(NSDictionary *);
        [invocation getArgument:&successStub atIndex:5];

        successStub(self.xmlrpcOptions);
    }];
}

@end
