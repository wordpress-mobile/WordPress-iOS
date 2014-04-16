#import "WPStatsTrackerMixpanelInstructionsForStat.h"

@implementation WPStatsTrackerMixpanelInstructionsForStat

- (instancetype)init
{
    if (self = [super init]) {
        _disableTrackingForSelfHosted = NO;
    }
    return self;
}

+ (instancetype)mixpanelInstructionsForEventName:(NSString *)eventName
{
    WPStatsTrackerMixpanelInstructionsForStat *instructions = [[[self class] alloc] init];
    instructions.mixpanelEventName = eventName;
    return instructions;
}

+ (instancetype)mixpanelInstructionsWithPropertyIncrementor:(NSString *)property forStat:(WPAnalyticsStat)stat
{
    WPStatsTrackerMixpanelInstructionsForStat *instructions = [[[self class] alloc] init];
    instructions.statToAttachProperty = stat;
    instructions.propertyToIncrement = property;
    return instructions;
}

+ (instancetype)mixpanelInstructionsWithSuperPropertyFlagger:(NSString *)property
{
    WPStatsTrackerMixpanelInstructionsForStat *instructions = [[[self class] alloc] init];
    instructions.superPropertyToFlag = property;
    return instructions;
}

+ (instancetype)mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:(NSString *)property
{
    WPStatsTrackerMixpanelInstructionsForStat *instructions = [[[self class] alloc] init];
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
