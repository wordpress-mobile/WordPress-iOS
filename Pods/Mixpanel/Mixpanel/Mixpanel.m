#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Either turn on ARC for the project or use -fobjc-arc flag on this file.
#endif

#include <arpa/inet.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <sys/socket.h>
#include <sys/sysctl.h>

#import <CommonCrypto/CommonDigest.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <UIKit/UIDevice.h>

#import "MPSurveyNavigationController.h"
#import "MPNotification.h"
#import "MPNotificationViewController.h"
#import "Mixpanel.h"
#import "NSData+MPBase64.h"
#import "UIView+MPSnapshotImage.h"
#import "MPVariant.h"

#import "MPWebSocket.h"
#import "MPABTestDesignerConnection.h"

#define VERSION @"2.5.3"

#ifdef MIXPANEL_LOG
#define MixpanelLog(...) NSLog(__VA_ARGS__)
#else
#define MixpanelLog(...)
#endif

#ifdef MIXPANEL_DEBUG
#define MixpanelDebug(...) NSLog(__VA_ARGS__)
#else
#define MixpanelDebug(...)
#endif

@interface Mixpanel () <UIAlertViewDelegate, MPSurveyNavigationControllerDelegate, MPNotificationViewControllerDelegate> {
    NSUInteger _flushInterval;
}

// re-declare internally as readwrite
@property (atomic, strong) MixpanelPeople *people;
@property (atomic, copy) NSString *distinctId;

@property (nonatomic, copy) NSString *apiToken;
@property (atomic, strong) NSDictionary *superProperties;
@property (atomic, strong) NSDictionary *automaticProperties;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSMutableArray *eventsQueue;
@property (nonatomic, strong) NSMutableArray *peopleQueue;
@property (nonatomic, assign) UIBackgroundTaskIdentifier taskId;
@property (nonatomic, strong) dispatch_queue_t serialQueue;
@property (nonatomic, assign) SCNetworkReachabilityRef reachability;
@property (nonatomic, strong) CTTelephonyNetworkInfo *telephonyInfo;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSMutableDictionary *timedEvents;

@property (nonatomic) BOOL decideResponseCached;

@property (nonatomic, strong) NSArray *surveys;
@property (nonatomic, strong) MPSurvey *currentlyShowingSurvey;
@property (nonatomic, strong) NSMutableSet *shownSurveyCollections;

@property (nonatomic, strong) NSArray *notifications;
@property (nonatomic, strong) MPNotification *currentlyShowingNotification;
@property (nonatomic, strong) MPNotificationViewController *notificationViewController;
@property (nonatomic, strong) NSMutableSet *shownNotifications;

@property (nonatomic, strong) MPABTestDesignerConnection *abtestDesignerConnection;
@property (nonatomic, strong) NSSet *variants;

@property (atomic, copy) NSString *decideURL;
@property (atomic, copy) NSString *switchboardURL;

@end

@interface MixpanelPeople ()

@property (nonatomic, weak) Mixpanel *mixpanel;
@property (nonatomic, strong) NSMutableArray *unidentifiedQueue;
@property (nonatomic, copy) NSString *distinctId;
@property (nonatomic, strong) NSDictionary *automaticPeopleProperties;

- (id)initWithMixpanel:(Mixpanel *)mixpanel;
- (void)merge:(NSDictionary *)properties;

@end

static NSString *MPURLEncode(NSString *s)
{
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)s, NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8));
}

@implementation Mixpanel

static void MixpanelReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
    if (info != NULL && [(__bridge NSObject*)info isKindOfClass:[Mixpanel class]]) {
        @autoreleasepool {
            Mixpanel *mixpanel = (__bridge Mixpanel *)info;
            [mixpanel reachabilityChanged:flags];
        }
    } else {
        NSLog(@"Mixpanel reachability callback received unexpected info object");
    }
}

static Mixpanel *sharedInstance = nil;

+ (Mixpanel *)sharedInstanceWithToken:(NSString *)apiToken launchOptions:(NSDictionary *)launchOptions
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc] initWithToken:apiToken launchOptions:launchOptions andFlushInterval:60];
    });
    return sharedInstance;
}

+ (Mixpanel *)sharedInstanceWithToken:(NSString *)apiToken
{
    return [Mixpanel sharedInstanceWithToken:apiToken launchOptions:nil];
}

+ (Mixpanel *)sharedInstance
{
    if (sharedInstance == nil) {
        NSLog(@"%@ warning sharedInstance called before sharedInstanceWithToken:", self);
    }
    return sharedInstance;
}

- (instancetype)initWithToken:(NSString *)apiToken launchOptions:(NSDictionary *)launchOptions andFlushInterval:(NSUInteger)flushInterval
{
    if (apiToken == nil) {
        apiToken = @"";
    }
    if ([apiToken length] == 0) {
        NSLog(@"%@ warning empty api token", self);
    }
    if (self = [self init]) {
        self.people = [[MixpanelPeople alloc] initWithMixpanel:self];
        self.apiToken = apiToken;
        _flushInterval = flushInterval;
        self.flushOnBackground = YES;
        self.showNetworkActivityIndicator = YES;

        self.serverURL = @"https://api.mixpanel.com";
        self.decideURL = @"https://decide.mixpanel.com";
        self.switchboardURL = @"wss://switchboard.mixpanel.com";

        self.showNotificationOnActive = YES;
        self.checkForNotificationsOnActive = YES;
        self.checkForVariantsOnActive = YES;
        self.checkForSurveysOnActive = YES;
        self.miniNotificationPresentationTime = 6.0;

        self.distinctId = [self defaultDistinctId];
        self.superProperties = [NSMutableDictionary dictionary];
        self.automaticProperties = [self collectAutomaticProperties];
        self.eventsQueue = [NSMutableArray array];
        self.peopleQueue = [NSMutableArray array];
        self.taskId = UIBackgroundTaskInvalid;
        NSString *label = [NSString stringWithFormat:@"com.mixpanel.%@.%p", apiToken, self];
        self.serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        [_dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
        self.timedEvents = [NSMutableDictionary dictionary];

        self.decideResponseCached = NO;
        self.showSurveyOnActive = YES;
        self.surveys = nil;
        self.currentlyShowingSurvey = nil;
        self.shownSurveyCollections = [NSMutableSet set];
        self.shownNotifications = [NSMutableSet set];
        self.currentlyShowingNotification = nil;
        self.notifications = nil;
        self.variants = nil;

        [self setupListeners];
        [self unarchive];
        [self executeCachedVariants];

        if (launchOptions && launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
            [self trackPushNotification:launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] event:@"$app_open"];
        }
    }

    return self;
}

- (instancetype)initWithToken:(NSString *)apiToken andFlushInterval:(NSUInteger)flushInterval
{
    return [self initWithToken:apiToken launchOptions:nil andFlushInterval:flushInterval];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_reachability != NULL) {
        if (!SCNetworkReachabilitySetCallback(_reachability, NULL, NULL)) {
            NSLog(@"%@ error unsetting reachability callback", self);
        }
        if (!SCNetworkReachabilitySetDispatchQueue(_reachability, NULL)) {
            NSLog(@"%@ error unsetting reachability dispatch queue", self);
        }
        CFRelease(_reachability);
        _reachability = NULL;
        MixpanelDebug(@"realeased reachability");
    }
}

