#import "WPAnalyticsTrackerMixpanelInstructionsForStat.h"

@interface WPAnalyticsTrackerMixpanelInstructionsForStat () {
    NSMutableArray *_superPropertiesToFlag;
}

@end

@implementation WPAnalyticsTrackerMixpanelInstructionsForStat

- (instancetype)init
{
    if (self = [super init]) {
        _disableTrackingForSelfHosted = NO;
        _superPropertiesToFlag = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addSuperPropertyToFlag:(NSString *)property
{
    if ([_superPropertiesToFlag containsObject:property])
        return;
    
    [_superPropertiesToFlag addObject:property];
}

+ (instancetype)mixpanelInstructionsForEventName:(NSString *)eventName
{
    WPAnalyticsTrackerMixpanelInstructionsForStat *instructions = [[[self class] alloc] init];
    instructions.mixpanelEventName = eventName;
    return instructions;
}

+ (instancetype)mixpanelInstructionsWithPropertyIncrementor:(NSString *)property forStat:(WPAnalyticsStat)stat
{
    WPAnalyticsTrackerMixpanelInstructionsForStat *instructions = [[[self class] alloc] init];
    instructions.statToAttachProperty = stat;
    instructions.propertyToIncrement = property;
    return instructions;
}

+ (instancetype)mixpanelInstructionsWithSuperPropertyFlagger:(NSString *)property
{
    WPAnalyticsTrackerMixpanelInstructionsForStat *instructions = [[[self class] alloc] init];
    [instructions addSuperPropertyToFlag:property];
    return instructions;
}

+ (instancetype)mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:(NSString *)property
{
    WPAnalyticsTrackerMixpanelInstructionsForStat *instructions = [[[self class] alloc] init];
    [instructions setSuperPropertyAndPeoplePropertyToIncrement:property];
    return instructions;
}

- (NSMutableArray *)superPropertiesToFlag
{
    return [_superPropertiesToFlag copy];
}

- (void)setSuperPropertyAndPeoplePropertyToIncrement:(NSString *)property
{
    NSParameterAssert(property != nil);
    [self addSuperPropertyToFlag:property];
    self.peoplePropertyToIncrement = property;
}

@end
