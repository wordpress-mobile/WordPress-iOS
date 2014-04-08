#import <Foundation/Foundation.h>

@interface WPStatsMixpanelClientInstructionsForStat : NSObject

@property (nonatomic, strong) NSString *mixpanelEventName;
@property (nonatomic, strong) NSString *superPropertyToIncrement;
@property (nonatomic, strong) NSString *peoplePropertyToIncrement;
@property (nonatomic, strong) NSString *propertyToIncrement;
@property (nonatomic, assign) WPStat stat;
@property (nonatomic, assign) WPStat statToAttachProperty;

+ (instancetype)initWithMixpanelEventName:(NSString *)eventName;
+ (instancetype)initWithPropertyIncrementor:(NSString *)property forStat:(WPStat)stat;
- (void)setSuperPropertyAndPeoplePropertyToIncrement:(NSString *)propertyName;

@end