- (void)setupListeners
{
    // wifi reachability
    BOOL reachabilityOk = NO;
    if ((_reachability = SCNetworkReachabilityCreateWithName(NULL, "api.mixpanel.com")) != NULL) {
        SCNetworkReachabilityContext context = {0, (__bridge void*)self, NULL, NULL, NULL};
        if (SCNetworkReachabilitySetCallback(_reachability, MixpanelReachabilityCallback, &context)) {
            if (SCNetworkReachabilitySetDispatchQueue(_reachability, self.serialQueue)) {
                reachabilityOk = YES;
                MixpanelDebug(@"%@ successfully set up reachability callback", self);
            } else {
                // cleanup callback if setting dispatch queue failed
                SCNetworkReachabilitySetCallback(_reachability, NULL, NULL);
            }
        }
    }
    if (!reachabilityOk) {
        NSLog(@"%@ failed to set up reachability callback: %s", self, SCErrorString(SCError()));
    }

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    // cellular info
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        [self setCurrentRadio];
        [notificationCenter addObserver:self
                               selector:@selector(setCurrentRadio)
                                   name:CTRadioAccessTechnologyDidChangeNotification
                                 object:nil];
    }
#endif

    // Application lifecycle events
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillTerminate:)
                               name:UIApplicationWillTerminateNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillResignActive:)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillEnterForeground:)
                               name:UIApplicationWillEnterForegroundNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(appLinksNotificationRaised:)
                               name:@"com.parse.bolts.measurement_event"
                             object:nil];

#ifndef DISABLE_MIXPANEL_AB_DESIGNER
    dispatch_async(dispatch_get_main_queue(), ^{
        UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(connectGestureRecognized:)];
        recognizer.minimumPressDuration = 3;
        recognizer.cancelsTouchesInView = NO;
#if TARGET_IPHONE_SIMULATOR
        recognizer.numberOfTouchesRequired = 2;
#else
        recognizer.numberOfTouchesRequired = 4;
#endif
        [[UIApplication sharedApplication].keyWindow addGestureRecognizer:recognizer];
    });
#endif
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<Mixpanel: %p %@>", self, self.apiToken];
}

- (NSString *)deviceModel
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char answer[size];
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    NSString *results = @(answer);
    return results;
}

- (NSString *)IFA
{
    NSString *ifa = nil;
#ifndef MIXPANEL_NO_IFA
    Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
    if (ASIdentifierManagerClass) {
        SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
        id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
        SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
        NSUUID *uuid = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
        ifa = [uuid UUIDString];
    }
#endif
    return ifa;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
- (void)setCurrentRadio
{
    dispatch_async(self.serialQueue, ^(){
        NSMutableDictionary *properties = [self.automaticProperties mutableCopy];
        properties[@"$radio"] = [self currentRadio];
        self.automaticProperties = [properties copy];
    });
}

- (NSString *)currentRadio
{
    NSString *radio = _telephonyInfo.currentRadioAccessTechnology;
    if (!radio) {
        radio = @"None";
    } else if ([radio hasPrefix:@"CTRadioAccessTechnology"]) {
        radio = [radio substringFromIndex:23];
    }
    return radio;
}
#endif

- (NSDictionary *)collectAutomaticProperties
{
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    UIDevice *device = [UIDevice currentDevice];
    NSString *deviceModel = [self deviceModel];
    CGSize size = [UIScreen mainScreen].bounds.size;
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [networkInfo subscriberCellularProvider];

    // Use setValue semantics to avoid adding keys where value can be nil.
    [p setValue:[[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"] forKey:@"$app_version"];
    [p setValue:[[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] forKey:@"$app_release"];
    [p setValue:[self IFA] forKey:@"$ios_ifa"];
    [p setValue:carrier.carrierName forKey:@"$carrier"];

    [p addEntriesFromDictionary:@{
             @"mp_lib": @"iphone",
             @"$lib_version": VERSION,
             @"$manufacturer": @"Apple",
             @"$os": [device systemName],
             @"$os_version": [device systemVersion],
             @"$model": deviceModel,
             @"mp_device_model": deviceModel, //legacy
             @"$screen_height": @((NSInteger)size.height),
             @"$screen_width": @((NSInteger)size.width)
    }];
    return [p copy];
}

+ (BOOL)inBackground
{
    return [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
}

#pragma mark - Encoding/decoding utilities

- (NSData *)JSONSerializeObject:(id)obj
{
    id coercedObj = [self JSONSerializableObjectForObject:obj];
    NSError *error = nil;
    NSData *data = nil;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:coercedObj options:0 error:&error];
    }
    @catch (NSException *exception) {
        NSLog(@"%@ exception encoding api data: %@", self, exception);
    }
    if (error) {
        NSLog(@"%@ error encoding api data: %@", self, error);
    }
    return data;
}

- (id)JSONSerializableObjectForObject:(id)obj
{
    // valid json types
    if ([obj isKindOfClass:[NSString class]] ||
        [obj isKindOfClass:[NSNumber class]] ||
        [obj isKindOfClass:[NSNull class]]) {
        return obj;
    }
    // recurse on containers
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *a = [NSMutableArray array];
        for (id i in obj) {
            [a addObject:[self JSONSerializableObjectForObject:i]];
        }
        return [NSArray arrayWithArray:a];
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        for (id key in obj) {
            NSString *stringKey;
            if (![key isKindOfClass:[NSString class]]) {
                stringKey = [key description];
                NSLog(@"%@ warning: property keys should be strings. got: %@. coercing to: %@", self, [key class], stringKey);
            } else {
                stringKey = [NSString stringWithString:key];
            }
            id v = [self JSONSerializableObjectForObject:obj[key]];
            d[stringKey] = v;
        }
        return [NSDictionary dictionaryWithDictionary:d];
    }
    // some common cases
    if ([obj isKindOfClass:[NSDate class]]) {
        return [self.dateFormatter stringFromDate:obj];
    } else if ([obj isKindOfClass:[NSURL class]]) {
        return [obj absoluteString];
    }
    // default to sending the object's description
    NSString *s = [obj description];
    NSLog(@"%@ warning: property values should be valid json types. got: %@. coercing to: %@", self, [obj class], s);
    return s;
}

- (NSString *)encodeAPIData:(NSArray *)array
{
    NSString *b64String = @"";
    NSData *data = [self JSONSerializeObject:array];
    if (data) {
        b64String = [data mp_base64EncodedString];
        b64String = (id)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                (CFStringRef)b64String,
                                                                NULL,
                                                                CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                kCFStringEncodingUTF8));
    }
    return b64String;
}

#pragma mark - Tracking

+ (void)assertPropertyTypes:(NSDictionary *)properties
{
    for (id __unused k in properties) {
        NSAssert([k isKindOfClass: [NSString class]], @"%@ property keys must be NSString. got: %@ %@", self, [k class], k);
        // would be convenient to do: id v = [properties objectForKey:k]; but
        // when the NSAssert's are stripped out in release, it becomes an
        // unused variable error. also, note that @YES and @NO pass as
        // instances of NSNumber class.
        NSAssert([properties[k] isKindOfClass:[NSString class]] ||
                 [properties[k] isKindOfClass:[NSNumber class]] ||
                 [properties[k] isKindOfClass:[NSNull class]] ||
                 [properties[k] isKindOfClass:[NSArray class]] ||
                 [properties[k] isKindOfClass:[NSDictionary class]] ||
                 [properties[k] isKindOfClass:[NSDate class]] ||
                 [properties[k] isKindOfClass:[NSURL class]],
                 @"%@ property values must be NSString, NSNumber, NSNull, NSArray, NSDictionary, NSDate or NSURL. got: %@ %@", self, [properties[k] class], properties[k]);
    }
}

- (NSString *)defaultDistinctId
{
    NSString *distinctId = [self IFA];

    if (!distinctId && NSClassFromString(@"UIDevice")) {
        distinctId = [[UIDevice currentDevice].identifierForVendor UUIDString];
    }
    if (!distinctId) {
        NSLog(@"%@ error getting device identifier: falling back to uuid", self);
        distinctId = [[NSUUID UUID] UUIDString];
    }
    if (!distinctId) {
        NSLog(@"%@ error getting uuid: no default distinct id could be generated", self);
    }
    return distinctId;
}


- (void)identify:(NSString *)distinctId
{
    if (distinctId == nil || distinctId.length == 0) {
        NSLog(@"%@ error blank distinct id: %@", self, distinctId);
        return;
    }
    dispatch_async(self.serialQueue, ^{
        self.distinctId = distinctId;
        self.people.distinctId = distinctId;
        if ([self.people.unidentifiedQueue count] > 0) {
            for (NSMutableDictionary *r in self.people.unidentifiedQueue) {
                r[@"$distinct_id"] = distinctId;
                [self.peopleQueue addObject:r];
            }
            [self.people.unidentifiedQueue removeAllObjects];
            [self archivePeople];
        }
        if ([Mixpanel inBackground]) {
            [self archiveProperties];
        }
    });
}

- (void)createAlias:(NSString *)alias forDistinctID:(NSString *)distinctID
{
    if (!alias || [alias length] == 0) {
        NSLog(@"%@ create alias called with empty alias: %@", self, alias);
        return;
    }
    if (!distinctID || [distinctID length] == 0) {
        NSLog(@"%@ create alias called with empty distinct id: %@", self, distinctID);
        return;
    }
    [self track:@"$create_alias" properties:@{@"distinct_id": distinctID, @"alias": alias}];
}

- (void)track:(NSString *)event
{
    [self track:event properties:nil];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties
{
    if (event == nil || [event length] == 0) {
        NSLog(@"%@ mixpanel track called with empty event parameter. using 'mp_event'", self);
        event = @"mp_event";
    }
    properties = [properties copy];
    [Mixpanel assertPropertyTypes:properties];
    
    double epochInterval = [[NSDate date] timeIntervalSince1970];
    NSNumber *epochSeconds = @(round(epochInterval));
    dispatch_async(self.serialQueue, ^{
        NSNumber *eventStartTime = self.timedEvents[event];
        NSMutableDictionary *p = [NSMutableDictionary dictionary];
        [p addEntriesFromDictionary:self.automaticProperties];
        p[@"token"] = self.apiToken;
        p[@"time"] = epochSeconds;
        if (eventStartTime) {
            [self.timedEvents removeObjectForKey:event];
            p[@"$duration"] = [NSString stringWithFormat:@"%.3f", epochInterval - [eventStartTime doubleValue]];
        }
        if (self.nameTag) {
            p[@"mp_name_tag"] = self.nameTag;
        }
        if (self.distinctId) {
            p[@"distinct_id"] = self.distinctId;
        }
        [p addEntriesFromDictionary:self.superProperties];
        if (properties) {
            [p addEntriesFromDictionary:properties];
        }
        NSDictionary *e = @{@"event": event, @"properties": [NSDictionary dictionaryWithDictionary:p]};
        MixpanelLog(@"%@ queueing event: %@", self, e);
        [self.eventsQueue addObject:e];
        if ([self.eventsQueue count] > 500) {
            [self.eventsQueue removeObjectAtIndex:0];
        }
        if ([Mixpanel inBackground]) {
            [self archiveEvents];
        }
    });
}

- (void)registerSuperProperties:(NSDictionary *)properties
{
    properties = [properties copy];
    [Mixpanel assertPropertyTypes:properties];
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:self.superProperties];
        [tmp addEntriesFromDictionary:properties];
        self.superProperties = [NSDictionary dictionaryWithDictionary:tmp];
        if ([Mixpanel inBackground]) {
            [self archiveProperties];
        }
    });
}

