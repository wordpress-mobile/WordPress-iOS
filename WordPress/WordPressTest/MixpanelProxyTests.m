#import <Specta/Specta.h>
#define EXP_SHORTHAND
#import <Expecta/Expecta.h>
#import <OCMock/OCMock.h>
#import <Mixpanel/Mixpanel.h>
#import "MixpanelProxy.h"

SpecBegin(MixpanelProxy)

__block id mixpanelMock;
__block id mixpanelPeopleMock;
__block MixpanelProxy *mixpanelProxy;
__block NSMutableDictionary *superProperties;

beforeEach(^{
    mixpanelMock = OCMClassMock([Mixpanel class]);
    mixpanelPeopleMock = OCMClassMock([MixpanelPeople class]);
    [OCMStub(ClassMethod([mixpanelMock sharedInstance])) andReturn:mixpanelMock];
    [OCMStub([mixpanelMock people]) andReturn:mixpanelPeopleMock];
    
    superProperties = [NSMutableDictionary new];
    [OCMStub([mixpanelMock currentSuperProperties]) andReturn:superProperties];
    
    mixpanelProxy = [MixpanelProxy new];
});

describe(@"registerInstanceWithToken:", ^{
    
    it(@"should register the token with Mixpanel", ^{
        NSString *token = @"mixpanel-token";
        OCMExpect(ClassMethod([mixpanelMock sharedInstanceWithToken:token]));
        
        [mixpanelProxy registerInstanceWithToken:token];
        
        OCMVerifyAll(mixpanelMock);
    });
});

describe(@"currentSuperProperties", ^{
    
    it(@"returns the currentSuperProperties", ^{
        superProperties[@"property"] = @YES;
        
        NSDictionary *currentSuperProperties = mixpanelProxy.currentSuperProperties;
        
        expect([currentSuperProperties[@"property"] boolValue]).to.beTruthy();
    });
});

// Create helper to intercept super property dictionary
__block NSDictionary *superPropertiesRegistering;
void (^interceptSuperPropertyDictionary)() = ^{
    [OCMStub([mixpanelMock registerSuperProperties:OCMOCK_ANY]) andDo:^(NSInvocation *invocation) {
        __unsafe_unretained NSDictionary *props;
        [invocation getArgument:&props atIndex:2];
        
        superPropertiesRegistering = props;
    }];
};

describe(@"incrementSuperProperty:", ^{
    
    NSString *property = @"property";
    it(@"should increment the super property", ^{
        superProperties[property] = @10;
        interceptSuperPropertyDictionary();
        
        [mixpanelProxy incrementSuperProperty:property];
        
        setAsyncSpecTimeout(1.0);
        
        // Sleeping briefly to give the MixpanelProxy time to kick off the async tasks that eventually register the super properties
        [NSThread sleepForTimeInterval:0.1];
        expect(superPropertiesRegistering[property]).to.equal(@11);
    });
});

describe(@"flagSuperProperty:", ^{
    NSString *property = @"property";
    it(@"should flag the super property", ^{
        interceptSuperPropertyDictionary();
        
        [mixpanelProxy flagSuperProperty:property];
        
        // Sleeping briefly to give the MixpanelProxy time to kick off the async tasks that eventually register the super properties
        [NSThread sleepForTimeInterval:0.1];
        expect(superPropertiesRegistering[property]).to.equal(@YES);
    });
});

describe(@"setSuperProperty:toValue:", ^{
    
    NSString *property = @"property";
    it(@"should set the super property", ^{
        interceptSuperPropertyDictionary();
        
        NSString *value = @"value";
        [mixpanelProxy setSuperProperty:property toValue:value];
        
        // Sleeping briefly to give the MixpanelProxy time to kick off the async tasks that eventually register the super properties
        [NSThread sleepForTimeInterval:0.1];
        expect(superPropertiesRegistering[property]).to.equal(value);
    });
});

describe(@"registerSuperProperties:", ^{
    
    it(@"register's the super properties passed in", ^{
        NSDictionary *properties = @{ @"hello" : @"world"};
        [[mixpanelMock expect] registerSuperProperties:properties];
        
        [mixpanelProxy registerSuperProperties:properties];
        
        // Sleeping briefly to give the MixpanelProxy time to kick off the async tasks that eventually register the super properties
        [NSThread sleepForTimeInterval:0.1];
        [mixpanelMock verify];
    });
});

describe(@"identify:", ^{
    
    it(@"identifies the user", ^{
        NSString *username = @"username";
        [[mixpanelMock expect] identify:username];
        
        [mixpanelProxy identify:username];
        
        [mixpanelMock verify];
    });
});

describe(@"setPeopleProperties:", ^{
    
    it(@"should set the people properties", ^{
        NSDictionary *properties = @{ @"hello" : @"world"};
        [[mixpanelPeopleMock expect] set:properties];
        
        [mixpanelProxy setPeopleProperties:properties];
        
        [mixpanelPeopleMock verify];
    });
});

describe(@"incrementPeopleProperty:", ^{
    
    it(@"should increment a people property", ^{
        NSString *property = @"random-property";
        [[mixpanelPeopleMock expect] increment:property by:@(1)];
        
        [mixpanelProxy incrementPeopleProperty:property];
        
        [mixpanelPeopleMock verify];
    });
});

describe(@"aliasNewUser:", ^{
    
    it(@"should correctly alias the new user", ^{
        NSString *username = @"username";
        NSString *distinctId = @"distinctId";
        [OCMStub([mixpanelMock distinctId]) andReturn:distinctId];
        [[mixpanelMock expect] createAlias:username forDistinctID:distinctId];
        [[mixpanelMock expect] identify:distinctId];
        
        [mixpanelProxy aliasNewUser:username];
        
        [mixpanelMock verify];
    });
});

describe(@"track:properties:", ^{
    
    NSString *eventName = @"eventName";
    NSDictionary *properties = @{ @"hello" : @"world" };
    
    it(@"should track an event with no properties", ^{
        [[mixpanelMock expect] track:eventName properties:nil];
        
        [mixpanelProxy track:eventName properties:nil];
        
        [mixpanelMock verify];
    });
    
    it(@"should track an event with properties", ^{
        [[mixpanelMock expect] track:eventName properties:properties];
        
        [mixpanelProxy track:eventName properties:properties];
        
        [mixpanelMock verify];
    });
});

SpecEnd
