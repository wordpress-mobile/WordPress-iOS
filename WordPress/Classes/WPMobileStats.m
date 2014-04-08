#import "WPMobileStats.h"
#import <Mixpanel/Mixpanel.h>
#import "WordPressComApiCredentials.h"
#import "WordPressComApi.h"
#import "WordPressAppDelegate.h"
#import "NSString+Helpers.h"
#import "WPAccount.h"
#import "ContextManager.h"
#import "Blog.h"
#import "Constants.h"
#import "AccountService.h"

static BOOL hasRecordedAppOpenedEvent = NO;

@interface WPMobileStats() {
    NSMutableDictionary *_aggregatedEventProperties;
}

@end

@implementation WPMobileStats

- (id)init
{
    self = [super init];
    if (self) {
        _aggregatedEventProperties = [[NSMutableDictionary alloc] init];
    }
    return self;
}

+ (WPMobileStats *)sharedInstance
{
    static WPMobileStats *sharedInstance = nil;
    
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

+ (void)trackEventForSelfHostedAndWPCom:(NSString *)event
{
    [[self sharedInstance] trackEventForSelfHostedAndWPCom:event];
}

+ (void)trackEventForSelfHostedAndWPCom:(NSString *)event properties:(NSDictionary *)properties
{
    [[self sharedInstance] trackEventForSelfHostedAndWPCom:event properties:properties];
}

+ (void)trackEventForSelfHostedAndWPComWithSavedProperties:(NSString *)event
{
    [[self sharedInstance] trackEventForSelfHostedAndWPComWithSavedProperties:event];
}

+ (void)trackEventForWPCom:(NSString *)event
{
    [[self sharedInstance] trackEventForWPCom:event];
}

+ (void)trackEventForWPCom:(NSString *)event properties:(NSDictionary *)properties
{
    [[self sharedInstance] trackEventForWPCom:event properties:properties];
}

+ (void)trackEventForWPComWithSavedProperties:(NSString *)event
{
    [[self sharedInstance] trackEventForWPComWithSavedProperties:event];
}

+ (void)pingWPComStatsEndpoint:(NSString *)statName
{
    int x = arc4random();
    NSString *statsURL = [NSString stringWithFormat:@"%@%@%@%@%d" , kMobileReaderURL, @"&template=stats&stats_name=", statName, @"&rnd=", x];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:statsURL]];
    WordPressAppDelegate *appDelegate = (WordPressAppDelegate *)[[UIApplication sharedApplication] delegate];
    [request setValue:[appDelegate applicationUserAgent] forHTTPHeaderField:@"User-Agent"];
    @autoreleasepool {
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:nil];
        [conn start];
    }
}

+ (void)clearPropertiesForAllEvents
{
    [[self sharedInstance] clearPropertiesForAllEvents];
}

+ (void)incrementProperty:(NSString *)property forEvent:(NSString *)event
{
    [[self sharedInstance] incrementProperty:property forEvent:event];
}

+ (void)setValue:(id)value forProperty:(NSString *)property forEvent:(NSString *)event
{
    [[self sharedInstance] setValue:value forProperty:property forEvent:event];
}

+ (void)flagProperty:(NSString *)property forEvent:(NSString *)event
{
    [[self sharedInstance] flagProperty:property forEvent:event];
}

+ (void)unflagProperty:(NSString *)property forEvent:(NSString *)event
{
    [[self sharedInstance] unflagProperty:property forEvent:event];
}

+ (void)flagSuperProperty:(NSString *)property
{
    [[self sharedInstance] flagSuperProperty:property];
}

+ (void)incrementSuperProperty:(NSString *)property
{
    [[self sharedInstance] incrementSuperProperty:property];
}

+ (void)setValue:(id)value forSuperProperty:(NSString *)property
{
    [[self sharedInstance] setValue:value forSuperProperty:property];
}

+ (void)flagPeopleProperty:(NSString *)property
{
    [[self sharedInstance] flagPeopleProperty:property];
}

+ (void)incrementPeopleProperty:(NSString *)property
{
    [[self sharedInstance] incrementPeopleProperty:property];
}

+ (void)setValue:(id)value forPeopleProperty:(NSString *)property
{
    [[self sharedInstance] setValue:value forPeopleProperty:property];
}

+ (void)flagPeopleAndSuperProperty:(NSString *)property
{
    [[self sharedInstance] flagPeopleAndSuperProperty:property];
}

+ (void)incrementPeopleAndSuperProperty:(NSString *)property
{
    [[self sharedInstance] incrementPeopleAndSuperProperty:property];
}

+ (void)setValue:(id)value forPeopleAndSuperProperty:(NSString *)property
{
    [[self sharedInstance] setValue:value forPeopleAndSuperProperty:property];
}

#pragma mark - Private Methods

- (BOOL)connectedToWordPressDotCom
{
    NSManagedObjectContext *context = [[ContextManager sharedInstance] mainContext];
    AccountService *accountService = [[AccountService alloc] initWithManagedObjectContext:context];
    WPAccount *defaultAccount = [accountService defaultWordPressComAccount];

    return [[defaultAccount restApi] hasCredentials];
}

- (void)trackEventForSelfHostedAndWPCom:(NSString *)event
{
    [[Mixpanel sharedInstance] track:event];
}