- (void)registerSuperPropertiesOnce:(NSDictionary *)properties
{
    [self registerSuperPropertiesOnce:properties defaultValue:nil];
}

- (void)registerSuperPropertiesOnce:(NSDictionary *)properties defaultValue:(id)defaultValue
{
    properties = [properties copy];
    [Mixpanel assertPropertyTypes:properties];
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:self.superProperties];
        for (NSString *key in properties) {
            id value = tmp[key];
            if (value == nil || [value isEqual:defaultValue]) {
                tmp[key] = properties[key];
            }
        }
        self.superProperties = [NSDictionary dictionaryWithDictionary:tmp];
        if ([Mixpanel inBackground]) {
            [self archiveProperties];
        }
    });
}

- (void)unregisterSuperProperty:(NSString *)propertyName
{
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:self.superProperties];
        if (tmp[propertyName] != nil) {
            [tmp removeObjectForKey:propertyName];
        }
        self.superProperties = [NSDictionary dictionaryWithDictionary:tmp];
        if ([Mixpanel inBackground]) {
            [self archiveProperties];
        }
    });
}

- (void)clearSuperProperties
{
    dispatch_async(self.serialQueue, ^{
        self.superProperties = @{};
        if ([Mixpanel inBackground]) {
            [self archiveProperties];
        }
    });
}

- (NSDictionary *)currentSuperProperties
{
    return [self.superProperties copy];
}

- (void)timeEvent:(NSString *)event
{
    if (event == nil || [event length] == 0) {
        NSLog(@"Mixpanel cannot time an empty event");
        return;
    }
    dispatch_async(self.serialQueue, ^{
        self.timedEvents[event] = @([[NSDate date] timeIntervalSince1970]);
    });
}

- (void)clearTimedEvents
{   dispatch_async(self.serialQueue, ^{
        self.timedEvents = [NSMutableDictionary dictionary];
    });
}

- (void)reset
{
    dispatch_async(self.serialQueue, ^{
        self.distinctId = [self defaultDistinctId];
        self.nameTag = nil;
        self.superProperties = [NSMutableDictionary dictionary];
        self.people.distinctId = nil;
        self.people.unidentifiedQueue = [NSMutableArray array];
        self.eventsQueue = [NSMutableArray array];
        self.peopleQueue = [NSMutableArray array];
        self.timedEvents = [NSMutableDictionary dictionary];
        [self archive];
    });
}

#pragma mark - Network control

- (NSUInteger)flushInterval
{
    @synchronized(self) {
        return _flushInterval;
    }
}

- (void)setFlushInterval:(NSUInteger)interval
{
    @synchronized(self) {
        _flushInterval = interval;
    }
    [self startFlushTimer];
}

- (void)startFlushTimer
{
    [self stopFlushTimer];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.flushInterval > 0) {
            self.timer = [NSTimer scheduledTimerWithTimeInterval:self.flushInterval
                                                          target:self
                                                        selector:@selector(flush)
                                                        userInfo:nil
                                                         repeats:YES];
            MixpanelDebug(@"%@ started flush timer: %@", self, self.timer);
        }
    });
}

- (void)stopFlushTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.timer) {
            [self.timer invalidate];
            MixpanelDebug(@"%@ stopped flush timer: %@", self, self.timer);
        }
        self.timer = nil;
    });
}

- (void)flush
{
    dispatch_async(self.serialQueue, ^{
        MixpanelDebug(@"%@ flush starting", self);

        __strong id<MixpanelDelegate> strongDelegate = self.delegate;
        if (strongDelegate != nil && [strongDelegate respondsToSelector:@selector(mixpanelWillFlush:)] && ![strongDelegate mixpanelWillFlush:self]) {
            MixpanelDebug(@"%@ flush deferred by delegate", self);
            return;
        }

        [self flushEvents];
        [self flushPeople];

        MixpanelDebug(@"%@ flush complete", self);
    });
}

- (void)flushEvents
{
    [self flushQueue:_eventsQueue
            endpoint:@"/track/"];
}

- (void)flushPeople
{
    [self flushQueue:_peopleQueue
            endpoint:@"/engage/"];
}

