#import <Foundation/Foundation.h>

/**
 *  A class acting as an intermediary for Mixpanel.
 */
@interface MixpanelProxy : NSObject

/**
 *  Sets up Mixpanel
 *
 *  @param token the API token for the Mixpanel project.
 */
- (void)registerInstanceWithToken:(NSString *)token;

/**
 *  The current super properties stored by Mixpanel
 */
- (NSDictionary *)currentSuperProperties;

/**
 *  Sets a particular super property to true
 *
 *  @param property the name of the property
 */
- (void)flagSuperProperty:(NSString *)property;

/**
 *  Sets a particular super property to a specific value
 *
 *  @param property the name of the property
 *  @param value    the value to store
 */
- (void)setSuperProperty:(NSString *)property toValue:(id)value;

/**
 *  Increments a partcular super property by value 1
 *
 *  @param property the name of the property
 */
- (void)incrementSuperProperty:(NSString *)property;

/**
 *  Combines a dictionary of passed in super properties with the ones currently stored.
 */
- (void)registerSuperProperties:(NSDictionary *)superProperties;

/**
 *  Identifies the particular user with the people analytics portion of Mixpanel.
 */
- (void)identify:(NSString *)username;

/**
 *  Combines a dictionary of passed in people properties with the ones currently stored.
 */
- (void)setPeopleProperties:(NSDictionary *)peopleProperties;

/**
 *  Increments a particular people property by value 1.
 *
 *  @param property the name of the property
 */
- (void)incrementPeopleProperty:(NSString *)property;

/**
 *  Aliases a new user to the anonymous id stored by Mixpanel. This method is called after a user logs in to make sure that the prior actions they took before they were logged in are propertly aggregated with their logged in account. Without this funnels tracking logins are useless.
 *
 *  @param username the WordPress.com username
 */
- (void)aliasNewUser:(NSString *)username;

/**
 *  Tracks an event with properties.
 *
 *  @param eventName  event name to be tracked
 *  @param properties properties to associated with the event
 */
- (void)track:(NSString *)eventName properties:(NSDictionary *)properties;

@end
