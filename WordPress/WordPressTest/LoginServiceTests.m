#import <Specta/Specta.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>
#import <OCMock/OCMock.h>
#import "LoginService.h"
#import "LoginFields.h"
#import "WordPressComOAuthClientService.h"
#import "WordPressXMLRPCApiService.h"

SpecBegin(LoginService)

__block LoginService *loginService;
__block id mockOAuthService;
__block id mockXMLRPCApiService;
__block id mockLoginServiceDelegate;
__block LoginFields *loginFields;

beforeEach(^{
    mockOAuthService = [OCMockObject niceMockForProtocol:@protocol(WordPressComOAuthClientService)];
    mockXMLRPCApiService = [OCMockObject niceMockForProtocol:@protocol(WordPressXMLRPCApiService)];
    mockLoginServiceDelegate = [OCMockObject  niceMockForProtocol:@protocol(LoginServiceDelegate)];
    
    loginService = [LoginService new];
    loginService.wordpressComOAuthClientService = mockOAuthService;
    loginService.wordpressXMLRPCApiService = mockXMLRPCApiService;
    loginService.delegate = mockLoginServiceDelegate;
    
    loginFields = [LoginFields loginFieldsWithUsername:@"username" password:@"password" siteUrl:@"www.mysite.com" multifactorCode:@"123456" userIsDotCom:YES shouldDisplayMultiFactor:NO];
});