- (void)flushQueue:(NSMutableArray *)queue endpoint:(NSString *)endpoint
{
    while ([queue count] > 0) {
        NSUInteger batchSize = ([queue count] > 50) ? 50 : [queue count];
        NSArray *batch = [queue subarrayWithRange:NSMakeRange(0, batchSize)];

        NSString *requestData = [self encodeAPIData:batch];
        NSString *postBody = [NSString stringWithFormat:@"ip=1&data=%@", requestData];
        MixpanelDebug(@"%@ flushing %lu of %lu to %@: %@", self, (unsigned long)[batch count], (unsigned long)[queue count], endpoint, queue);
        NSURLRequest *request = [self apiRequestWithEndpoint:endpoint andBody:postBody];
        NSError *error = nil;

        [self updateNetworkActivityIndicator:YES];

        NSURLResponse *urlResponse = nil;
        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];

        [self updateNetworkActivityIndicator:NO];

        if (error) {
            NSLog(@"%@ network failure: %@", self, error);
            break;
        }

        NSString *response = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        if ([response intValue] == 0) {
            NSLog(@"%@ %@ api rejected some items", self, endpoint);
        };

        [queue removeObjectsInArray:batch];
    }
}

- (void)updateNetworkActivityIndicator:(BOOL)on
{
    if (_showNetworkActivityIndicator) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = on;
    }
}

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags
{
    // this should be run in the serial queue. the reason we don't dispatch_async here
    // is because it's only ever called by the reachability callback, which is already
    // set to run on the serial queue. see SCNetworkReachabilitySetDispatchQueue in init
    BOOL wifi = (flags & kSCNetworkReachabilityFlagsReachable) && !(flags & kSCNetworkReachabilityFlagsIsWWAN);
    NSMutableDictionary *properties = [self.automaticProperties mutableCopy];
    properties[@"$wifi"] = wifi ? @YES : @NO;
    self.automaticProperties = [properties copy];
    MixpanelDebug(@"%@ reachability changed, wifi=%d", self, wifi);
}

- (NSURLRequest *)apiRequestWithEndpoint:(NSString *)endpoint andBody:(NSString *)body
{
    NSURL *URL = [NSURL URLWithString:[self.serverURL stringByAppendingString:endpoint]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    MixpanelDebug(@"%@ http request: %@?%@", self, URL, body);
    return request;
}

#pragma mark - Persistence

- (NSString *)filePathForData:(NSString *)data
{
    NSString *filename = [NSString stringWithFormat:@"mixpanel-%@-%@.plist", self.apiToken, data];
    return [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
            stringByAppendingPathComponent:filename];
}

- (NSString *)eventsFilePath
{
    return [self filePathForData:@"events"];
}

- (NSString *)peopleFilePath
{
    return [self filePathForData:@"people"];
}

- (NSString *)propertiesFilePath
{
    return [self filePathForData:@"properties"];
}

- (NSString *)variantsFilePath
{
    return [self filePathForData:@"variants"];
}

- (void)archive
{
    [self archiveEvents];
    [self archivePeople];
    [self archiveProperties];
    [self archiveVariants];
}

- (void)archiveEvents
{
    NSString *filePath = [self eventsFilePath];
    NSMutableArray *eventsQueueCopy = [NSMutableArray arrayWithArray:[self.eventsQueue copy]];
    MixpanelDebug(@"%@ archiving events data to %@: %@", self, filePath, eventsQueueCopy);
    if (![NSKeyedArchiver archiveRootObject:eventsQueueCopy toFile:filePath]) {
        NSLog(@"%@ unable to archive events data", self);
    }
}

- (void)archivePeople
{
    NSString *filePath = [self peopleFilePath];
    NSMutableArray *peopleQueueCopy = [NSMutableArray arrayWithArray:[self.peopleQueue copy]];
    MixpanelDebug(@"%@ archiving people data to %@: %@", self, filePath, peopleQueueCopy);
    if (![NSKeyedArchiver archiveRootObject:peopleQueueCopy toFile:filePath]) {
        NSLog(@"%@ unable to archive people data", self);
    }
}

- (void)archiveProperties
{
    NSString *filePath = [self propertiesFilePath];
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    [p setValue:self.distinctId forKey:@"distinctId"];
    [p setValue:self.nameTag forKey:@"nameTag"];
    [p setValue:self.superProperties forKey:@"superProperties"];
    [p setValue:self.people.distinctId forKey:@"peopleDistinctId"];
    [p setValue:self.people.unidentifiedQueue forKey:@"peopleUnidentifiedQueue"];
    [p setValue:self.shownSurveyCollections forKey:@"shownSurveyCollections"];
    [p setValue:self.shownNotifications forKey:@"shownNotifications"];
    [p setValue:self.timedEvents forKey:@"timedEvents"];
    MixpanelDebug(@"%@ archiving properties data to %@: %@", self, filePath, p);
    if (![NSKeyedArchiver archiveRootObject:p toFile:filePath]) {
        NSLog(@"%@ unable to archive properties data", self);
    }
}

- (void)archiveVariants
{
    NSString *filePath = [self variantsFilePath];
    if (![NSKeyedArchiver archiveRootObject:self.variants toFile:filePath]) {
        NSLog(@"%@ unable to archive variants data", self);
    }
}

- (void)unarchive
{
    [self unarchiveEvents];
    [self unarchivePeople];
    [self unarchiveProperties];
    [self unarchiveVariants];
}

- (id)unarchiveFromFile:(NSString *)filePath
{
    id unarchivedData = nil;
    @try {
        unarchivedData = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        MixpanelDebug(@"%@ unarchived data from %@: %@", self, filePath, unarchivedData);
    }
    @catch (NSException *exception) {
        NSLog(@"%@ unable to unarchive data in %@, starting fresh", self, filePath);
        unarchivedData = nil;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSError *error;
        BOOL removed = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (!removed) {
            NSLog(@"%@ unable to remove archived file at %@ - %@", self, filePath, error);
        }
    }
    return unarchivedData;
}

- (void)unarchiveEvents
{
    self.eventsQueue = (NSMutableArray *)[self unarchiveFromFile:[self eventsFilePath]];
    if (!self.eventsQueue) {
        self.eventsQueue = [NSMutableArray array];
    }
}

- (void)unarchivePeople
{
    self.peopleQueue = (NSMutableArray *)[self unarchiveFromFile:[self peopleFilePath]];
    if (!self.peopleQueue) {
        self.peopleQueue = [NSMutableArray array];
    }
}

- (void)unarchiveProperties
{
    NSDictionary *properties = (NSDictionary *)[self unarchiveFromFile:[self propertiesFilePath]];
    if (properties) {
        self.distinctId = properties[@"distinctId"] ? properties[@"distinctId"] : [self defaultDistinctId];
        self.nameTag = properties[@"nameTag"];
        self.superProperties = properties[@"superProperties"] ? properties[@"superProperties"] : [NSMutableDictionary dictionary];
        self.people.distinctId = properties[@"peopleDistinctId"];
        self.people.unidentifiedQueue = properties[@"peopleUnidentifiedQueue"] ? properties[@"peopleUnidentifiedQueue"] : [NSMutableArray array];
        self.shownSurveyCollections = properties[@"shownSurveyCollections"] ? properties[@"shownSurveyCollections"] : [NSMutableSet set];
        self.shownNotifications = properties[@"shownNotifications"] ? properties[@"shownNotifications"] : [NSMutableSet set];
        self.variants = properties[@"variants"] ? properties[@"variants"] : [NSSet set];
        self.timedEvents = properties[@"timedEvents"] ? properties[@"timedEvents"] : [NSMutableDictionary dictionary];
    }
}

- (void)unarchiveVariants
{
    self.variants = (NSSet *)[self unarchiveFromFile:[self variantsFilePath]];
    if (!self.variants) {
        self.variants = [NSSet set];
    }
}

#pragma mark - UIApplication notifications

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    MixpanelDebug(@"%@ application did become active", self);
    [self startFlushTimer];

    if (self.checkForSurveysOnActive || self.checkForNotificationsOnActive) {
        NSDate *start = [NSDate date];

        [self checkForDecideResponseWithCompletion:^(NSArray *surveys, NSArray *notifications, NSSet *variants) {
            if (self.showNotificationOnActive && notifications && [notifications count] > 0) {
                [self showNotificationWithObject:notifications[0]];
            } else if (self.showSurveyOnActive && surveys && [surveys count] > 0) {
                [self showSurveyWithObject:surveys[0] withAlert:([start timeIntervalSinceNow] < -2.0)];
            }

            dispatch_sync(dispatch_get_main_queue(), ^{
                for (MPVariant *variant in variants) {
                    [variant execute];
                    [self markVariantRun:variant];
                }
            });

        }];
    }
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    MixpanelDebug(@"%@ application will resign active", self);
    [self stopFlushTimer];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    MixpanelDebug(@"%@ did enter background", self);

    self.taskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        MixpanelDebug(@"%@ flush %lu cut short", self, (unsigned long)self.taskId);
        [[UIApplication sharedApplication] endBackgroundTask:self.taskId];
        self.taskId = UIBackgroundTaskInvalid;
    }];
    MixpanelDebug(@"%@ starting background cleanup task %lu", self, (unsigned long)self.taskId);

    if (self.flushOnBackground) {
        [self flush];
    }

    dispatch_async(_serialQueue, ^{
        [self archive];
        MixpanelDebug(@"%@ ending background cleanup task %lu", self, (unsigned long)self.taskId);
        if (self.taskId != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self.taskId];
            self.taskId = UIBackgroundTaskInvalid;
        }
        self.decideResponseCached = NO;
    });
}

