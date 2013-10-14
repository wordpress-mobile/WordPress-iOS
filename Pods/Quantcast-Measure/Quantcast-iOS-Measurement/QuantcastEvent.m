/*
 * Copyright 2012 Quantcast Corp.
 *
 * This software is licensed under the Quantcast Mobile App Measurement Terms of Service
 * https://www.quantcast.com/learning-center/quantcast-terms/mobile-app-measurement-tos
 * (the “License”). You may not use this file unless (1) you sign up for an account at
 * https://www.quantcast.com and click your agreement to the License and (2) are in
 * compliance with the License. See the License for the specific language governing
 * permissions and limitations under the License.
 *
 */

#ifndef __has_feature
#define __has_feature(x) 0
#endif
#ifndef __has_extension
#define __has_extension __has_feature // Compatibility with pre-3.0 compilers.
#endif

#if __has_feature(objc_arc) && __clang_major__ >= 3
#error "Quantcast Measurement is not designed to be used with ARC. Please add '-fno-objc-arc' to this file's compiler flags"
#endif // __has_feature(objc_arc)

#import "QuantcastMeasurement.h"
#import <sys/utsname.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import "QuantcastEvent.h"
#import "QuantcastParameters.h"
#import "QuantcastPolicy.h"
#import "QuantcastUtils.h"

@interface QuantcastMeasurement (Carrier)
// declare "private" method here;
-(CTCarrier*)getCarrier;
@end

@interface QuantcastEvent ()
+(NSString*)hashDeviceID:(NSString*)inDeviceID withSalt:(NSString*)inSalt;
+(NSString*)connectionTypeForNetworkStatus:(QuantcastNetworkStatus)inNetworkStatus;

-(void)addTimeZoneParameterEnforcingPolicy:(QuantcastPolicy*)inPolicy;

@end
#pragma mark - QuantcastEvent
@implementation QuantcastEvent
@synthesize timestamp=_timestamp;
@synthesize sessionID=_sessionID;

-(id)initWithSessionID:(NSString*)inSessionID {
    
    return [self initWithSessionID:inSessionID timeStamp:[NSDate date]];
}

-(id)initWithSessionID:(NSString*)inSessionID timeStamp:(NSDate*)inTimeStamp {
    
    self = [super init];
    if (self) {
        _timestamp = [inTimeStamp retain];
        _sessionID = [inSessionID retain];
        _parameters = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
        
    }
    
    return self;
}


-(void)dealloc {
    [_timestamp release];
    [_sessionID release];
    [_parameters release];
    
    [super dealloc];
}


#pragma mark - Parameter Management
@synthesize parameters=_parameters;

-(void)putParameter:(NSString*)inParamKey withValue:(id)inValue enforcingPolicy:(QuantcastPolicy*)inPolicyOrNil {
    
    if ( nil != inPolicyOrNil && ( [inPolicyOrNil isBlacklistedParameter:inParamKey] || inPolicyOrNil.isMeasurementBlackedout ) ) {
        return;
    }
    
    if ( nil == inValue ) {
        return;
    }
    
    [_parameters setObject:inValue forKey:inParamKey];
}

-(id)getParameter:(NSString*)inParamKey {
    return [_parameters objectForKey:inParamKey];
}

-(void)putLabels:(id<NSObject>)inLabelsObjectOrNil enforcingPolicy:(QuantcastPolicy*)inPolicyOrNil {
    if ( nil != inLabelsObjectOrNil ) {
      
        if ( [inLabelsObjectOrNil isKindOfClass:[NSString class]] ) {
            NSString* encodedLabel = [QuantcastUtils urlEncodeString:(NSString*)inLabelsObjectOrNil];
            
            [self putParameter:QCPARAMETER_LABELS withValue:encodedLabel enforcingPolicy:inPolicyOrNil];

        }
        else if ( [inLabelsObjectOrNil isKindOfClass:[NSArray class]] ) {
            NSArray* labelArray = (NSArray*)inLabelsObjectOrNil;
            
            NSString* labelsString =  [QuantcastUtils encodeLabelsList:labelArray];
            
            [self putParameter:QCPARAMETER_LABELS withValue:labelsString enforcingPolicy:inPolicyOrNil];
        }
        else {
            NSLog(@"QC Measurment: An incorrect object type was passed as a label. The object passed was: %@",inLabelsObjectOrNil);
        
        }
    }
}