describe(@"signInWithLoginFields", ^{
    
    context(@"for a .com user", ^{
        
        beforeEach(^{
            loginFields.userIsDotCom = YES;
        });
        
        it(@"should display a message about 'Connecting to WordPress.com'", ^{
            [[mockLoginServiceDelegate expect] displayLoginMessage:NSLocalizedString(@"Connecting to WordPress.com", nil)];
            
            [loginService signInWithLoginFields:loginFields];
            
            [mockLoginServiceDelegate verify];
        });
        
        it(@"should authenticate the user's credentials", ^{
            [[mockOAuthService expect] authenticateWithUsername:loginFields.username password:loginFields.password multifactorCode:loginFields.multifactorCode success:OCMOCK_ANY needsMultiFactor:OCMOCK_ANY failure:OCMOCK_ANY];
            
            [loginService signInWithLoginFields:loginFields];
            
            [mockOAuthService verify];
        });
        
        it(@"should call LoginServiceDelegate's finishedLoginWithUsername:authToken:shouldDisplayMultifactor: when authentication was successful", ^{
            // Intercept success callback and execute it when appropriate
            NSString *authToken = @"auth-token";
            [OCMStub([mockOAuthService authenticateWithUsername:loginFields.username password:loginFields.password multifactorCode:loginFields.multifactorCode success:OCMOCK_ANY needsMultiFactor:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                void (^ __unsafe_unretained successStub)(NSString *);
                [invocation getArgument:&successStub atIndex:5];
                
                successStub(authToken);
            }];
            [[mockLoginServiceDelegate expect] finishedLoginWithUsername:loginFields.username authToken:authToken shouldDisplayMultifactor:loginFields.shouldDisplayMultifactor];
            
            [loginService signInWithLoginFields:loginFields];
            
            [mockLoginServiceDelegate verify];
        });
        
        it(@"should call LoginServceDelegate's needsMultifactorCode when authentication requires it", ^{
            // Intercept success callback and execute it when appropriate
            [OCMStub([mockOAuthService authenticateWithUsername:loginFields.username password:loginFields.password multifactorCode:loginFields.multifactorCode success:OCMOCK_ANY needsMultiFactor:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                void (^ __unsafe_unretained needsMultifactorStub)(void);
                [invocation getArgument:&needsMultifactorStub atIndex:6];
                
                needsMultifactorStub();
            }];
            [[mockLoginServiceDelegate expect] needsMultifactorCode];
            
            [loginService signInWithLoginFields:loginFields];
            
            [mockLoginServiceDelegate verify];
        });
        
        it(@"should call LoginServiceDelegate's displayRemoteError when there has been an error", ^{
            NSError *error = [NSError errorWithDomain:@"org.wordpress" code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"You have failed me yet again starscream" }];
            // Intercept success callback and execute it when appropriate
            [OCMStub([mockOAuthService authenticateWithUsername:loginFields.username password:loginFields.password multifactorCode:loginFields.multifactorCode success:OCMOCK_ANY needsMultiFactor:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                void (^ __unsafe_unretained failureStub)(NSError *);
                [invocation getArgument:&failureStub atIndex:7];
                
                failureStub(error);
            }];
            [[mockLoginServiceDelegate expect] displayRemoteError:error];
            
            [loginService signInWithLoginFields:loginFields];
            
            [mockLoginServiceDelegate verify];
        });
    });
    
    context(@"for a self hosted user", ^{
        
        beforeEach(^{
            loginFields.userIsDotCom = NO;
        });
        
        it(@"should display a message about 'Authenticating'", ^{
            [[mockLoginServiceDelegate expect] displayLoginMessage:NSLocalizedString(@"Authenticating", nil)];
            
            [loginService signInWithLoginFields:loginFields];
            
            [mockLoginServiceDelegate verify];
        });
        
        context(@"the guessing of the xmlrpc url for the site", ^{
            
            it(@"should occur", ^{
                [[mockXMLRPCApiService expect] guessXMLRPCURLForSite:loginFields.siteUrl success:OCMOCK_ANY failure:OCMOCK_ANY];
                
                [loginService signInWithLoginFields:loginFields];
                
                [mockXMLRPCApiService verify];
            });
            
            context(@"when successful", ^{
                
                __block NSURL *xmlrpc;
                
                beforeEach(^{
                    xmlrpc = [NSURL URLWithString:@"http://www.selfhosted.com/xmlrpc.php"];
                    // Intercept success callback and execute it when appropriate
                    [OCMStub([mockXMLRPCApiService guessXMLRPCURLForSite:loginFields.siteUrl success:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                        void (^ __unsafe_unretained successStub)(NSURL *);
                        [invocation getArgument:&successStub atIndex:3];
                        
                        successStub(xmlrpc);
                    }];
                });
                
                it(@"should result in attempting to retrieve the blog's options", ^{
                    [[mockXMLRPCApiService expect] getBlogOptionsWithEndpoint:xmlrpc username:loginFields.username password:loginFields.password success:OCMOCK_ANY failure:OCMOCK_ANY];
                    
                    [loginService signInWithLoginFields:loginFields];
                    
                    [mockXMLRPCApiService verify];
                });
                
                context(@"successfully retrieving the blog's options", ^{
                    
                    __block NSMutableDictionary *options;
                    
                    beforeEach(^{
                        options = [NSMutableDictionary new];
                        
                        // Intercept success callback and execute it when appropriate
                        [OCMStub([mockXMLRPCApiService getBlogOptionsWithEndpoint:xmlrpc username:loginFields.username password:loginFields.password success:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                            void (^ __unsafe_unretained successStub)(NSDictionary *);
                            [invocation getArgument:&successStub atIndex:5];
                            
                            successStub(options);
                        }];
                    });
                    
                    it(@"should indicate to the LoginServiceDelegate it's finished logging in with those credentials", ^{
                        [[mockLoginServiceDelegate expect] finishedLoginWithUsername:loginFields.username password:loginFields.password xmlrpc:[xmlrpc absoluteString] options:options];
                       
                        [loginService signInWithLoginFields:loginFields];
                        
                        [mockLoginServiceDelegate verify];
                    });
                    
                    it(@"should attempt to authenticate for WordPress.com when it detects the site is a WordPress.com site", ^{
                        options[@"wordpress.com"] = @YES;
                        [[mockOAuthService expect] authenticateWithUsername:loginFields.username password:loginFields.password multifactorCode:loginFields.multifactorCode success:OCMOCK_ANY needsMultiFactor:OCMOCK_ANY failure:OCMOCK_ANY];
                        
                        [loginService signInWithLoginFields:loginFields];
                       
                        [mockOAuthService verify];
                    });
                });
                
                context(@"failure of retrieving the blog's options", ^{
                    
                    __block NSError *error;
                    
                    beforeEach(^{
                        error = [NSError errorWithDomain:@"org.wordpress" code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"You have failed me yet again Starscream" }];
                        
                        // Intercept failure callback and execute it when appropriate
                        [OCMStub([mockXMLRPCApiService getBlogOptionsWithEndpoint:xmlrpc username:loginFields.username password:loginFields.password success:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                            void (^ __unsafe_unretained failureStub)(NSError *);
                            [invocation getArgument:&failureStub atIndex:6];
                            
                            failureStub(error);
                        }];
                    });
                    
                    it(@"should display an error", ^{
                        [[mockLoginServiceDelegate expect] displayRemoteError:error];
                        
                        [loginService signInWithLoginFields:loginFields];
                        
                        [mockLoginServiceDelegate verify];
                    });
                });
            });
            
            context(@"when not successful", ^{
                
                __block NSError *error;
                
                beforeEach(^{
                    error = [NSError errorWithDomain:@"org.wordpress" code:-1 userInfo:@{ NSLocalizedDescriptionKey : @"You have failed me yet again Starscream" }];
                    
                    // Intercept failure callback and execute it when appropriate
                    [OCMStub([mockXMLRPCApiService guessXMLRPCURLForSite:loginFields.siteUrl success:OCMOCK_ANY failure:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
                        void (^ __unsafe_unretained failureStub)(NSError *);
                        [invocation getArgument:&failureStub atIndex:4];
                        
                        failureStub(error);
                    }];
                });
                
                it(@"should display an error", ^{
                    [[mockLoginServiceDelegate expect] displayRemoteError:error];
                    
                    [loginService signInWithLoginFields:loginFields];
                    
                    [mockLoginServiceDelegate verify];
                });
            });
        });
    });
});

SpecEnd

