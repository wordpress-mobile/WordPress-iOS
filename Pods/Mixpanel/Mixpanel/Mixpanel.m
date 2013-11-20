//
// Mixpanel.m
// Mixpanel
//
// Copyright 2012 Mixpanel
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include <arpa/inet.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <sys/socket.h>
#include <sys/sysctl.h>

#import <AdSupport/ASIdentifierManager.h>
#import <CommonCrypto/CommonDigest.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import "MPCJSONDataSerializer.h"
#import "Mixpanel.h"
#import "NSData+MPBase64.h"
#import "ODIN.h"

#define VERSION @"2.0.4"

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

@interface Mixpanel () {
    NSUInteger _flushInterval;
}

// re-declare internally as readwrite
@property(atomic,retain)    MixpanelPeople *people;
@property(atomic,copy)      NSString *distinctId;

@property(nonatomic,copy)   NSString *apiToken;
@property(atomic,retain)    NSDictionary *superProperties;
@property(nonatomic,retain) NSMutableDictionary *automaticProperties; // mutable because we update $wifi when reachability changes
@property(nonatomic,retain) NSTimer *timer;
@property(nonatomic,retain) NSMutableArray *eventsQueue;
@property(nonatomic,retain) NSMutableArray *peopleQueue;
@property(nonatomic,assign) UIBackgroundTaskIdentifier taskId;
@property(nonatomic,assign) dispatch_queue_t serialQueue;
@property(nonatomic,assign) SCNetworkReachabilityRef reachability;
@property(nonatomic,retain) NSDateFormatter *dateFormatter;

@end

@interface MixpanelPeople ()

@property(nonatomic,assign) Mixpanel *mixpanel;
@property(nonatomic,retain) NSMutableArray *unidentifiedQueue;
@property(nonatomic,copy)   NSString *distinctId;
@property(nonatomic,retain) NSDictionary *automaticProperties;

- (id)initWithMixpanel:(Mixpanel *)mixpanel;

@end

@implementation Mixpanel

static void MixpanelReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
    if (info != NULL && [(NSObject*)info isKindOfClass:[Mixpanel class]]) {
        @autoreleasepool {
            Mixpanel *mixpanel = (Mixpanel *)info;
            [mixpanel reachabilityChanged:flags];
        }
    } else {
        NSLog(@"Mixpanel reachability callback received unexpected info object");
    }
}

static Mixpanel *sharedInstance = nil;

+ (Mixpanel *)sharedInstanceWithToken:(NSString *)apiToken
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc] initWithToken:apiToken andFlushInterval:60];
    });
    return sharedInstance;
}

+ (Mixpanel *)sharedInstance
{
    if (sharedInstance == nil) {
        NSLog(@"%@ warning sharedInstance called before sharedInstanceWithToken:", self);
    }
    return sharedInstance;
}