-(void)addTimeZoneParameterEnforcingPolicy:(QuantcastPolicy*)inPolicy {
    
    NSTimeZone* tz = [NSTimeZone localTimeZone];
    
    [self putParameter:QCPARAMETER_DST withValue:[NSNumber numberWithBool:[tz isDaylightSavingTimeForDate:self.timestamp]] enforcingPolicy:inPolicy];
    
    NSInteger tzMinuteOffset = [tz secondsFromGMTForDate:self.timestamp]/60;
    
    [self putParameter:QCPARAMETER_TZO withValue:[NSNumber numberWithInteger:tzMinuteOffset] enforcingPolicy:inPolicy];
}

#pragma mark - JSON conversion

-(NSString*)JSONStringEnforcingPolicy:(QuantcastPolicy*)inPolicyOrNil {
    NSSet* paramsWithUnquotedValues = [NSSet setWithObjects:QCPARAMETER_LATENCY, nil];
    
    NSString* jsonStr = @"{";
    
    // add sessoin id and timestamp 
    
    jsonStr = [jsonStr stringByAppendingFormat:@"\"sid\":\"%@\",\"et\":\"%qi\"",self.sessionID,(int64_t)[self.timestamp timeIntervalSince1970]];
    
    // now add json for each parameter. Sort for testing purposes
    
    NSArray* sortedKeys = [[self.parameters allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    for ( NSString* param in sortedKeys ) {
        
        if ( nil != inPolicyOrNil && [inPolicyOrNil isBlacklistedParameter:param] ) {
            continue;
        }
        
        id value = [self.parameters objectForKey:param];
        
        NSString* valueStr;
        
        if ( [value isKindOfClass:[NSString class]]) {
            valueStr = (NSString*)value;
        }
        else if ([value isKindOfClass:[NSNumber class]] ) {
            valueStr = [(NSNumber*)value stringValue];
        }
        else {
            valueStr = [value description];
        }
        
        // hash the 'did' and 'aid' parameters
        
        if ( nil != inPolicyOrNil ) {
            if ( [param compare:QCPARAMETER_DID] == NSOrderedSame || [param compare:QCPARAMETER_AID] == NSOrderedSame ) {
                valueStr = [QuantcastEvent hashDeviceID:valueStr withSalt:inPolicyOrNil.deviceIDHashSalt];
            }
        }
        
        NSString* paramFormat = @",\"%@\":\"%@\"";
        if ( [paramsWithUnquotedValues containsObject:param] ) {
            paramFormat = @",\"%@\":%@";
        }
        
        jsonStr = [jsonStr stringByAppendingFormat:paramFormat,param,valueStr];
    }
    
    // close it up
    
    jsonStr = [jsonStr stringByAppendingString:@"}"];
               
    return jsonStr;
}


#pragma mark - Debugging
@synthesize enableLogging;

- (NSString *)description {
    return [NSString stringWithFormat:@"<QuantcastEvent %p: sid = %@, timestamp = %@>", self, self.sessionID, self.timestamp ];
}

#pragma mark - Event Factory

+(NSString*)hashDeviceID:(NSString*)inDeviceID withSalt:(NSString*)inSalt {
    if ( nil != inSalt ) {
        NSString* saltedGoodness = [inDeviceID stringByAppendingString:inSalt];
        
        return [QuantcastUtils quantcastHash:saltedGoodness];
    }
    else {
        return inDeviceID;
    }
}

+(NSString*)connectionTypeForNetworkStatus:(QuantcastNetworkStatus)inNetworkStatus {
    NSString* connectionType = @"unknown";
    
    switch ( inNetworkStatus ) {
        case QuantcastReachableViaWiFi:
            connectionType = @"wifi";
            break;
        case QuantcastReachableViaWWAN:
            connectionType = @"wwan";
            break;
        case QuantcastNotReachable:
            connectionType = @"disconnected";
            break;
        default:
            break;
    }

    return connectionType;
}


+(QuantcastEvent*)eventWithSessionID:(NSString*)inSessionID 
                applicationInstallID:(NSString*)inAppInstallID
                     enforcingPolicy:(QuantcastPolicy*)inPolicy
{
    QuantcastEvent* e = [[[QuantcastEvent alloc] initWithSessionID:inSessionID] autorelease];
    
    if ( nil != inAppInstallID )
    {
        [e putParameter:QCPARAMETER_AID withValue:inAppInstallID enforcingPolicy:inPolicy];
    }

    return e;
}

+(QuantcastEvent*)openSessionEventWithClientUserHash:(NSString*)inHashedUserIDOrNil
                                    newSessionReason:(NSString*)inReason
                                       networkStatus:(QuantcastNetworkStatus)inNetworkStatus
                                           sessionID:(NSString*)inSessionID
                                     quantcastAPIKey:(NSString*)inQuantcastAPIKey
                                    deviceIdentifier:(NSString*)inDeviceID
                                appInstallIdentifier:(NSString*)inAppInstallID
                                     enforcingPolicy:(QuantcastPolicy*)inPolicy
                                         eventLabels:(id<NSObject>)inEventLabelsOrNil
                                             carrier:(CTCarrier*)carrier
{
    
    QuantcastEvent* e = [QuantcastEvent eventWithSessionID:inSessionID applicationInstallID:inAppInstallID enforcingPolicy:inPolicy];

    [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_LOAD enforcingPolicy:inPolicy];

    [e putParameter:QCPARAMETER_REASON withValue:inReason enforcingPolicy:inPolicy];
    [e putParameter:QCPARAMATER_APIKEY withValue:inQuantcastAPIKey enforcingPolicy:inPolicy];
    [e putParameter:QCPARAMETER_MEDIA withValue:@"app" enforcingPolicy:inPolicy];
    [e putParameter:QCPARAMETER_CT withValue:[QuantcastEvent connectionTypeForNetworkStatus:inNetworkStatus] enforcingPolicy:inPolicy];
    
    
    if ( nil != inDeviceID ) {
        [e putParameter:QCPARAMETER_DID withValue:inDeviceID enforcingPolicy:inPolicy];
       
    }

    
    NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
    if ( nil != appName) {
        [e putParameter:QCPARAMETER_ANAME withValue:appName enforcingPolicy:inPolicy];
    }
    
    NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
    if ( nil != appBundleID ) {
        [e putParameter:QCPARAMATER_PKID withValue:appBundleID enforcingPolicy:inPolicy];
    }
    
    NSString* appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if (nil != appVersion) {
        [e putParameter:QCPARAMETER_AVER withValue:appVersion enforcingPolicy:inPolicy];
    }
    NSString* appBuildVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    if (nil != appBuildVersion) {
        [e putParameter:QCPARAMETER_IVER withValue:appBuildVersion enforcingPolicy:inPolicy];
    }
    
    [e putLabels:inEventLabelsOrNil enforcingPolicy:inPolicy];
    
    if ( nil != inHashedUserIDOrNil ) {
        [e putParameter:QCPARAMETER_UH withValue:inHashedUserIDOrNil enforcingPolicy:inPolicy];
    }
    
    // screen resolution
    
    UIScreen* screen = [UIScreen mainScreen];
    
    NSString* screenResolution = [NSString stringWithFormat:@"%dx%dx32", (int)screen.bounds.size.width, (int)screen.bounds.size.height ];
    
    [e putParameter:QCPARAMETER_SR withValue:screenResolution enforcingPolicy:inPolicy];
    
    // time zone
    
    [e addTimeZoneParameterEnforcingPolicy:inPolicy];
    
    // Cheack carrier and fill in data
    if ( nil != carrier ) {
    
        // Get mobile country code 
        NSString *icc = [carrier isoCountryCode];
        if (icc != nil) {
            [e putParameter:QCPARAMETER_ICC withValue:icc enforcingPolicy:inPolicy];
        }

        NSString *mcc = [carrier mobileCountryCode];
        if ( mcc != nil) {
            [e putParameter:QCPARAMETER_MCC withValue:mcc enforcingPolicy:inPolicy];                
        }
        
        // Get carrier name
        NSString *carrierName = [carrier carrierName];
        if (carrierName != nil) {
            [e putParameter:QCPARAMETER_MNN withValue:carrierName enforcingPolicy:inPolicy];
        }
        
        
        // Get mobile network code
        NSString *mnc = [carrier mobileNetworkCode];
        if (mnc != nil) {            
            [e putParameter:QCPARAMETER_MNC withValue:mnc enforcingPolicy:inPolicy];
        }
        
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    if ([paths count] > 0) {
        NSString* base = [paths objectAtIndex:0];
        NSError* error = nil;
        NSDictionary* attrib = [[NSFileManager defaultManager] attributesOfItemAtPath:base error:&error];
        if (nil != error && e.enableLogging) {
            NSLog(@"QC Measurement: Error creating user agent regular expression = %@ ", error );
        }
        else {
            NSDate* created = [attrib objectForKey:NSFileCreationDate];
            if (nil != created) {
                [e putParameter:QCPARAMETER_INSTALL withValue:[NSString stringWithFormat:@"%lu",(unsigned long)[created timeIntervalSince1970]*1000] enforcingPolicy:inPolicy];
            }
        }
    }
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    NSString* platform =  [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
    [e putParameter:QCPARAMETER_DTYPE withValue:[[UIDevice currentDevice] model] enforcingPolicy:inPolicy];
    [e putParameter:QCPARAMETER_DMOD withValue:platform enforcingPolicy:inPolicy];
    [e putParameter:QCPARAMETER_DOS withValue:[[UIDevice currentDevice] systemName] enforcingPolicy:inPolicy];
    [e putParameter:QCPARAMETER_DOSV withValue:[[UIDevice currentDevice] systemVersion] enforcingPolicy:inPolicy];
    [e putParameter:QCPARAMETER_DM withValue:@"Apple" enforcingPolicy:inPolicy];    
    [e putParameter:QCPARAMETER_LC withValue:[[NSLocale preferredLanguages] objectAtIndex:0] enforcingPolicy:inPolicy];    
    [e putParameter:QCPARAMETER_LL withValue:[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode] enforcingPolicy:inPolicy];
    
    return e;
}

+(QuantcastEvent*)closeSessionEventWithSessionID:(NSString*)inSessionID 
                            applicationInstallID:(NSString*)inAppInstallID
                                 enforcingPolicy:(QuantcastPolicy*)inPolicy
                                     eventLabels:(id<NSObject>)inEventLabelsOrNil
{
    QuantcastEvent* e = [QuantcastEvent eventWithSessionID:inSessionID applicationInstallID:inAppInstallID enforcingPolicy:inPolicy];
    
    [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_FINISHED enforcingPolicy:inPolicy];
    [e putLabels:inEventLabelsOrNil enforcingPolicy:inPolicy];
    
    return e;
}

+(QuantcastEvent*)pauseSessionEventWithSessionID:(NSString*)inSessionID 
                            applicationInstallID:(NSString*)inAppInstallID
                                 enforcingPolicy:(QuantcastPolicy*)inPolicy
                                     eventLabels:(id<NSObject>)inEventLabelsOrNil
{
    QuantcastEvent* e = [QuantcastEvent eventWithSessionID:inSessionID applicationInstallID:inAppInstallID enforcingPolicy:inPolicy];
    
    [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_PAUSE enforcingPolicy:inPolicy];
    [e putLabels:inEventLabelsOrNil enforcingPolicy:inPolicy];
    
    return e;
}

+(QuantcastEvent*)resumeSessionEventWithSessionID:(NSString*)inSessionID 
                             applicationInstallID:(NSString*)inAppInstallID
                                  enforcingPolicy:(QuantcastPolicy*)inPolicy
                                      eventLabels:(id<NSObject>)inEventLabelsOrNil
{
    QuantcastEvent* e = [QuantcastEvent eventWithSessionID:inSessionID applicationInstallID:inAppInstallID enforcingPolicy:inPolicy];
    
    [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_RESUME enforcingPolicy:inPolicy];    
    [e putLabels:inEventLabelsOrNil enforcingPolicy:inPolicy];
    
    return e;
}

+(QuantcastEvent*)logEventEventWithEventName:(NSString*)inEventName
                                 eventLabels:(id<NSObject>)inEventLabelsOrNil
                                   sessionID:(NSString*)inSessionID 
                        applicationInstallID:(NSString*)inAppInstallID
                             enforcingPolicy:(QuantcastPolicy*)inPolicy
{
    QuantcastEvent* e = [QuantcastEvent eventWithSessionID:inSessionID applicationInstallID:inAppInstallID enforcingPolicy:inPolicy];
   
    [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_APPEVENT enforcingPolicy:inPolicy];
    [e putParameter:QCPARAMETER_APPEVENT withValue:inEventName enforcingPolicy:inPolicy];
    [e putLabels:inEventLabelsOrNil enforcingPolicy:inPolicy];

    
    return e;
}

+(QuantcastEvent*)logUploadLatency:(NSUInteger)inLatencyMilliseconds
                       forUploadId:(NSString*)inUploadID
                     withSessionID:(NSString*)inSessionID 
              applicationInstallID:(NSString*)inAppInstallID
                   enforcingPolicy:(QuantcastPolicy*)inPolicy
{
    QuantcastEvent* e = [QuantcastEvent eventWithSessionID:inSessionID applicationInstallID:inAppInstallID enforcingPolicy:inPolicy];

    [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_LATENCY enforcingPolicy:inPolicy];
    [e putParameter:QCPARAMETER_LATENCY_UPLID withValue:inUploadID enforcingPolicy:inPolicy];
    [e putParameter:QCPARAMETER_LATENCY_VALUE withValue:[NSString stringWithFormat:@"%lu",(unsigned long)inLatencyMilliseconds] enforcingPolicy:inPolicy];
    
    return e;
}

+(QuantcastEvent*)geolocationEventWithCountry:(NSString*)inCountry
                                     province:(NSString*)inProvince
                                         city:(NSString*)inCity
                               eventTimestamp:(NSDate*)inTimestamp
                            appIsInBackground:(BOOL)inIsAppInBackground
                                withSessionID:(NSString*)inSessionID
                         applicationInstallID:(NSString*)inAppInstallID
                              enforcingPolicy:(QuantcastPolicy*)inPolicy
{
    QuantcastEvent* e = [[[QuantcastEvent alloc] initWithSessionID:inSessionID timeStamp:inTimestamp] autorelease];
    
    [e putParameter:QCPARAMETER_AID withValue:inAppInstallID enforcingPolicy:inPolicy];
    [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_LOCATION enforcingPolicy:inPolicy];
    [e putParameter:QCPARAMETER_COUNTRY withValue:inCountry enforcingPolicy:inPolicy];
    [e putParameter:QCPARAMETER_STATE withValue:inProvince enforcingPolicy:inPolicy];
    [e putParameter:QCPARAMETER_LOCALITY withValue:inCity enforcingPolicy:inPolicy];
    if (inIsAppInBackground) {
        [e putParameter:QCPARAMETER_INBACKGROUND withValue:[[NSNumber numberWithBool:inIsAppInBackground] stringValue] enforcingPolicy:inPolicy];
    }
    [e addTimeZoneParameterEnforcingPolicy:inPolicy];
    return e;
}

+(QuantcastEvent*)networkReachabilityEventWithNetworkStatus:(QuantcastNetworkStatus)inNetworkStatus
                                              withSessionID:(NSString*)inSessionID
                                       applicationInstallID:(NSString*)inAppInstallID
                                            enforcingPolicy:(QuantcastPolicy*)inPolicy
{
    QuantcastEvent* e = [QuantcastEvent eventWithSessionID:inSessionID applicationInstallID:inAppInstallID enforcingPolicy:inPolicy];

    [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_NETINFO enforcingPolicy:inPolicy];
    [e putParameter:QCPARAMETER_CT withValue:[QuantcastEvent connectionTypeForNetworkStatus:inNetworkStatus] enforcingPolicy:inPolicy];

    return e;
}


+(QuantcastEvent*)logSDKError:(NSString*)inSDKErrorType
              withErrorObject:(NSError*)inErrorObjectOrNil
               errorParameter:(NSString*)inErrorParameterOrNil
                withSessionID:(NSString*)inSessionID
         applicationInstallID:(NSString*)inAppInstallID
              enforcingPolicy:(QuantcastPolicy*)inPolicy
{
    QuantcastEvent* e = [QuantcastEvent eventWithSessionID:inSessionID applicationInstallID:inAppInstallID enforcingPolicy:inPolicy];
 
    [e putParameter:QCPARAMETER_EVENT withValue:QCMEASUREMENT_EVENT_SDKERROR enforcingPolicy:inPolicy];
    [e putParameter:QCPARAMETER_ERRORTYPE withValue:inSDKErrorType enforcingPolicy:inPolicy];

    if ( nil != inErrorObjectOrNil ) {
        NSString* errorDesc = [inErrorObjectOrNil description];
        
        [e putParameter:QCPARAMETER_ERRORDESCRIPTION withValue:[QuantcastUtils JSONEncodeString:errorDesc] enforcingPolicy:inPolicy];
    }

    if ( nil != inErrorParameterOrNil ) {
        [e putParameter:QCPARAMETER_ERRORPARAMETER withValue:[QuantcastUtils JSONEncodeString:inErrorParameterOrNil] enforcingPolicy:inPolicy];
    }
    return e;
}

@end