- (void)applicationWillEnterForeground:(NSNotificationCenter *)notification
{
    MixpanelDebug(@"%@ will enter foreground", self);
    dispatch_async(self.serialQueue, ^{
        if (self.taskId != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self.taskId];
            self.taskId = UIBackgroundTaskInvalid;
            [self updateNetworkActivityIndicator:NO];
        }
    });
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    MixpanelDebug(@"%@ application will terminate", self);
    dispatch_async(_serialQueue, ^{
       [self archive];
    });
}

- (void)trackPushNotification:(NSDictionary *)userInfo event:(NSString *)event
{
    MixpanelDebug(@"%@ tracking push payload %@", self, userInfo);

    if (userInfo && userInfo[@"mp"]) {
        NSDictionary *mpPayload = userInfo[@"mp"];

        if ([mpPayload isKindOfClass:[NSDictionary class]] && mpPayload[@"m"] && mpPayload[@"c"]) {
            [self track:event properties:@{@"campaign_id": mpPayload[@"c"],
                                           @"message_id": mpPayload[@"m"],
                                           @"message_type": @"push"}];
        } else {
            NSLog(@"%@ malformed mixpanel push payload %@", self, mpPayload);
        }
    }
}

- (void)trackPushNotification:(NSDictionary *)userInfo
{
    [self trackPushNotification:userInfo event:@"$campaign_received"];
}

- (void)appLinksNotificationRaised:(NSNotification *)notification
{
    NSDictionary *eventMap = @{@"al_nav_out": @"$al_nav_out",
                               @"al_nav_in": @"$al_nav_in",
                               @"al_ref_back_out": @"$al_ref_back_out"
                               };
    NSDictionary *userInfo = [notification userInfo];
    if (userInfo && userInfo[@"event_name"] && userInfo[@"event_args"] && eventMap[userInfo[@"event_name"]]) {
        [self track:eventMap[userInfo[@"event_name"]] properties:userInfo[@"event_args"]];
    }
}

#pragma mark - Decide

+ (UIViewController *)topPresentedViewController
{
    UIViewController *controller = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (controller.presentedViewController) {
        controller = controller.presentedViewController;
    }
    return controller;
}

- (void)checkForDecideResponseWithCompletion:(void (^)(NSArray *surveys, NSArray *notifications, NSSet *variants))completion
{
    [self checkForDecideResponseWithCompletion:completion useCache:YES];
}

- (void)checkForDecideResponseWithCompletion:(void (^)(NSArray *surveys, NSArray *notifications, NSSet *variants))completion useCache:(BOOL)useCache
{
    dispatch_async(self.serialQueue, ^{
        MixpanelDebug(@"%@ decide check started", self);
        if (!self.people.distinctId) {
            MixpanelDebug(@"%@ decide check skipped because no user has been identified", self);
            return;
        }

        NSMutableSet *newVariants = [NSMutableSet set];

        if (!useCache || !self.decideResponseCached) {
            MixpanelDebug(@"%@ decide cache not found, starting network request", self);

            NSData *peoplePropertiesJSON = [NSJSONSerialization dataWithJSONObject:self.people.automaticPeopleProperties options:0 error:nil];
            NSString *params = [NSString stringWithFormat:@"version=1&lib=iphone&token=%@&distinct_id=%@&properties=%@",
                                self.apiToken,
                                MPURLEncode(self.people.distinctId),
                                MPURLEncode([[NSString alloc] initWithData:peoplePropertiesJSON encoding:NSUTF8StringEncoding])
                                ];
            NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/decide?%@", self.decideURL, params]];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
            [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
            NSError *error = nil;
            NSURLResponse *urlResponse = nil;
            NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
            if (error) {
                NSLog(@"%@ decide check http error: %@", self, error);
                return;
            }
            NSDictionary *object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error) {
                NSLog(@"%@ decide check json error: %@, data: %@", self, error, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                return;
            }
            if (object[@"error"]) {
                MixpanelDebug(@"%@ decide check api error: %@", self, object[@"error"]);
                return;
            }

            NSArray *rawSurveys = object[@"surveys"];
            NSMutableArray *parsedSurveys = [NSMutableArray array];

            if (rawSurveys && [rawSurveys isKindOfClass:[NSArray class]]) {
                for (id obj in rawSurveys) {
                    MPSurvey *survey = [MPSurvey surveyWithJSONObject:obj];
                    if (survey) {
                        [parsedSurveys addObject:survey];
                    }
                }
            } else {
               MixpanelDebug(@"%@ survey check response format error: %@", self, object);
            }

            NSArray *rawNotifications = object[@"notifications"];
            NSMutableArray *parsedNotifications = [NSMutableArray array];

            if (rawNotifications && [rawNotifications isKindOfClass:[NSArray class]]) {
                for (id obj in rawNotifications) {
                    MPNotification *notification = [MPNotification notificationWithJSONObject:obj];
                    if (notification) {
                        [parsedNotifications addObject:notification];
                    }
                }
            } else {
                MixpanelDebug(@"%@ in-app notifs check response format error: %@", self, object);
            }

            NSArray *rawVariants = object[@"variants"];
            NSMutableSet *parsedVariants = [NSMutableSet set];
            if (rawVariants && [rawVariants isKindOfClass:[NSArray class]]) {
                for (id obj in rawVariants) {
                    MPVariant *variant = [MPVariant variantWithJSONObject:obj];
                    if (variant) {
                        [parsedVariants addObject:variant];
                    }
                }
            } else {
                MixpanelDebug(@"%@ variants check response format error: %@", self, object);
            }

            // Variants that are already running (may or may not have been marked as finished).
            NSSet *runningVariants = [NSSet setWithSet:[self.variants objectsPassingTest:^BOOL(MPVariant *var, BOOL *stop) { return var.running; }]];
            // Variants that are marked as finished, (may or may not be running still).
            NSSet *finishedVariants = [NSSet setWithSet:[self.variants objectsPassingTest:^BOOL(MPVariant *var, BOOL *stop) { return var.finished; }]];
            // Variants that are running that should be marked finished.
            NSMutableSet *toFinishVariants = [NSMutableSet setWithSet:runningVariants];
            [toFinishVariants minusSet:parsedVariants];
            // New variants that we just saw that are not already running.
            newVariants = [NSMutableSet setWithSet:parsedVariants];
            [newVariants minusSet:runningVariants];
            // Running variants that were marked finished, but have now started again.
            NSMutableSet *restartVariants = [NSMutableSet setWithSet:parsedVariants];
            [restartVariants intersectSet:runningVariants];
            [restartVariants intersectSet:finishedVariants];
            // All variants that we still care about (stopped are thrown out)
            NSMutableSet *allVariants = [NSMutableSet setWithSet:newVariants];
            [allVariants unionSet:runningVariants];

            [restartVariants makeObjectsPerformSelector:NSSelectorFromString(@"restart")];
            [toFinishVariants makeObjectsPerformSelector:NSSelectorFromString(@"finish")];

            self.surveys = [NSArray arrayWithArray:parsedSurveys];
            self.notifications = [NSArray arrayWithArray:parsedNotifications];
            self.variants = [allVariants copy];

            self.decideResponseCached = YES;
        } else {
            MixpanelDebug(@"%@ decide cache found, skipping network request", self);
        }

        NSArray *unseenSurveys = [self.surveys objectsAtIndexes:[self.surveys indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop){
            return [self.shownSurveyCollections member:@(((MPSurvey *)obj).collectionID)] == nil;
        }]];

        NSArray *unseenNotifications = [self.notifications objectsAtIndexes:[self.notifications indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            return [self.shownNotifications member:@(((MPNotification *)obj).ID)] == nil;
        }]];

        MixpanelDebug(@"%@ decide check found %lu available surveys out of %lu total: %@", self, (unsigned long)[unseenSurveys count], (unsigned long)[self.surveys count], unseenSurveys);
        MixpanelDebug(@"%@ decide check found %lu available notifs out of %lu total: %@", self, (unsigned long)[unseenNotifications count],
                      (unsigned long)[self.notifications count], unseenNotifications);
        MixpanelDebug(@"%@ decide check found %lu variants: %@", self, (unsigned long)[self.variants count], self.variants);

        if (completion) {
            completion(unseenSurveys, unseenNotifications, newVariants);
        }
    });
}

