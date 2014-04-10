#import "WPStatsMixpanelClientInstructionsForStat.h"

@implementation WPStatsMixpanelClientInstructionsForStat

- (instancetype)init
{
    if (self = [super init]) {
        _disableTrackingForSelfHosted = NO;
    }
    return self;
}

+ (instancetype)mixpanelInstructionsForEventName:(NSString *)eventName
{
    WPStatsMixpanelClientInstructionsForStat *instructions = [[[self class] alloc] init];
    instructions.mixpanelEventName = eventName;
    return instructions;
}

+ (instancetype)mixpanelInstructionsWithPropertyIncrementor:(NSString *)property forStat:(WPStat)stat
{
    WPStatsMixpanelClientInstructionsForStat *instructions = [[[self class] alloc] init];
    instructions.statToAttachProperty = stat;
    instructions.propertyToIncrement = property;
    return instructions;
}

+ (instancetype)mixpanelInstructionsWithSuperPropertyFlagger:(NSString *)property
{
    WPStatsMixpanelClientInstructionsForStat *instructions = [[[self class] alloc] init];
    instructions.superPropertyToFlag = property;
    return instructions;
}

+ (instancetype)mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:(NSString *)property
{
    WPStatsMixpanelClientInstructionsForStat *instructions = [[[self class] alloc] init];
    [instructions setSuperPropertyAndPeoplePropertyToIncrement:property];
    return instructions;
}

- (void)setSuperPropertyAndPeoplePropertyToIncrement:(NSString *)property
{
    NSParameterAssert(property != nil);
    self.superPropertyToIncrement = property;
    self.peoplePropertyToIncrement = property;
}

@end
