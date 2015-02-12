#import <Foundation/Foundation.h>

@interface WPAnalyticsTrackerMixpanelInstructionsForStat : NSObject

@property (nonatomic, strong) NSString *mixpanelEventName;
@property (nonatomic, strong) NSString *superPropertyToIncrement;
@property (nonatomic, strong, readonly) NSMutableArray *superPropertiesToFlag;
@property (nonatomic, strong, readonly) NSDictionary *peoplePropertiesToAssign;
@property (nonatomic, strong, readonly) NSDictionary *superPropertiesToAssign;
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
- (void)addSuperPropertyToFlag:(NSString *)property;
- (void)setCurrentDateForPeopleProperty:(NSString *)property;
- (void)setPeopleProperty:(NSString *)property toValue:(id)value;
- (void)setSuperProperty:(NSString *)property toValue:(id)value;

@end
