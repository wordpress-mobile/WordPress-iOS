#import <Specta/Specta.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>
#import <OCMock/OCMock.h>
#import "LoginFacade.h"
#import "WordPressComOAuthClientFacade.h"
#import "WordPressXMLRPCAPIFacade.h"
#import <WordPressAuthenticator/WordPressAuthenticator-Swift.h>


SpecBegin(LoginFacade)

__block LoginFacade *loginFacade;
__block id mockOAuthFacade;
__block id mockXMLRPCAPIFacade;
__block id mockLoginFacade;
__block id mockLoginFacadeDelegate;
__block LoginFields *loginFields;

beforeEach(^{
    mockOAuthFacade = [OCMockObject niceMockForProtocol:@protocol(WordPressComOAuthClientFacade)];
    mockXMLRPCAPIFacade = [OCMockObject niceMockForProtocol:@protocol(WordPressXMLRPCAPIFacade)];
    mockLoginFacadeDelegate = [OCMockObject niceMockForProtocol:@protocol(LoginFacadeDelegate)];

    loginFacade = [LoginFacade new];
    loginFacade.wordpressComOAuthClientFacade = mockOAuthFacade;
    loginFacade.wordpressXMLRPCAPIFacade = mockXMLRPCAPIFacade;
    loginFacade.delegate = mockLoginFacadeDelegate;

    mockLoginFacade = OCMPartialMock(loginFacade);
    OCMStub([[mockLoginFacade ignoringNonObjectArgs] track:0]);
    OCMStub([[mockLoginFacade ignoringNonObjectArgs] track:0 error:[OCMArg any]]);

    loginFields = [LoginFields new];
    loginFields.username = @"username";
    loginFields.password = @"password";
    loginFields.siteAddress = @"www.mysite.com";
    loginFields.multifactorCode = @"123456";
});

