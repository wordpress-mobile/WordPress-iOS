#import <Foundation/Foundation.h>

@interface MixpanelProxy : NSObject

- (void)registerInstanceWithToken:(NSString *)token;
- (NSDictionary *)currentSuperProperties;
- (void)incrementSuperProperty:(NSString *)property;
- (void)flagSuperProperty:(NSString *)property;
- (void)setSuperProperty:(NSString *)property toValue:(id)value;
- (void)registerSuperProperties:(NSDictionary *)superProperties;
- (void)identify:(NSString *)username;
- (void)setPeopleProperties:(NSDictionary *)peopleProperties;
- (void)incrementPeopleProperty:(NSString *)property;
- (void)aliasNewUser:(NSString *)username;
- (void)track:(NSString *)eventName properties:(NSDictionary *)properties;

@end
