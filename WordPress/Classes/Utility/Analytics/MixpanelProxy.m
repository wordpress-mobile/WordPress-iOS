#import "MixpanelProxy.h"

#import <Mixpanel/Mixpanel.h>


@interface MixpanelProxy ()

@property (nonatomic, strong) NSLock *lock;

@end


@implementation MixpanelProxy

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lock = [NSLock new];
    }
    return self;
}

- (void)registerInstanceWithToken:(NSString *)token
{
    [Mixpanel sharedInstanceWithToken:token];
}

- (NSDictionary *)currentSuperProperties
{
    return [Mixpanel sharedInstance].currentSuperProperties;
}

- (void)incrementSuperProperty:(NSString *)property
{
    NSMutableDictionary *superProperties = [[NSMutableDictionary alloc] initWithDictionary:self.currentSuperProperties];
    NSUInteger propertyValue = [superProperties[property] integerValue];
    superProperties[property] = @(++propertyValue);
    [self registerSuperProperties:superProperties];
}

- (void)flagSuperProperty:(NSString *)property
{
    NSMutableDictionary *superProperties = [[NSMutableDictionary alloc] initWithDictionary:self.currentSuperProperties];
    superProperties[property] = @(YES);
    [self registerSuperProperties:superProperties];
}

- (void)setSuperProperty:(NSString *)property toValue:(id)value
{
    NSParameterAssert(property.length > 0);
    NSParameterAssert(value != nil);
    
    NSMutableDictionary *superProperties = [[NSMutableDictionary alloc] initWithDictionary:self.currentSuperProperties];
    superProperties[property] = value;
    [self registerSuperProperties:superProperties];
}

- (void)registerSuperProperties:(NSDictionary *)superProperties
{
    [[Mixpanel sharedInstance] registerSuperProperties:superProperties];
}

- (void)identify:(NSString *)username
{
    NSParameterAssert(username.length > 0);
    
    [[Mixpanel sharedInstance] identify:username];
}

- (void)setPeopleProperties:(NSDictionary *)peopleProperties
{
    [[Mixpanel sharedInstance].people set:peopleProperties];
}

- (void)incrementPeopleProperty:(NSString *)property
{
    NSParameterAssert(property.length > 0);
    
    [[Mixpanel sharedInstance].people increment:property by:@(1)];
}

- (void)aliasNewUser:(NSString *)username
{
    NSParameterAssert(username.length > 0);
    
    [[Mixpanel sharedInstance] createAlias:username forDistinctID:[Mixpanel sharedInstance].distinctId];
    [[Mixpanel sharedInstance] identify:[Mixpanel sharedInstance].distinctId];
}

- (void)track:(NSString *)eventName properties:(NSDictionary *)properties
{
    NSParameterAssert(eventName.length > 0);
    
    [[Mixpanel sharedInstance] track:eventName properties:properties];
}

@end