describe(@"signInWithLoginFields", ^{
    
    context(@"for a .com user", ^{
        
        beforeEach(^{
            loginFields.meta.userIsDotCom = YES;
        });
        
        it(@"should display a message about 'Connecting to WordPress.com'", ^{
            [[mockLoginFacadeDelegate expect] displayLoginMessage:NSLocalizedString(@"Connecting to WordPress.com", nil)];
            
            [loginFacade signInWithLoginFields:loginFields];
            
            [mockLoginFacadeDelegate verify];
        });
        
        it(@"should authenticate the user's credentials", ^{
            [[mockOAuthFacade expect] authenticateWithUsername:loginFields.username password:loginFields.password multifactorCode:loginFields.multifactorCode success:OCMOCK_ANY needsMultiFactor:OCMOCK_ANY failure:OCMOCK_ANY];
            
            [loginFacade signInWithLoginFields:loginFields];
            
            [mockOAuthFacade verify];
        });
        
        it(@"should call LoginFacadeDelegate's finishedLoginWithUsername:authToken:shouldDisplayMultifactor: when authentication was successful", ^{
            // Intercept success callback and execute it when appropriate
            NSString *authToken = @"auth-token";
            [OCMStub([mockOAuthFacade authenticateWithUsername:loginFields.username password:loginFields.password multifactorCode:loginFields.multifactorCode success:OCMOCK_ANY needsMultiFactor:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                void (^ __unsafe_unretained successStub)(NSString *);
                [invocation getArgument:&successStub atIndex:5];
                
                successStub(authToken);
            }];
            [[mockLoginFacadeDelegate expect] finishedLoginWithUsername:loginFields.username authToken:authToken requiredMultifactorCode:loginFields.meta.requiredMultifactor];
            
            [loginFacade signInWithLoginFields:loginFields];
            
            [mockLoginFacadeDelegate verify];
        });
        
        it(@"should call LoginServceDelegate's needsMultifactorCode when authentication requires it", ^{
            // Intercept success callback and execute it when appropriate
            [OCMStub([mockOAuthFacade authenticateWithUsername:loginFields.username password:loginFields.password multifactorCode:loginFields.multifactorCode success:OCMOCK_ANY needsMultiFactor:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                void (^ __unsafe_unretained needsMultifactorStub)(void);
                [invocation getArgument:&needsMultifactorStub atIndex:6];
                
                needsMultifactorStub();
            }];
            [[mockLoginFacadeDelegate expect] needsMultifactorCode];
            
            [loginFacade signInWithLoginFields:loginFields];
            
            [mockLoginFacadeDelegate verify];
        });
        
        it(@"should call LoginFacadeDelegate's displayRemoteError when there has been an error", ^{
            NSError *error = [NSError errorWithDomain:@"org.wordpress" code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"Error" }];
            // Intercept success callback and execute it when appropriate
            [OCMStub([mockOAuthFacade authenticateWithUsername:loginFields.username password:loginFields.password multifactorCode:loginFields.multifactorCode success:OCMOCK_ANY needsMultiFactor:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                void (^ __unsafe_unretained failureStub)(NSError *);
                [invocation getArgument:&failureStub atIndex:7];
                
                failureStub(error);
            }];
            [[mockLoginFacadeDelegate expect] displayRemoteError:error];
            
            [loginFacade signInWithLoginFields:loginFields];
            
            [mockLoginFacadeDelegate verify];
        });
    });
    
    context(@"for a self hosted user", ^{
        
        beforeEach(^{
            loginFields.meta.userIsDotCom = NO;
        });
        
        it(@"should display a message about 'Authenticating'", ^{
            [[mockLoginFacadeDelegate expect] displayLoginMessage:NSLocalizedString(@"Authenticating", nil)];
            
            [loginFacade signInWithLoginFields:loginFields];
            
            [mockLoginFacadeDelegate verify];
        });
        
        context(@"the guessing of the xmlrpc url for the site", ^{
            
            it(@"should occur", ^{
                [[mockXMLRPCAPIFacade expect] guessXMLRPCURLForSite:loginFields.siteAddress success:OCMOCK_ANY failure:OCMOCK_ANY];
                
                [loginFacade signInWithLoginFields:loginFields];
                
                [mockXMLRPCAPIFacade verify];
            });
            
            context(@"when successful", ^{
                
                __block NSURL *xmlrpc;
                
                beforeEach(^{
                    xmlrpc = [NSURL URLWithString:@"http://www.selfhosted.com/xmlrpc.php"];
                    // Intercept success callback and execute it when appropriate
                    [OCMStub([mockXMLRPCAPIFacade guessXMLRPCURLForSite:loginFields.siteAddress success:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                        void (^ __unsafe_unretained successStub)(NSURL *);
                        [invocation getArgument:&successStub atIndex:3];
                        
                        successStub(xmlrpc);
                    }];
                });
                
                it(@"should result in attempting to retrieve the blog's options", ^{
                    [[mockXMLRPCAPIFacade expect] getBlogOptionsWithEndpoint:xmlrpc username:loginFields.username password:loginFields.password success:OCMOCK_ANY failure:OCMOCK_ANY];
                    
                    [loginFacade signInWithLoginFields:loginFields];
                    
                    [mockXMLRPCAPIFacade verify];
                });
                
                context(@"successfully retrieving the blog's options", ^{
                    
                    __block NSMutableDictionary *options;
                    
                    beforeEach(^{
                        options = [NSMutableDictionary dictionaryWithDictionary:@{@"software_version":@{@"value":@"4.2"}}];
                        
                        // Intercept success callback and execute it when appropriate
                        [OCMStub([mockXMLRPCAPIFacade getBlogOptionsWithEndpoint:xmlrpc username:loginFields.username password:loginFields.password success:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                            void (^ __unsafe_unretained successStub)(NSDictionary *);
                            [invocation getArgument:&successStub atIndex:5];
                            
                            successStub(options);
                        }];
                    });
                    
                    it(@"should indicate to the LoginFacadeDelegate it's finished logging in with those credentials", ^{
                        [[mockLoginFacadeDelegate expect] finishedLoginWithUsername:loginFields.username password:loginFields.password xmlrpc:[xmlrpc absoluteString] options:options];
                       
                        [loginFacade signInWithLoginFields:loginFields];
                        
                        [mockLoginFacadeDelegate verify];
                    });
                    
                    it(@"should attempt to authenticate for WordPress.com when it detects the site is a WordPress.com site", ^{
                        options[@"wordpress.com"] = @YES;
                        [[mockOAuthFacade expect] authenticateWithUsername:loginFields.username password:loginFields.password multifactorCode:loginFields.multifactorCode success:OCMOCK_ANY needsMultiFactor:OCMOCK_ANY failure:OCMOCK_ANY];
                        
                        [loginFacade signInWithLoginFields:loginFields];
                       
                        [mockOAuthFacade verify];
                    });
                });
                
                context(@"failure of retrieving the blog's options", ^{
                    
                    __block NSError *error;
                    
                    beforeEach(^{
                        error = [NSError errorWithDomain:@"org.wordpress" code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"Error" }];
                        
                        // Intercept failure callback and execute it when appropriate
                        [OCMStub([mockXMLRPCAPIFacade getBlogOptionsWithEndpoint:xmlrpc username:loginFields.username password:loginFields.password success:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                            void (^ __unsafe_unretained failureStub)(NSError *);
                            [invocation getArgument:&failureStub atIndex:6];
                            
                            failureStub(error);
                        }];
                    });
                    
                    it(@"should display an error", ^{
                        [[mockLoginFacadeDelegate expect] displayRemoteError:error];
                        
                        [loginFacade signInWithLoginFields:loginFields];
                        
                        [mockLoginFacadeDelegate verify];
                    });
                });
            });
            
            context(@"when not successful", ^{
                
                __block NSError *error;
                
                beforeEach(^{
                    error = [NSError errorWithDomain:@"org.wordpress" code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"Error" }];
                    
                    // Intercept failure callback and execute it when appropriate
                    [OCMStub([mockXMLRPCAPIFacade guessXMLRPCURLForSite:loginFields.siteAddress success:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                        void (^ __unsafe_unretained failureStub)(NSError *);
                        [invocation getArgument:&failureStub atIndex:4];
                        
                        failureStub(error);
                    }];
                });
                
                it(@"should display an error", ^{
                    [[mockLoginFacadeDelegate expect] displayRemoteError:error];
                    
                    [loginFacade signInWithLoginFields:loginFields];
                    
                    [mockLoginFacadeDelegate verify];
                });
            });
        });
    });
});

SpecEnd