- (instancetype)initWithToken:(NSString *)apiToken andFlushInterval:(NSUInteger)flushInterval
{
    if (apiToken == nil) {
        apiToken = @"";
    }
    if ([apiToken length] == 0) {
        NSLog(@"%@ warning empty api token", self);
    }
    if (self = [self init]) {
        self.people = [[[MixpanelPeople alloc] initWithMixpanel:self] autorelease];
        self.apiToken = apiToken;
        self.flushInterval = flushInterval;
        self.flushOnBackground = YES;
        self.showNetworkActivityIndicator = YES;
        self.serverURL = @"https://api.mixpanel.com";
        self.distinctId = [self defaultDistinctId];
        self.superProperties = [NSMutableDictionary dictionary];
        self.automaticProperties = [self collectAutomaticProperties];
        self.eventsQueue = [NSMutableArray array];
        self.peopleQueue = [NSMutableArray array];
        self.taskId = UIBackgroundTaskInvalid;
        NSString *label = [NSString stringWithFormat:@"com.mixpanel.%@.%p", apiToken, self];
        self.serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        BOOL reachabilityOk = NO;
        if ((self.reachability = SCNetworkReachabilityCreateWithName(NULL, "api.mixpanel.com")) != NULL) {
            SCNetworkReachabilityContext context = {0, NULL, NULL, NULL, NULL};
            context.info = (void *)self;
            if (SCNetworkReachabilitySetCallback(self.reachability, MixpanelReachabilityCallback, &context)) {
                if (SCNetworkReachabilitySetDispatchQueue(self.reachability, self.serialQueue)) {
                    reachabilityOk = YES;
                    MixpanelDebug(@"%@ successfully set up reachability callback", self);
                } else {
                    // cleanup callback if setting dispatch queue failed
                    SCNetworkReachabilitySetCallback(self.reachability, NULL, NULL);
                }
            }
        }
        if (!reachabilityOk) {
            NSLog(@"%@ failed to set up reachability callback: %s", self, SCErrorString(SCError()));
        }
        self.dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [self.dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];
        [self.dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
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
        [self unarchive];
        [self startFlushTimer];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.people = nil;
    self.distinctId = nil;
    self.nameTag = nil;
    self.serverURL = nil;
    self.delegate = nil;
    self.apiToken = nil;
    self.superProperties = nil;
    self.automaticProperties = nil;
    self.timer = nil;
    self.eventsQueue = nil;
    self.peopleQueue = nil;
    self.dateFormatter = nil;
    if (self.reachability) {
        SCNetworkReachabilitySetCallback(self.reachability, NULL, NULL);
        SCNetworkReachabilitySetDispatchQueue(self.reachability, NULL);
        self.reachability = nil;
    }
    if (self.serialQueue) {
        dispatch_release(self.serialQueue);
        self.serialQueue = nil;
    }
    [super dealloc];
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
    NSString *results = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
    return results;
}

- (NSMutableDictionary *)collectAutomaticProperties
{
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    UIDevice *device = [UIDevice currentDevice];
    NSString *deviceModel = [self deviceModel];
    [p setValue:@"iphone" forKey:@"mp_lib"];
    [p setValue:VERSION forKey:@"$lib_version"];
    [p setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"$app_version"];
    [p setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] forKey:@"$app_release"];
    [p setValue:@"Apple" forKey:@"$manufacturer"];
    [p setValue:[device systemName] forKey:@"$os"];
    [p setValue:[device systemVersion] forKey:@"$os_version"];
    [p setValue:deviceModel forKey:@"$model"];
    [p setValue:deviceModel forKey:@"mp_device_model"]; // legacy
    CGSize size = [UIScreen mainScreen].bounds.size;
    [p setValue:[NSNumber numberWithInt:(int)size.height] forKey:@"$screen_height"];
    [p setValue:[NSNumber numberWithInt:(int)size.width] forKey:@"$screen_width"];
    CTTelephonyNetworkInfo *networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier *carrier = [networkInfo subscriberCellularProvider];
    [networkInfo release];
    if (carrier.carrierName.length) {
        [p setValue:carrier.carrierName forKey:@"$carrier"];
    }
    if (NSClassFromString(@"ASIdentifierManager")) {
        [p setValue:[[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString] forKey:@"$ios_ifa"];
    }
    return p;
}

+ (BOOL)inBackground
{
    return [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
}

#pragma mark - Encoding/decoding utilities

- (NSData *)JSONSerializeObject:(id)obj
{
    id coercedObj = [self JSONSerializableObjectForObject:obj];
    MPCJSONDataSerializer *serializer = [MPCJSONDataSerializer serializer];
    NSError *error = nil;
    NSData *data = nil;
    @try {
        data = [serializer serializeObject:coercedObj error:&error];
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
            id v = [self JSONSerializableObjectForObject:[obj objectForKey:key]];
            [d setObject:v forKey:stringKey];
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
        b64String = (id)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                (CFStringRef)b64String,
                                                                NULL,
                                                                CFSTR("!*'();:@&=+$,/?%#[]"),
                                                                kCFStringEncodingUTF8);
    }
    return [b64String autorelease];
}

#pragma mark - Tracking

+ (void)assertPropertyTypes:(NSDictionary *)properties
{
    for (id k in properties) {
        NSAssert([k isKindOfClass: [NSString class]], @"%@ property keys must be NSString. got: %@ %@", self, [k class], k);
        // would be convenient to do: id v = [properties objectForKey:k]; but
        // when the NSAssert's are stripped out in release, it becomes an
        // unused variable error. also, note that @YES and @NO pass as
        // instances of NSNumber class.
        NSAssert([[properties objectForKey:k] isKindOfClass:[NSString class]] ||
                 [[properties objectForKey:k] isKindOfClass:[NSNumber class]] ||
                 [[properties objectForKey:k] isKindOfClass:[NSNull class]] ||
                 [[properties objectForKey:k] isKindOfClass:[NSArray class]] ||
                 [[properties objectForKey:k] isKindOfClass:[NSDictionary class]] ||
                 [[properties objectForKey:k] isKindOfClass:[NSDate class]] ||
                 [[properties objectForKey:k] isKindOfClass:[NSURL class]],
                 @"%@ property values must be NSString, NSNumber, NSNull, NSArray, NSDictionary, NSDate or NSURL. got: %@ %@", self, [[properties objectForKey:k] class], [properties objectForKey:k]);
    }
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
                [r setObject:distinctId forKey:@"$distinct_id"];
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

- (NSString *)defaultDistinctId
{
    NSString *distinctId = nil;
    if (NSClassFromString(@"ASIdentifierManager")) {
        distinctId = [[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString];
    }
    if (!distinctId) {
        distinctId = ODIN1();
    }
    if (!distinctId) {
        NSLog(@"%@ error getting default distinct id: both iOS IFA and ODIN1 failed", self);
    }
    return distinctId;
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
    [Mixpanel assertPropertyTypes:properties];
    NSNumber *epochSeconds = @(round([[NSDate date] timeIntervalSince1970]));
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *p = [NSMutableDictionary dictionary];
        [p addEntriesFromDictionary:self.automaticProperties];
        [p setObject:self.apiToken forKey:@"token"];
        [p setObject:epochSeconds forKey:@"time"];
        if (self.nameTag) {
            [p setObject:self.nameTag forKey:@"mp_name_tag"];
        }
        if (self.distinctId) {
            [p setObject:self.distinctId forKey:@"distinct_id"];
        }
        [p addEntriesFromDictionary:self.superProperties];
        if (properties) {
            [p addEntriesFromDictionary:properties];
        }
        NSDictionary *e = [NSDictionary dictionaryWithObjectsAndKeys:event, @"event", [NSDictionary dictionaryWithDictionary:p], @"properties", nil];
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
    [Mixpanel assertPropertyTypes:properties];
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:self.superProperties];
        for (NSString *key in properties) {
            if ([tmp objectForKey:key] == nil) {
                [tmp setObject:[properties objectForKey:key] forKey:key];
            }
        }
        self.superProperties = [NSDictionary dictionaryWithDictionary:tmp];
        if ([Mixpanel inBackground]) {
            [self archiveProperties];
        }
    });
}

- (void)registerSuperPropertiesOnce:(NSDictionary *)properties defaultValue:(id)defaultValue
{
    [Mixpanel assertPropertyTypes:properties];
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:self.superProperties];
        for (NSString *key in properties) {
            id value = [tmp objectForKey:key];
            if (value == nil || [value isEqual:defaultValue]) {
                [tmp setObject:[properties objectForKey:key] forKey:key];
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
        if ([tmp objectForKey:propertyName] != nil) {
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
        self.superProperties = [NSDictionary dictionary];
        if ([Mixpanel inBackground]) {
            [self archiveProperties];
        }
    });
}

- (NSDictionary *)currentSuperProperties
{
    return [[self.superProperties copy] autorelease];
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
        [self archiveFromSerialQueue];
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

        if ([self.delegate respondsToSelector:@selector(mixpanelWillFlush:)] && ![self.delegate mixpanelWillFlush:self]) {
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
            endpoint:@"/track/"
       batchComplete:^{
           [self archiveEvents];
       }];
}

- (void)flushPeople
{
    [self flushQueue:_peopleQueue
            endpoint:@"/engage/"
       batchComplete:^{
           [self archivePeople];
       }];
}

- (void)flushQueue:(NSMutableArray *)queue endpoint:(NSString *)endpoint batchComplete:(void(^)())batchCompleteCallback
{
    while ([queue count] > 0) {
        NSArray *batch = [queue subarrayWithRange:NSMakeRange(0, MIN(50U, [queue count]))];

        NSString *requestData = [self encodeAPIData:batch];
        NSString *postBody = [NSString stringWithFormat:@"ip=1&data=%@", requestData];
        MixpanelDebug(@"%@ flushing %lu of %lu to %@: %@", self, (unsigned long)[batch count], (unsigned long)[queue count], endpoint, queue);
        NSURLRequest *request = [self apiRequestWithEndpoint:endpoint andBody:postBody];
        NSError *error = nil;

        [self updateNetworkActivityIndicator:YES];

        NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error];

        [self updateNetworkActivityIndicator:NO];

        if (error) {
            NSLog(@"%@ network failure: %@", self, error);
            break;
        }

        NSString *response = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
        if ([response intValue] == 0) {
            NSLog(@"%@ %@ api rejected some items", self, endpoint);
        };

        [queue removeObjectsInArray:batch];
        batchCompleteCallback();
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
    dispatch_async(self.serialQueue, ^{
        BOOL wifi = (flags & kSCNetworkReachabilityFlagsReachable) && !(flags & kSCNetworkReachabilityFlagsIsWWAN);
        self.automaticProperties[@"$wifi"] = wifi ? @YES : @NO;
    });
}

- (NSURLRequest *)apiRequestWithEndpoint:(NSString *)endpoint andBody:(NSString *)body
{
    NSURL *url = [NSURL URLWithString:[self.serverURL stringByAppendingString:endpoint]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    MixpanelDebug(@"%@ http request: %@?%@", self, url, body);
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

- (void)archive
{
   // Must archive from the serial queue to avoid conflicts from data mutation
   dispatch_sync(self.serialQueue, ^{
      [self archiveFromSerialQueue];
   });
}

- (void)archiveFromSerialQueue
{
    [self archiveEvents];
    [self archivePeople];
    [self archiveProperties];
}

- (void)archiveEvents
{
    NSString *filePath = [self eventsFilePath];
    MixpanelDebug(@"%@ archiving events data to %@: %@", self, filePath, self.eventsQueue);
    if (![NSKeyedArchiver archiveRootObject:self.eventsQueue toFile:filePath]) {
        NSLog(@"%@ unable to archive events data", self);
    }
}

- (void)archivePeople
{
    NSString *filePath = [self peopleFilePath];
    MixpanelDebug(@"%@ archiving people data to %@: %@", self, filePath, self.peopleQueue);
    if (![NSKeyedArchiver archiveRootObject:self.peopleQueue toFile:filePath]) {
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
    MixpanelDebug(@"%@ archiving properties data to %@: %@", self, filePath, p);
    if (![NSKeyedArchiver archiveRootObject:p toFile:filePath]) {
        NSLog(@"%@ unable to archive properties data", self);
    }
}

- (void)unarchive
{
    [self unarchiveEvents];
    [self unarchivePeople];
    [self unarchiveProperties];
}

- (void)unarchiveEvents
{
    NSString *filePath = [self eventsFilePath];
    @try {
        self.eventsQueue = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        MixpanelDebug(@"%@ unarchived events data: %@", self, self.eventsQueue);
    }
    @catch (NSException *exception) {
        NSLog(@"%@ unable to unarchive events data, starting fresh", self);
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        self.eventsQueue = nil;
    }
    if (!self.eventsQueue) {
        self.eventsQueue = [NSMutableArray array];
    }
}

- (void)unarchivePeople
{
    NSString *filePath = [self peopleFilePath];
    @try {
        self.peopleQueue = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        MixpanelDebug(@"%@ unarchived people data: %@", self, self.peopleQueue);
    }
    @catch (NSException *exception) {
        NSLog(@"%@ unable to unarchive people data, starting fresh", self);
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        self.peopleQueue = nil;
    }
    if (!self.peopleQueue) {
        self.peopleQueue = [NSMutableArray array];
    }
}

- (void)unarchiveProperties
{
    NSString *filePath = [self propertiesFilePath];
    NSDictionary *properties = nil;
    @try {
        properties = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        MixpanelDebug(@"%@ unarchived properties data: %@", self, properties);
    }
    @catch (NSException *exception) {
        NSLog(@"%@ unable to unarchive properties data, starting fresh", self);
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    if (properties) {
        self.distinctId = [properties objectForKey:@"distinctId"];
        self.nameTag = [properties objectForKey:@"nameTag"];
        self.superProperties = [properties objectForKey:@"superProperties"];
        self.people.distinctId = [properties objectForKey:@"peopleDistinctId"];
        self.people.unidentifiedQueue = [properties objectForKey:@"peopleUnidentifiedQueue"];
    }
}

#pragma mark - UIApplication notifications

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    MixpanelDebug(@"%@ application did become active", self);
    [self startFlushTimer];
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    MixpanelDebug(@"%@ application will resign active", self);
    [self stopFlushTimer];
}

- (void)applicationDidEnterBackground:(NSNotificationCenter *)notification
{
    MixpanelDebug(@"%@ did enter background", self);

    self.taskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        MixpanelDebug(@"%@ flush %lu cut short", self, (unsigned long)self.taskId);
        [[UIApplication sharedApplication] endBackgroundTask:self.taskId];
        self.taskId = UIBackgroundTaskInvalid;
    }];
    MixpanelDebug(@"%@ starting background cleanup task %lu", self, (unsigned long)self.taskId);

    [self archive];
    if (self.flushOnBackground) {
        [self flush];
    }
    dispatch_async(_serialQueue, ^{
        MixpanelDebug(@"%@ ending background cleanup task %lu", self, (unsigned long)self.taskId);
        if (self.taskId != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self.taskId];
            self.taskId = UIBackgroundTaskInvalid;
        }
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
    [self archive];
}

@end

@implementation MixpanelPeople

- (id)initWithMixpanel:(Mixpanel *)mixpanel
{
    if (self = [self init]) {
        self.mixpanel = mixpanel;
        self.unidentifiedQueue = [NSMutableArray array];
        self.automaticProperties = [self collectAutomaticProperties];
    }
    return self;
}

- (void)dealloc
{
    self.mixpanel = nil;
    self.distinctId = nil;
    self.unidentifiedQueue = nil;
    self.automaticProperties = nil;
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<MixpanelPeople: %p %@>", self, self.mixpanel.apiToken];
}

- (NSDictionary *)collectAutomaticProperties
{
    UIDevice *device = [UIDevice currentDevice];
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    [p setValue:[self.mixpanel deviceModel] forKey:@"$ios_device_model"];
    [p setValue:[device systemVersion] forKey:@"$ios_version"];
    [p setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] forKey:@"$ios_app_version"];
    [p setValue:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] forKey:@"$ios_app_release"];
    if (NSClassFromString(@"ASIdentifierManager")) {
        [p setValue:[[ASIdentifierManager sharedManager].advertisingIdentifier UUIDString] forKey:@"$ios_ifa"];
    }
    return [NSDictionary dictionaryWithDictionary:p];
}

- (void)addPeopleRecordToQueueWithAction:(NSString *)action andProperties:(NSDictionary *)properties
{
    NSNumber *epochMilliseconds = @(round([[NSDate date] timeIntervalSince1970] * 1000));
    dispatch_async(self.mixpanel.serialQueue, ^{
        NSMutableDictionary *r = [NSMutableDictionary dictionary];
        NSMutableDictionary *p = [NSMutableDictionary dictionary];
        [r setObject:self.mixpanel.apiToken forKey:@"$token"];
        if (![r objectForKey:@"$time"]) {
            // milliseconds unix timestamp
            [r setObject:epochMilliseconds forKey:@"$time"];
        }
        if ([action isEqualToString:@"$set"] || [action isEqualToString:@"$set_once"]) {
            [p addEntriesFromDictionary:self.automaticProperties];
        }
        [p addEntriesFromDictionary:properties];
        [r setObject:[NSDictionary dictionaryWithDictionary:p] forKey:action];
        if (self.distinctId) {
            [r setObject:self.distinctId forKey:@"$distinct_id"];
            MixpanelLog(@"%@ queueing people record: %@", self.mixpanel, r);
            [self.mixpanel.peopleQueue addObject:r];
            if ([self.mixpanel.peopleQueue count] > 500) {
                [self.mixpanel.peopleQueue removeObjectAtIndex:0];
            }
        } else {
            MixpanelLog(@"%@ queueing unidentified people record: %@", self.mixpanel, r);
            [self.unidentifiedQueue addObject:r];
            if ([self.unidentifiedQueue count] > 500) {
                [self.unidentifiedQueue removeObjectAtIndex:0];
            }
        }
        if ([Mixpanel inBackground]) {
            [self.mixpanel archivePeople];
        }
    });
}

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
    NSArray *tokens = [NSArray arrayWithObject:[NSString stringWithString:hex]];
    NSDictionary *properties = [NSDictionary dictionaryWithObject:tokens forKey:@"$ios_devices"];
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
    [self set:[NSDictionary dictionaryWithObject:object forKey:property]];
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
    for (id v in [properties allValues]) {
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
    [self increment:[NSDictionary dictionaryWithObject:amount forKey:property]];
}

- (void)append:(NSDictionary *)properties
{
    NSAssert(properties != nil, @"properties must not be nil");
    [Mixpanel assertPropertyTypes:properties];
    [self addPeopleRecordToQueueWithAction:@"$append" andProperties:properties];
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
        [self append:[NSDictionary dictionaryWithObject:txn forKey:@"$transactions"]];
    }
}

- (void)clearCharges
{
    [self set:[NSDictionary dictionaryWithObject:[NSArray array] forKey:@"$transactions"]];
}

- (void)deleteUser
{
    [self addPeopleRecordToQueueWithAction:@"$delete" andProperties:[NSDictionary dictionary]];
}

@end
