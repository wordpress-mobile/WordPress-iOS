#import <Foundation/Foundation.h>

@interface WPStatsTrackerMixpanelInstructionsForStat : NSObject

@property (nonatomic, strong) NSString *mixpanelEventName;
@property (nonatomic, strong) NSString *superPropertyToIncrement;
@property (nonatomic, strong) NSString *superPropertyToFlag;
@property (nonatomic, strong) NSString *peoplePropertyToIncrement;
@property (nonatomic, strong) NSString *propertyToIncrement;
@property (nonatomic, assign) WPAnalyticsStat stat;
@property (nonatomic, assign) WPAnalyticsStat statToAttachProperty;
@property (nonatomic, assign) BOOL disableTrackingForSelfHosted;

+ (instancetype)mixpanelInstructionsForEventName:(NSString *)eventName;
+ (instancetype)mixpanelInstructionsWithPropertyIncrementor:(NSString *)property forStat:(WPAnalyticsStat)stat;
+ (instancetype)mixpanelInstructionsWithSuperPropertyFlagger:(NSString *)property;
+ (instancetype)mixpanelInstructionsWithSuperPropertyAndPeoplePropertyIncrementor:(NSString *)property;

- (void)setSuperPropertyAndPeoplePropertyToIncrement:(NSString *)property;

@end