- (void)checkForSurveysWithCompletion:(void (^)(NSArray *surveys))completion
{
    [self checkForDecideResponseWithCompletion:^(NSArray *surveys, NSArray *notifications, NSSet *variants) {
        if (completion) {
            completion(surveys);
        }
    }];
}

- (void)checkForNotificationsWithCompletion:(void (^)(NSArray *notifications))completion
{
    [self checkForDecideResponseWithCompletion:^(NSArray *surveys, NSArray *notifications, NSSet *variants) {
        if (completion) {
            completion(notifications);
        }
    }];
}

- (void)checkForVariantsWithCompletion:(void (^)(NSSet *variants))completion
{
    [self checkForDecideResponseWithCompletion:^(NSArray *surveys, NSArray *notifications, NSSet *variants) {
        if (completion) {
            completion(variants);
        }
    } useCache:NO];
}

#pragma mark - Surveys

- (void)presentSurveyWithRootViewController:(MPSurvey *)survey
{
    UIViewController *presentingViewController = [Mixpanel topPresentedViewController];

    // This fixes the NSInternalInconsistencyException caused when we try present a
    // survey on a viewcontroller that is itself being presented.
    if (![presentingViewController isBeingPresented] && ![presentingViewController isBeingDismissed]) {

        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MPSurvey" bundle:nil];
        MPSurveyNavigationController *controller = [storyboard instantiateViewControllerWithIdentifier:@"MPSurveyNavigationController"];
        controller.survey = survey;
        controller.delegate = self;
        controller.backgroundImage = [presentingViewController.view mp_snapshotImage];
        [presentingViewController presentViewController:controller animated:YES completion:nil];
    }
}

- (void)showSurveyWithObject:(MPSurvey *)survey withAlert:(BOOL)showAlert
{
    if (survey) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.currentlyShowingSurvey) {
                MixpanelLog(@"%@ already showing survey: %@", self, self.currentlyShowingSurvey);
            } else if (self.currentlyShowingNotification) {
                MixpanelLog(@"%@ already showing in-app notification: %@", self, self.currentlyShowingNotification);
            } else {
                self.currentlyShowingSurvey = survey;
                if (showAlert) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000
                    if ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending) {
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"We'd love your feedback!" message:@"Mind taking a quick survey?" preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"No, Thanks" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                            if (self.currentlyShowingSurvey) {
                                [self markSurvey:self.currentlyShowingSurvey shown:NO withAnswerCount:0];
                                self.currentlyShowingSurvey = nil;
                            }
                        }]];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Sure" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            if (self.currentlyShowingSurvey) {
                                [self presentSurveyWithRootViewController:self.currentlyShowingSurvey];
                            }
                        }]];
                        [[Mixpanel topPresentedViewController] presentViewController:alert animated:YES completion:nil];
                    } else {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"We'd love your feedback!"
                                                                        message:@"Mind taking a quick survey?"
                                                                       delegate:self
                                                              cancelButtonTitle:@"No, Thanks"
                                                              otherButtonTitles:@"Sure", nil];
                        [alert show];
                    }
#else
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"We'd love your feedback!"
                                                                    message:@"Mind taking a quick survey?"
                                                                   delegate:self
                                                          cancelButtonTitle:@"No, Thanks"
                                                          otherButtonTitles:@"Sure", nil];
                    [alert show];
#endif
                } else {
                    [self presentSurveyWithRootViewController:survey];
                }
            }
        });
    } else {
        NSLog(@"%@ cannot show nil survey", self);
    }
}

- (void)showSurveyWithObject:(MPSurvey *)survey
{
    [self showSurveyWithObject:survey withAlert:NO];
}

- (void)showSurvey
{
    [self checkForSurveysWithCompletion:^(NSArray *surveys){
        if ([surveys count] > 0) {
            [self showSurveyWithObject:surveys[0]];
        }
    }];
}

- (void)showSurveyWithID:(NSUInteger)ID
{
    [self checkForSurveysWithCompletion:^(NSArray *surveys){
        for (MPSurvey *survey in surveys) {
            if (survey.ID == ID) {
                [self showSurveyWithObject:survey];
                break;
            }
        }
    }];
}

- (void)markSurvey:(MPSurvey *)survey shown:(BOOL)shown withAnswerCount:(NSUInteger)count
{
    MixpanelDebug(@"%@ marking survey shown: %@, %@", self, @(survey.collectionID), _shownSurveyCollections);
    [_shownSurveyCollections addObject:@(survey.collectionID)];
    [self.people append:@{@"$surveys": @(survey.ID), @"$collections": @(survey.collectionID)}];

    if (![survey.name isEqualToString:@"$ignore"]) {
        [self track:@"$show_survey" properties:@{@"survey_id": @(survey.ID),
                                                 @"collection_id": @(survey.collectionID),
                                                 @"$survey_shown": @(shown),
                                                 @"$answer_count": @(count)
                                                 }];
    }
}

- (void)surveyController:(MPSurveyNavigationController *)controller wasDismissedWithAnswers:(NSArray *)answers
{
    [controller.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    self.currentlyShowingSurvey = nil;
    if ([controller.survey.name isEqualToString:@"$ignore"]) {
        MixpanelDebug(@"%@ not sending survey %@ result", self, controller.survey);
    } else {
        [self markSurvey:controller.survey shown:YES withAnswerCount:[answers count]];
        for (NSUInteger i = 0, n = [answers count]; i < n; i++) {
            if (i == 0) {
                [self.people append:@{@"$answers": answers[i], @"$responses": @(controller.survey.collectionID)}];
            } else {
                [self.people append:@{@"$answers": answers[i]}];
            }
        }
    }
}

#pragma mark Surveys (UIAlertViewDelegate)

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (_currentlyShowingSurvey) {
        if (buttonIndex == 1) {
            [self presentSurveyWithRootViewController:_currentlyShowingSurvey];
        } else {
            [self markSurvey:_currentlyShowingSurvey shown:NO withAnswerCount:0];
            self.currentlyShowingSurvey = nil;
        }
    }
}

