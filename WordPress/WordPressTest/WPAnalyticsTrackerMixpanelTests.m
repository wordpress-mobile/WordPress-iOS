#import <Specta/Specta.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>
#import <OCMock/OCMock.h>
#import <Mixpanel/Mixpanel.h>
#import "MixpanelProxy.h"
#import "WPAnalyticsTrackerMixpanel.h"
#import "TestContextManager.h"
#import "AccountService.h"
#import "BlogService.h"
#import "WPAccount.h"
#import "Blog.h"

SpecBegin(WPAnalyticsTrackerMixpanel)

__block WPAnalyticsTrackerMixpanel *mixpanelTracker;
__block id mixpanelProxyMock;
__block TestContextManager *testContextManager;
__block AccountService *accountService;
__block BlogService *blogService;
__block WPAccount *account;

// Helper Methods
NSString *username = @"username";
void (^createDotComAccount)() = ^{
    account = [accountService createOrUpdateWordPressComAccountWithUsername:username authToken:@"authtoken"];
};

typedef void (^BlockWithDict)(NSDictionary *);
void (^interceptSuperProperties)(BlockWithDict) = ^(BlockWithDict callback){
    [OCMStub([mixpanelProxyMock registerSuperProperties:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        __unsafe_unretained NSDictionary *superProperties;
        [invocation getArgument:&superProperties atIndex:2];
        
        callback(superProperties);
    }];
};

void (^interceptPeopleProperties)(BlockWithDict) = ^(BlockWithDict callback){
    [OCMStub([mixpanelProxyMock setPeopleProperties:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        __unsafe_unretained NSDictionary *peopleProperties;
        [invocation getArgument:&peopleProperties atIndex:2];
        
        callback(peopleProperties);
        expect(peopleProperties[@"$username"]).to.equal(username);
        expect(peopleProperties[@"$first_name"]).to.equal(username);
    }];
};

__block Blog *blog;
void (^createBlog)() = ^{
    blog = (Blog *)[NSEntityDescription insertNewObjectForEntityForName:@"Blog" inManagedObjectContext:testContextManager.mainContext];
    blog.xmlrpc = @"http://test.blog/xmlrpc.php";
    blog.url = @"http://test.blog/";
    blog.options = @{@"jetpack_version": @{
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
    blog.account = account;
    [testContextManager.mainContext save:nil];
};

beforeEach(^{
    testContextManager = [TestContextManager new];
    accountService = [[AccountService alloc] initWithManagedObjectContext:testContextManager.mainContext];
    blogService = [[BlogService alloc] initWithManagedObjectContext:testContextManager.mainContext];
    
    mixpanelProxyMock = [OCMockObject niceMockForClass:[MixpanelProxy class]];
    mixpanelTracker = [[WPAnalyticsTrackerMixpanel alloc] initWithManagedObjectContext:testContextManager.mainContext mixpanelProxy:mixpanelProxyMock];
});

describe(@"beginSession", ^{
    
    it(@"should register the instance token with Mixpanel", ^{
        [[mixpanelProxyMock expect] registerInstanceWithToken:OCMOCK_ANY];
        
        [mixpanelTracker beginSession];
        
        [mixpanelProxyMock verify];
    });
});

describe(@"refreshMetadata", ^{
    
    context(@"registering of superproperties", ^{
        
        context(@"dotcom_user", ^{
            
            it(@"should be YES when the user is a .com user", ^{
                interceptSuperProperties(^(NSDictionary *superProperties){
                    expect(superProperties[@"dotcom_user"]).to.equal(YES);
                });
                createDotComAccount();
                
                [mixpanelTracker refreshMetadata];
            });
            
            it(@"should be NO when the user is self hosted", ^{
                interceptSuperProperties(^(NSDictionary *superProperties){
                    expect(superProperties[@"dotcom_user"]).to.equal(NO);
                });
                account = [accountService createOrUpdateSelfHostedAccountWithXmlrpc:@"xmlrpc" username:username andPassword:@"password"];
                
                [mixpanelTracker refreshMetadata];
            });
            
            it(@"should be NO if there is no account", ^{
                interceptSuperProperties(^(NSDictionary *superProperties){
                    expect(superProperties[@"dotcom_user"]).to.equal(NO);
                });
                
                [mixpanelTracker refreshMetadata];
            });
        });
        
        context(@"number_of_blogs", ^{
            
            it(@"should be zero when there are no blogs", ^{
                interceptSuperProperties(^(NSDictionary *superProperties){
                    expect(superProperties[@"number_of_blogs"]).to.equal(0);
                });
                
                [mixpanelTracker refreshMetadata];
            });
            
            it(@"should be 1 when there is a blog", ^{
                createDotComAccount();
                interceptSuperProperties(^(NSDictionary *superProperties){
                    expect(superProperties[@"number_of_blogs"]).to.equal(1);
                });
                createBlog();
                
                [mixpanelTracker refreshMetadata];
            });
        });
        
        context(@"jetpack_user", ^{
            
            beforeEach(^{
                createDotComAccount();
                createBlog();
            });
            
            it(@"should be NO when the user isn't connected to Jetpack", ^{
                interceptSuperProperties(^(NSDictionary *superProperties){
                    expect(superProperties[@"jetpack_user"]).to.beFalsy();
                });
                
                [mixpanelTracker refreshMetadata];
            });
            
            it(@"should be YES when the user is connected to Jetpack", ^{
                blog.jetpackAccount = account;
                [account addJetpackBlogsObject:blog];
                [testContextManager.mainContext save:nil];
                
                interceptSuperProperties(^(NSDictionary *superProperties){
                    expect(superProperties[@"jetpack_user"]).to.beTruthy();
                });
                
                [mixpanelTracker refreshMetadata];
            });
        });
    });
    
    context(@"when an account with a username is available", ^{
        
        beforeEach(^{
            createDotComAccount();
        });
        
        it(@"should identify the username to Mixpanel", ^{
            [[mixpanelProxyMock expect] identify:@"username"];
            
            [mixpanelTracker refreshMetadata];
            
            [mixpanelProxyMock verify];
        });
        
        it(@"should track the username via the people properties", ^{
            interceptPeopleProperties(^(NSDictionary *peopleProperties){
                expect(peopleProperties[@"$username"]).to.equal(username);
                expect(peopleProperties[@"$first_name"]).to.equal(username);
            });
            
            [mixpanelTracker refreshMetadata];
        });
        
        it(@"should not track the email address if it's not available", ^{
            interceptPeopleProperties(^(NSDictionary *peopleProperties){
                expect(peopleProperties[@"$email"]).to.beNil();
            });
            
            [mixpanelTracker refreshMetadata];
        });
        
        it(@"should track the email address if it's available", ^{
            NSString *email = @"test@example.com";
            account.email = email;
            [[testContextManager mainContext] save:nil];
            
            interceptPeopleProperties(^(NSDictionary *peopleProperties){
                expect(peopleProperties[@"$email"]).to.equal(email);
            });
            
            [mixpanelTracker refreshMetadata];
        });
    });
});

it(@"should alias new users when the account is created", ^{
    createDotComAccount();
    [[mixpanelProxyMock expect] aliasNewUser:username];
    
    [mixpanelTracker track:WPAnalyticsStatCreatedAccount];
    
    [mixpanelProxyMock verify];
});

it(@"should increment the session_count when the application is opened", ^{
    [[[mixpanelProxyMock stub] andReturn:@{ @"session_count" : @(3) }] currentSuperProperties];
    interceptSuperProperties(^(NSDictionary *superProperties){
        expect([superProperties[@"session_count"] integerValue]).to.equal(4);
    });
    
    [mixpanelTracker track:WPAnalyticsStatApplicationOpened];
});

SpecEnd
