#import "WPStatsMixpanelClientInstructionsForStat.h"

@implementation WPStatsMixpanelClientInstructionsForStat

+ (instancetype)initWithMixpanelEventName:(NSString *)eventName
{
    WPStatsMixpanelClientInstructionsForStat *metadata = [[WPStatsMixpanelClientInstructionsForStat alloc] init];
    metadata.mixpanelEventName = eventName;
    return metadata;
}

- (void)setSuperPropertyAndPeoplePropertyToIncrement:(NSString *)propertyName
{
    NSParameterAssert(propertyName != nil);
    self.superPropertyToIncrement = propertyName;
    self.peoplePropertyToIncrement = propertyName;
}

@end