#pragma mark - Notifications

- (void)showNotification
{
    [self checkForNotificationsWithCompletion:^(NSArray *notifications) {
        if ([notifications count] > 0) {
            [self showNotificationWithObject:notifications[0]];
        }
    }];
}

- (void)showNotificationWithType:(NSString *)type
{
    [self checkForNotificationsWithCompletion:^(NSArray *notifications) {
        if (type != nil) {
            for (MPNotification *notification in notifications) {
                if ([notification.type isEqualToString:type]) {
                    [self showNotificationWithObject:notification];
                    break;
                }
            }
        }
    }];
}

- (void)showNotificationWithID:(NSUInteger)ID
{
    [self checkForNotificationsWithCompletion:^(NSArray *notifications) {
        for (MPNotification *notification in notifications) {
            if (notification.ID == ID) {
                [self showNotificationWithObject:notification];
                break;
            }
        }
    }];
}

- (void)showNotificationWithObject:(MPNotification *)notification
{
    NSData *image = notification.image;

    // if images fail to load, remove the notification from the queue
    if (!image) {
        NSMutableArray *notifications = [NSMutableArray arrayWithArray:_notifications];
        [notifications removeObject:notification];
        self.notifications = [NSArray arrayWithArray:notifications];
        return;
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.currentlyShowingNotification) {
            MixpanelLog(@"%@ already showing in-app notification: %@", self, self.currentlyShowingNotification);
        } else if (self.currentlyShowingSurvey) {
            MixpanelLog(@"%@ already showing survey: %@", self, self.currentlyShowingSurvey);
        } else {
            self.currentlyShowingNotification = notification;
            BOOL shown = false;
            if ([notification.type isEqualToString:MPNotificationTypeMini]) {
                shown = [self showMiniNotificationWithObject:notification];
            } else {
                shown = [self showTakeoverNotificationWithObject:notification];
            }

            if (shown && ![notification.title isEqualToString:@"$ignore"]) {
                [self markNotificationShown:notification];
            }
        }
    });
}

- (BOOL)showTakeoverNotificationWithObject:(MPNotification *)notification
{
    UIViewController *presentingViewController = [Mixpanel topPresentedViewController];

    if (![presentingViewController isBeingPresented] && ![presentingViewController isBeingDismissed]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MPNotification" bundle:nil];
        MPTakeoverNotificationViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"MPNotificationViewController"];

        controller.backgroundImage = [presentingViewController.view mp_snapshotImage];
        controller.notification = notification;
        controller.delegate = self;
        self.notificationViewController = controller;

        [presentingViewController presentViewController:controller animated:NO completion:nil];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)showMiniNotificationWithObject:(MPNotification *)notification
{
    MPMiniNotificationViewController *controller = [[MPMiniNotificationViewController alloc] init];
    controller.notification = notification;
    controller.delegate = self;
    self.notificationViewController = controller;

    [controller showWithAnimation];

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.miniNotificationPresentationTime * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self notificationController:controller wasDismissedWithStatus:NO];
    });
    return YES;
}

- (void)notificationController:(MPNotificationViewController *)controller wasDismissedWithStatus:(BOOL)status
{
    if (controller == nil || self.currentlyShowingNotification != controller.notification) {
        return;
    }

    void (^completionBlock)()  = ^void(){
        self.currentlyShowingNotification = nil;
        self.notificationViewController = nil;
    };

    if (status && controller.notification.callToActionURL) {
        MixpanelDebug(@"%@ opening URL %@", self, controller.notification.callToActionURL);
        BOOL success = [[UIApplication sharedApplication] openURL:controller.notification.callToActionURL];

        [controller hideWithAnimation:!success completion:completionBlock];

        if (!success) {
            NSLog(@"Mixpanel failed to open given URL: %@", controller.notification.callToActionURL);
        }

        [self trackNotification:controller.notification event:@"$campaign_open"];
    } else {
        [controller hideWithAnimation:YES completion:completionBlock];
    }
}

- (void)trackNotification:(MPNotification *)notification event:(NSString *)event
{
    if (![notification.title isEqualToString:@"$ignore"]) {
        [self track:event properties:@{@"campaign_id": @(notification.ID),
                                       @"message_id": @(notification.messageID),
                                       @"message_type": @"inapp",
                                       @"message_subtype": notification.type}];
    } else {
        MixpanelDebug(@"%@ ignoring notif track for %@, %@", self, @(notification.ID), event);
    }
}

- (void)markNotificationShown:(MPNotification *)notification
{
    MixpanelDebug(@"%@ marking notification shown: %@, %@", self, @(notification.ID), _shownNotifications);

    [_shownNotifications addObject:@(notification.ID)];

    NSDictionary *properties = @{
                                 @"$campaigns": @(notification.ID),
                                 @"$notifications": @{
                                         @"campaign_id": @(notification.ID),
                                         @"message_id": @(notification.messageID),
                                         @"type": @"inapp",
                                         @"time": [NSDate date]
                                         }
                                 };

    [self.people append:properties];

    [self trackNotification:notification event:@"$campaign_delivery"];
}

#pragma mark - A/B Testing (Designer)

- (void)connectGestureRecognized:(id)sender
{
    if(!sender || ([sender isKindOfClass:[UIGestureRecognizer class]] && ((UIGestureRecognizer *)sender).state == UIGestureRecognizerStateBegan )) {
        [self connectToABTestDesigner];
    }
}

- (void)connectToABTestDesigner
{
    if (self.abtestDesignerConnection && self.abtestDesignerConnection.connected) {
        NSLog(@"A/B test designer connection already exists");
    } else {
        NSString *designerURLString = [NSString stringWithFormat:@"%@/connect?key=%@&type=device", self.switchboardURL, self.apiToken];
        NSURL *designerURL = [NSURL URLWithString:designerURLString];
        __weak Mixpanel *weakSelf = self;
        self.abtestDesignerConnection = [[MPABTestDesignerConnection alloc] initWithURL:designerURL
                                                                        connectCallback:^{
                                                                            __strong Mixpanel *strongSelf = weakSelf;
                                                                            if (strongSelf) {
                                                                                for (MPVariant *variant in self.variants) {
                                                                                    [variant stop];
                                                                                }
                                                                            }
                                                                        }
                                                                        disconnectCallback:^{
                                                                            __strong Mixpanel *strongSelf = weakSelf;
                                                                            if (strongSelf) {
                                                                                for (MPVariant *variant in self.variants) {
                                                                                    [variant execute];
                                                                                }
                                                                            }
                                                                        }];
    }
}

#pragma mark A/B Testing (Experiment)

- (void)executeCachedVariants {
    for (MPVariant *variant in self.variants) {
        NSAssert(!variant.running, @"Variant should not be running at this point");
        [variant execute];
    }
}

