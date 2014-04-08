#import "WPStatsMixpanelClientInstructionsForStat.h"

@implementation WPStatsMixpanelClientInstructionsForStat

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

- (void)setSuperPropertyAndPeoplePropertyToIncrement:(NSString *)propertyName
{
    NSParameterAssert(propertyName != nil);
    self.superPropertyToIncrement = propertyName;
    self.peoplePropertyToIncrement = propertyName;
}

@end
