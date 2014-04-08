#import "WPStatsMixpanelClientInstructionsForStat.h"

@implementation WPStatsMixpanelClientInstructionsForStat

- (instancetype)init
{
    if (self = [super init]) {
        self.disableTrackingForSelfHosted = NO;
    }
    return self;
}

+ (instancetype)initWithMixpanelEventName:(NSString *)eventName
{
    WPStatsMixpanelClientInstructionsForStat *instructions = [[WPStatsMixpanelClientInstructionsForStat alloc] init];
    instructions.mixpanelEventName = eventName;
    return instructions;
}

+ (instancetype)initWithPropertyIncrementor:(NSString *)property forStat:(WPStat)stat
{
    WPStatsMixpanelClientInstructionsForStat *instructions = [[WPStatsMixpanelClientInstructionsForStat alloc] init];
    instructions.statToAttachProperty = stat;
    instructions.propertyToIncrement = property;
    return instructions;
}

+ (instancetype)initWithSuperPropertyFlagger:(NSString *)property
{
    WPStatsMixpanelClientInstructionsForStat *instructions = [[WPStatsMixpanelClientInstructionsForStat alloc] init];
    instructions.superPropertyToFlag = property;
    return instructions;
}

+ (instancetype)initWithSuperPropertyAndPeoplePropertyIncrementor:(NSString *)property
{
    WPStatsMixpanelClientInstructionsForStat *instructions = [[WPStatsMixpanelClientInstructionsForStat alloc] init];
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
