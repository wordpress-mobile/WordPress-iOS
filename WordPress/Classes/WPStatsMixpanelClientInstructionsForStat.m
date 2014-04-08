#import "WPStatsMixpanelClientInstructionsForStat.h"

@implementation WPStatsMixpanelClientInstructionsForStat

+ (instancetype)initWithMixpanelEventName:(NSString *)eventName
{
    WPStatsMixpanelClientInstructionsForStat *metadata = [[WPStatsMixpanelClientInstructionsForStat alloc] init];
    metadata.mixpanelEventName = eventName;
    return metadata;
}

+(instancetype)initWithPropertyIncrementor:(NSString *)property forStat:(WPStat)stat
{
    WPStatsMixpanelClientInstructionsForStat *metadata = [[WPStatsMixpanelClientInstructionsForStat alloc] init];
    metadata.statToAttachProperty = stat;
    metadata.propertyToIncrement = property;
    return metadata;
}

- (void)setSuperPropertyAndPeoplePropertyToIncrement:(NSString *)propertyName
{
    NSParameterAssert(propertyName != nil);
    self.superPropertyToIncrement = propertyName;
    self.peoplePropertyToIncrement = propertyName;
}

@end
