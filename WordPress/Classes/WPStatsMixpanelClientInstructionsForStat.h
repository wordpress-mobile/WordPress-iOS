#import <Foundation/Foundation.h>

@interface WPStatsMixpanelClientInstructionsForStat : NSObject

@property (nonatomic, strong) NSString *mixpanelEventName;
@property (nonatomic, strong) NSString *superPropertyToIncrement;
@property (nonatomic, strong) NSString *peoplePropertyToIncrement;

+ (instancetype)initWithMixpanelEventName:(NSString *)eventName;
- (void)setSuperPropertyAndPeoplePropertyToIncrement:(NSString *)propertyName;

@end
