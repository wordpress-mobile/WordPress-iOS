#import <Foundation/Foundation.h>

@interface WPStatsMixpanelClientInstructionsForStat : NSObject

@property (nonatomic, strong) NSString *mixpanelEventName;
@property (nonatomic, strong) NSString *superPropertyToIncrement;
@property (nonatomic, strong) NSString *superPropertyToFlag;
@property (nonatomic, strong) NSString *peoplePropertyToIncrement;
@property (nonatomic, strong) NSString *propertyToIncrement;
@property (nonatomic, assign) WPStat stat;
@property (nonatomic, assign) WPStat statToAttachProperty;
@property (nonatomic, assign) BOOL disableTrackingForSelfHosted;

+ (instancetype)initWithMixpanelEventName:(NSString *)eventName;
+ (instancetype)initWithPropertyIncrementor:(NSString *)property forStat:(WPStat)stat;
+ (instancetype)initWithSuperPropertyFlagger:(NSString *)property;
+ (instancetype)initWithSuperPropertyAndPeoplePropertyIncrementor:(NSString *)property;

- (void)setSuperPropertyAndPeoplePropertyToIncrement:(NSString *)property;

@end
