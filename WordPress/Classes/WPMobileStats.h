#import <Foundation/Foundation.h>

@interface WPMobileStats : NSObject

+ (void)trackEventForSelfHostedAndWPCom:(NSString *)event;
+ (void)trackEventForSelfHostedAndWPCom:(NSString *)event properties:(NSDictionary *)properties;
+ (void)trackEventForSelfHostedAndWPComWithSavedProperties:(NSString *)event;
+ (void)trackEventForWPCom:(NSString *)event;
+ (void)trackEventForWPCom:(NSString *)event properties:(NSDictionary *)properties;
+ (void)trackEventForWPComWithSavedProperties:(NSString *)event;
+ (void)pingWPComStatsEndpoint:(NSString *)statName;

/*
    Mixpanel has both properties and super properties which should be used differently depending on the
    circumstance. A property in general can be attached to any event, so for example an event with
    the title "Opened from External Source" can have a property "external_source" which identifies the
    source of the event. Properties are useful to attach to events because they allow us to drill down
    into certain events with more detail. Super properties are different from properties in that super
    properties are attached to *every* event that gets sent up to Mixpanel. Things that you might
    use as super properties are perhaps certain things that you want to track across events that may
    help you determine certain patterns in the app. For example 'number_of_blogs' is a super property
    attached to every single event.
 */
+ (void)clearPropertiesForAllEvents;
+ (void)incrementProperty:(NSString *)property forEvent:(NSString *)event;
+ (void)setValue:(id)value forProperty:(NSString *)property forEvent:(NSString *)event;
+ (void)flagProperty:(NSString *)property forEvent:(NSString *)event;
+ (void)unflagProperty:(NSString *)property forEvent:(NSString *)event;


+ (void)flagSuperProperty:(NSString *)property;
+ (void)incrementSuperProperty:(NSString *)property;
+ (void)setValue:(id)value forSuperProperty:(NSString *)property;

+ (void)flagPeopleProperty:(NSString *)property;
+ (void)incrementPeopleProperty:(NSString *)property;
+ (void)setValue:(id)value forPeopleProperty:(NSString *)property;

+ (void)flagPeopleAndSuperProperty:(NSString *)property;
+ (void)incrementPeopleAndSuperProperty:(NSString *)property;
+ (void)setValue:(id)value forPeopleAndSuperProperty:(NSString *)property;

@end