- (void)markVariantRun:(MPVariant *)variant
{
    MixpanelDebug(@"%@ marking variant %@ shown for experiment %@", self, @(variant.ID), @(variant.experimentID));
    NSDictionary *shownVariant = @{[@(variant.experimentID) stringValue]: @(variant.ID)};
    [self track:@"$experiment_started" properties:@{@"$experiment_id" : @(variant.experimentID), @"$variant_id": @(variant.ID)}];
    [self.people merge:@{@"$experiments": shownVariant}];

    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *superProperties = [NSMutableDictionary dictionaryWithDictionary:self.superProperties];
        NSMutableDictionary *shownVariants = [NSMutableDictionary dictionaryWithDictionary: superProperties[@"$experiments"]];
        [shownVariants addEntriesFromDictionary:shownVariant];
        [superProperties addEntriesFromDictionary:@{@"$experiments": [shownVariants copy]}];
        self.superProperties = [superProperties copy];
        NSLog(@"Super properties are now %@", self.superProperties);
        if ([Mixpanel inBackground]) {
            [self archiveProperties];
        }
    });
}

- (void)joinExperiments
{
    [self checkForVariantsWithCompletion:^(NSSet *newVariants) {
        for (MPVariant *variant in newVariants) {
            [variant execute];
            [self markVariantRun:variant];
        }
    }];
}

@end

#pragma mark - People

@implementation MixpanelPeople

- (id)initWithMixpanel:(Mixpanel *)mixpanel
{
    if (self = [self init]) {
        self.mixpanel = mixpanel;
        self.unidentifiedQueue = [NSMutableArray array];
        self.automaticPeopleProperties = [self collectAutomaticPeopleProperties];
    }
    return self;
}

- (NSString *)description
{
    __strong Mixpanel *strongMixpanel = _mixpanel;
    return [NSString stringWithFormat:@"<MixpanelPeople: %p %@>", self, (strongMixpanel ? strongMixpanel.apiToken : @"")];
}

- (NSDictionary *)collectAutomaticPeopleProperties
{
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    __strong Mixpanel *strongMixpanel = _mixpanel;
    [p setValue:[strongMixpanel deviceModel] forKey:@"$ios_device_model"];
    [p setValue:[[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"] forKey:@"$ios_app_version"];
    [p setValue:[[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] forKey:@"$ios_app_release"];
    [p setValue:[strongMixpanel IFA] forKey:@"$ios_ifa"];
    [p addEntriesFromDictionary:@{@"$ios_version": [[UIDevice currentDevice] systemVersion],
                                 @"$ios_lib_version": VERSION,
                                  }];
    return [p copy];
}

- (void)addPeopleRecordToQueueWithAction:(NSString *)action andProperties:(NSDictionary *)properties
{
    properties = [properties copy];
    NSNumber *epochMilliseconds = @(round([[NSDate date] timeIntervalSince1970] * 1000));
    __strong Mixpanel *strongMixpanel = _mixpanel;
    if (strongMixpanel) {
        dispatch_async(strongMixpanel.serialQueue, ^{
            NSMutableDictionary *r = [NSMutableDictionary dictionary];
            NSMutableDictionary *p = [NSMutableDictionary dictionary];
            r[@"$token"] = strongMixpanel.apiToken;
            if (!r[@"$time"]) {
                // milliseconds unix timestamp
                r[@"$time"] = epochMilliseconds;
            }
            if ([action isEqualToString:@"$set"] || [action isEqualToString:@"$set_once"]) {
                [p addEntriesFromDictionary:self.automaticPeopleProperties];
            }
            [p addEntriesFromDictionary:properties];
            r[action] = [NSDictionary dictionaryWithDictionary:p];
            if (self.distinctId) {
                r[@"$distinct_id"] = self.distinctId;
                MixpanelLog(@"%@ queueing people record: %@", self.mixpanel, r);
                [strongMixpanel.peopleQueue addObject:r];
                if ([strongMixpanel.peopleQueue count] > 500) {
                    [strongMixpanel.peopleQueue removeObjectAtIndex:0];
                }
            } else {
                MixpanelLog(@"%@ queueing unidentified people record: %@", self.mixpanel, r);
                [self.unidentifiedQueue addObject:r];
                if ([self.unidentifiedQueue count] > 500) {
                    [self.unidentifiedQueue removeObjectAtIndex:0];
                }
            }
            if ([Mixpanel inBackground]) {
                [strongMixpanel archivePeople];
            }
        });
    }
}

#pragma mark - Public API

- (void)addPushDeviceToken:(NSData *)deviceToken
{
    const unsigned char *buffer = (const unsigned char *)[deviceToken bytes];
    if (!buffer) {
        return;
    }
    NSMutableString *hex = [NSMutableString stringWithCapacity:(deviceToken.length * 2)];
    for (NSUInteger i = 0; i < deviceToken.length; i++) {
        [hex appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)buffer[i]]];
    }
    NSArray *tokens = @[[NSString stringWithString:hex]];
    NSDictionary *properties = @{@"$ios_devices": tokens};
    [self addPeopleRecordToQueueWithAction:@"$union" andProperties:properties];
}

- (void)set:(NSDictionary *)properties
{
    NSAssert(properties != nil, @"properties must not be nil");
    [Mixpanel assertPropertyTypes:properties];
    [self addPeopleRecordToQueueWithAction:@"$set" andProperties:properties];
}

- (void)set:(NSString *)property to:(id)object
{
    NSAssert(property != nil, @"property must not be nil");
    NSAssert(object != nil, @"object must not be nil");
    if (property == nil || object == nil) {
        return;
    }
    [self set:@{property: object}];
}

- (void)setOnce:(NSDictionary *)properties
{
    NSAssert(properties != nil, @"properties must not be nil");
    [Mixpanel assertPropertyTypes:properties];
    [self addPeopleRecordToQueueWithAction:@"$set_once" andProperties:properties];
}

- (void)increment:(NSDictionary *)properties
{
    NSAssert(properties != nil, @"properties must not be nil");
    for (id __unused v in [properties allValues]) {
        NSAssert([v isKindOfClass:[NSNumber class]],
                 @"%@ increment property values should be NSNumber. found: %@", self, v);
    }
    [self addPeopleRecordToQueueWithAction:@"$add" andProperties:properties];
}

- (void)increment:(NSString *)property by:(NSNumber *)amount
{
    NSAssert(property != nil, @"property must not be nil");
    NSAssert(amount != nil, @"amount must not be nil");
    if (property == nil || amount == nil) {
        return;
    }
    [self increment:@{property: amount}];
}

- (void)append:(NSDictionary *)properties
{
    NSAssert(properties != nil, @"properties must not be nil");
    [Mixpanel assertPropertyTypes:properties];
    [self addPeopleRecordToQueueWithAction:@"$append" andProperties:properties];
}

- (void)union:(NSDictionary *)properties
{
    NSAssert(properties != nil, @"properties must not be nil");
    for (id __unused v in [properties allValues]) {
        NSAssert([v isKindOfClass:[NSArray class]],
                 @"%@ union property values should be NSArray. found: %@", self, v);
    }
    [self addPeopleRecordToQueueWithAction:@"$union" andProperties:properties];
}

- (void)merge:(NSDictionary *)properties
{
    NSAssert(properties != nil, @"properties must not be nil");
    [self addPeopleRecordToQueueWithAction:@"$merge" andProperties:properties];
}

- (void)trackCharge:(NSNumber *)amount
{
    [self trackCharge:amount withProperties:nil];
}

- (void)trackCharge:(NSNumber *)amount withProperties:(NSDictionary *)properties
{
    NSAssert(amount != nil, @"amount must not be nil");
    if (amount != nil) {
        NSMutableDictionary *txn = [NSMutableDictionary dictionaryWithObjectsAndKeys:amount, @"$amount", [NSDate date], @"$time", nil];
        if (properties) {
            [txn addEntriesFromDictionary:properties];
        }
        [self append:@{@"$transactions": txn}];
    }
}

- (void)clearCharges
{
    [self set:@{@"$transactions": @[]}];
}

- (void)deleteUser
{
    [self addPeopleRecordToQueueWithAction:@"$delete" andProperties:@{}];
}

@end