- (void)trackEventForSelfHostedAndWPCom:(NSString *)event properties:(NSDictionary *)properties
{
    [[Mixpanel sharedInstance] track:event properties:properties];
}

- (void)trackEventForSelfHostedAndWPComWithSavedProperties:(NSString *)event
{
    [[Mixpanel sharedInstance] track:event properties:[self propertiesForEvent:event]];
}

- (void)trackEventForWPCom:(NSString *)event
{
    if ([self connectedToWordPressDotCom]) {
        [[Mixpanel sharedInstance] track:event];
    }
}

- (void)trackEventForWPCom:(NSString *)event properties:(NSDictionary *)properties
{
    if ([self connectedToWordPressDotCom]) {
        [[Mixpanel sharedInstance] track:event properties:properties];
    }
}

- (void)trackEventForWPComWithSavedProperties:(NSString *)event
{
    if ([self connectedToWordPressDotCom]) {
        [[Mixpanel sharedInstance] track:event properties:[self propertiesForEvent:event]];
    }
}

- (void)clearPropertiesForAllEvents
{
    [_aggregatedEventProperties removeAllObjects];
}

- (void)incrementProperty:(NSString *)property forEvent:(NSString *)event
{
    NSNumber *currentValue = [self property:property forEvent:event];
    int newValue;
    if (currentValue == nil) {
        newValue = 1;
    } else {
        newValue = [currentValue intValue];
        newValue++;
    }
    
    [self saveProperty:property withValue:@(newValue) forEvent:event];
}

- (void)flagProperty:(NSString *)property forEvent:(NSString *)event
{
    [self saveProperty:property withValue:@(YES) forEvent:event];
}

- (void)unflagProperty:(NSString *)property forEvent:(NSString *)event
{
    [self saveProperty:property withValue:@(NO) forEvent:event];
}

- (void)setValue:(id)value forProperty:(NSString *)property forEvent:(NSString *)event
{
    [self saveProperty:property withValue:value forEvent:event];
}

- (void)flagSuperProperty:(NSString *)property
{
    NSParameterAssert(property != nil);
    NSMutableDictionary *superProperties = [[NSMutableDictionary alloc] initWithDictionary:[Mixpanel sharedInstance].currentSuperProperties];
    superProperties[property] = @(YES);
    [[Mixpanel sharedInstance] registerSuperProperties:superProperties];
}


- (void)incrementSuperProperty:(NSString *)property
{
    NSParameterAssert(property != nil);
    NSMutableDictionary *superProperties = [[NSMutableDictionary alloc] initWithDictionary:[Mixpanel sharedInstance].currentSuperProperties];
    NSUInteger propertyValue = [superProperties[property] integerValue];
    superProperties[property] = @(++propertyValue);
    [[Mixpanel sharedInstance] registerSuperProperties:superProperties];
}

- (void)setValue:(id)value forSuperProperty:(NSString *)property
{
    NSParameterAssert(value != nil);
    NSParameterAssert(property != nil);
    NSMutableDictionary *superProperties = [[NSMutableDictionary alloc] initWithDictionary:[Mixpanel sharedInstance].currentSuperProperties];
    superProperties[property] = value;
    [[Mixpanel sharedInstance] registerSuperProperties:superProperties];
}

- (void)flagPeopleProperty:(NSString *)property
{
    NSParameterAssert(property != nil);
    [[Mixpanel sharedInstance].people set:@{ property : @(YES) }];
}

- (void)incrementPeopleProperty:(NSString *)property
{
    NSParameterAssert(property != nil);
    [[Mixpanel sharedInstance].people increment:property by:@(1)];
}

- (void)setValue:(id)value forPeopleProperty:(NSString *)property
{
    NSParameterAssert(value != nil);
    NSParameterAssert(property != nil);
    [[Mixpanel sharedInstance].people set:@{property: value}];
}

- (void)flagPeopleAndSuperProperty:(NSString *)property
{
    NSParameterAssert(property != nil);
    [self flagPeopleProperty:property];
    [self flagSuperProperty:property];
}

- (void)incrementPeopleAndSuperProperty:(NSString *)property
{
    NSParameterAssert(property != nil);
    [self incrementPeopleProperty:property];
    [self incrementSuperProperty:property];
}

- (void)setValue:(id)value forPeopleAndSuperProperty:(NSString *)property
{
    NSParameterAssert(value != nil);
    NSParameterAssert(property != nil);
    [self setValue:value forPeopleProperty:property];
    [self setValue:value forSuperProperty:property];
}


- (id)property:(NSString *)property forEvent:(NSString *)event
{
    NSMutableDictionary *eventProperties = [_aggregatedEventProperties objectForKey:event];
    return [eventProperties objectForKey:property];
}

- (void)saveProperty:(NSString *)property withValue:(id)value forEvent:(NSString *)event
{
    NSMutableDictionary *eventProperties = [_aggregatedEventProperties objectForKey:event];
    if (eventProperties == nil) {
        eventProperties = [[NSMutableDictionary alloc] init];
        [_aggregatedEventProperties setValue:eventProperties forKey:event];
    }
    
    [eventProperties setValue:value forKey:property];
}

- (NSDictionary *)propertiesForEvent:(NSString *)event
{
    return [_aggregatedEventProperties objectForKey:event];
}


@end
