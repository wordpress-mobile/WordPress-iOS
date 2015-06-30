#import "MixpanelProxy.h"

#import <Mixpanel/Mixpanel.h>


@interface MixpanelProxy ()

@property (nonatomic, strong) dispatch_queue_t superPropertiesQueue;

@end

@implementation MixpanelProxy

- (instancetype)init
{
    self = [super init];
    if (self) {
        _superPropertiesQueue = dispatch_queue_create("org.wordpress.analytics.mixpanelproxy", DISPATCH_QUEUE_SERIAL);
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

- (void)flagSuperProperty:(NSString *)property
{
    NSParameterAssert(property.length > 0);
    
    [self registerSuperProperties:@{ property : @(YES) }];
}

- (void)setSuperProperty:(NSString *)property toValue:(id)value
{
    NSParameterAssert(property.length > 0);
    NSParameterAssert(value != nil);
    
    [self registerSuperProperties:@{ property : value }];
}

- (void)incrementSuperProperty:(NSString *)property
{
    dispatch_async(self.superPropertiesQueue, ^{
        NSUInteger propertyValue = [self.currentSuperProperties[property] integerValue];
        [self registerSuperProperties:@{ property : @(++propertyValue) }];
    });
}

- (void)registerSuperProperties:(NSDictionary *)superProperties
{
    dispatch_async(self.superPropertiesQueue, ^{
        [[Mixpanel sharedInstance] registerSuperProperties:superProperties];
    });
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
