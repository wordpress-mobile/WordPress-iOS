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

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <AdSupport/AdSupport.h>
#import "QuantcastMeasurement.h"
#import "QuantcastParameters.h"
#import "QuantcastDataManager.h"
#import "QuantcastEvent.h"
#import "QuantcastUtils.h"
#import "QuantcastPolicy.h"
#import "QuantcastOptOutViewController.h"

QuantcastMeasurement* gSharedInstance = nil;


@interface QuantcastMeasurement ()

@property (retain,nonatomic) NSString* currentSessionID;
@property (retain,nonatomic) QuantcastDataManager* dataManager;
@property (retain,nonatomic) NSString* quantcastAPIKey;
@property (retain,nonatomic) CLLocationManager* locationManager;
@property (retain,nonatomic) CLGeocoder* geocoder;
@property (readonly,nonatomic) BOOL isMeasurementActive;
@property (retain,nonatomic) NSDate* sessionPauseStartTime;
@property (retain,nonatomic) NSString* geoCountry;
@property (retain,nonatomic) NSString* geoProvince;
@property (retain,nonatomic) NSString* geoCity;
@property (readonly,nonatomic) BOOL advertisingTrackingEnabled;
@property (retain, nonatomic) CTTelephonyNetworkInfo* telephoneInfo;
@property (readonly,nonatomic) CTCarrier* carrier;

+(NSString*)generateSessionID;
+(BOOL)isOptedOutStatus;

-(NSString*)appInstallIdentifierWithUserAdvertisingPreference:(BOOL)inAdvertisingTrackingEnabled;
-(BOOL)hasUserAdvertisingPrefChangeWithCurrentPref:(BOOL)inCurrentPref;

-(void)enableDataUploading;
-(void)recordEvent:(QuantcastEvent*)inEvent;

-(void)logUploadLatency:(NSUInteger)inLatencyMilliseconds forUploadId:(NSString*)inUploadID;
-(void)logSDKError:(NSString*)inSDKErrorType withError:(NSError*)inErrorOrNil errorParameter:(NSString*)inErrorParametOrNil;


-(void)setOptOutStatus:(BOOL)inOptOutStatus;
-(void)startNewSessionAndGenerateEventWithReason:(NSString*)inReason withLabels:(id<NSObject>)inLabelsOrNil;
-(void)startNewSessionIfUsersAdPrefChanged;
-(BOOL)isQuantcastAPIKeyValid:(NSString*)inQuantcastAppId;

-(NSString*)setUserIdentifier:(NSString*)inUserIdentifierOrNil;

-(void)startGeoLocationMeasurement;
-(void)stopGeoLocationMeasurement;
-(void)pauseGeoLocationMeasurement;
-(void)resumeGeoLocationMeasurment;
-(void)generateGeoEventWithCurrentLocation;

-(void)logNetworkReachability;
-(BOOL)startReachabilityNotifier;
-(void)stopReachabilityNotifier;
@end

@implementation QuantcastMeasurement
@synthesize locationManager;
@synthesize geocoder;
@synthesize sessionPauseStartTime;
@synthesize telephoneInfo;

+(QuantcastMeasurement*)sharedInstance {

    @synchronized( [QuantcastMeasurement class] ) {
        if ( nil == gSharedInstance ) {
            
            gSharedInstance = [[QuantcastMeasurement alloc] init];
            
        }
    }
    
    return gSharedInstance;
}

-(id)init {
    self = [super init];
    if (self) {
        self.enableLogging = NO;
        
        // the first thing to do is determine user opt-out status, as that will guide everything else.
        _isOptedOut = [QuantcastMeasurement isOptedOutStatus];
        if(_isOptedOut){
            [self setOptOutCookie:YES];
        }
        
        _geoLocationEnabled = NO;
        
        Class telephonyClass = NSClassFromString(@"CTTelephonyNetworkInfo");
        if ( nil != telephonyClass ) {
            telephoneInfo = [[telephonyClass alloc] init];
        }
        uploadEventCount = QCMEASUREMENT_DEFAULT_UPLOAD_EVENT_COUNT;
        
    }
    
    return self;
}

-(void)dealloc {
    
    [self stopReachabilityNotifier];
    self.geoLocationEnabled = NO;
    
    [geocoder release];
    [locationManager release];
    [sessionPauseStartTime release];
    [quantcastAPIKey release];
    
    [_dataManager release];
    [_hashedUserId release];

    [telephoneInfo release];
    
    [super dealloc];
}

-(void)appendUserAgent:(BOOL)add {
    
    NSString* userAgent = [self originalUserAgent];
    
    //check for quantcast user agent first
    NSString* qcRegex = [NSString stringWithFormat:@"%@/iOS_(\\d+)\\.(\\d+)\\.(\\d+)/[a-zA-Z0-9]{16}-[a-zA-Z0-9]{16}", QCMEASUREMENT_UA_PREFIX];
    NSError* regexError = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:qcRegex options:0 error:&regexError];
    if(nil != regexError && self.enableLogging){
        NSLog(@"QC Measurement: Error creating user agent regular expression = %@ ", regexError );
    }
    NSRange start = [regex rangeOfFirstMatchInString:userAgent options:0 range:NSMakeRange(0, userAgent.length)];
    
    NSString* newUA = nil;
    if( start.location == NSNotFound && add ) {
        newUA = [userAgent stringByAppendingFormat:@"%@/%@/%@", QCMEASUREMENT_UA_PREFIX, QCMEASUREMENT_API_IDENTIFIER, self.quantcastAPIKey];
    }
    else if( start.location != NSNotFound && !add ) {
        newUA = [NSString stringWithFormat:@"%@%@", [userAgent substringToIndex:start.location], [userAgent substringFromIndex:NSMaxRange(start)]];
    }
    
    if( nil != newUA ) {
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:newUA, @"UserAgent", nil];
        [userDefaults registerDefaults:dictionary];
        
        //special check if Cordova is used
        
        NSString *cordovaValue = [userDefaults stringForKey:@"Cordova-User-Agent"];
        if( nil != cordovaValue ) {
            [userDefaults setValue:newUA forKey:@"Cordova-User-Agent"];
        }
    }
    
    
}

-(NSString*)originalUserAgent {
    NSString* userAgent = [[NSUserDefaults standardUserDefaults] stringForKey:@"UserAgent"];
    if( nil == userAgent ) {
        UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectZero];
        userAgent = [webView stringByEvaluatingJavaScriptFromString:@"navigator.userAgent"];
        [webView release];
    }
    return userAgent;
}

-(BOOL)advertisingTrackingEnabled {
    BOOL userAdvertisingPreference = YES;
    
    Class adManagerClass = NSClassFromString(@"ASIdentifierManager");
    
    if ( nil != adManagerClass ) {
        
        ASIdentifierManager* adPrefManager = [adManagerClass sharedManager];
        
        userAdvertisingPreference = adPrefManager.advertisingTrackingEnabled;
    }

    return userAdvertisingPreference;
}

#pragma mark - Device Identifier
-(NSString*)deviceIdentifier {
    
    if ( self.isOptedOut ) {
        return nil;
    }
    
    NSString* udidStr = nil;
    
    Class adManagerClass = NSClassFromString(@"ASIdentifierManager");
    
    if ( nil != adManagerClass ) {
        
        ASIdentifierManager* manager = [adManagerClass sharedManager];
        
        if ( manager.advertisingTrackingEnabled) {
            NSUUID* uuid = manager.advertisingIdentifier;
            
            if ( nil != uuid ) {
                udidStr = [uuid UUIDString];
                
                // now check for the iOS 6 bug
                
                if ( [udidStr compare:@"00000000-0000-0000-0000-000000000000"] == NSOrderedSame ) {
                    // this is a bad device identifier. treat as having no device identifier.
                    udidStr = nil;
                }
            }
        }
    }
    else if ([[[UIDevice currentDevice] systemVersion] compare:@"6.0" options:NSNumericSearch] != NSOrderedAscending) {
        NSLog(@"QC Measurement: ERROR - This app is running on iOS 6 or later and is not properly linked with the AdSupport.framework");
    }

    return udidStr;

}

-(NSString*)appInstallIdentifier {
    return [self appInstallIdentifierWithUserAdvertisingPreference:self.advertisingTrackingEnabled];
}

-(NSString*)appInstallIdentifierWithUserAdvertisingPreference:(BOOL)inAdvertisingTrackingEnabled {
    // this method is factored out for testability reasons
    
    if ( self.isOptedOut ) {
        return nil;
    }
   
    // first, check if one exists and use it contents
    
    NSString* cacheDir = [QuantcastUtils quantcastCacheDirectoryPathCreatingIfNeeded];
    
    if ( nil == cacheDir) {
        return @"";
    }
    
    NSError* writeError = nil;

    NSString* identFile = [cacheDir stringByAppendingPathComponent:QCMEASUREMENT_IDENTIFIER_FILENAME];
    
    // first thing is to determine if apple's ad ID pref has changed. If so, create a new app id.
    

    BOOL adIdPrefHasChanged = [self hasUserAdvertisingPrefChangeWithCurrentPref:inAdvertisingTrackingEnabled];
    
    
    if ( [[NSFileManager defaultManager] fileExistsAtPath:identFile] && !adIdPrefHasChanged ) {
        NSError* readError = nil;
        
        NSString* idStr = [NSString stringWithContentsOfFile:identFile encoding:NSUTF8StringEncoding error:&readError];
        
        if ( nil != readError && self.enableLogging ) {
            NSLog(@"QC Measurement: Error reading app specific identifier file = %@ ", readError );
        }
        
        // make sure string is of proper size before using it. Expecting something like "68753A44-4D6F-1226-9C60-0050E4C00067"
        
        if ( [idStr length] == 36 ) {
            return idStr;
        }
    }
    
    // a condition exists where a new app install ID needs to be created. create a new ID
    
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef uuidStr = CFUUIDCreateString(kCFAllocatorDefault, uuid);
    
    NSString* newIdStr = [NSString stringWithString:(NSString *)uuidStr ];
    
    CFRelease(uuidStr);
    CFRelease(uuid);
    
    writeError = nil;
    
    [newIdStr writeToFile:identFile atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
    
    if ( self.enableLogging ) {
        if ( nil != writeError ) {
            NSLog(@"QC Measurement: Error when writing app specific identifier = %@", writeError);
        }
        else {
            NSLog(@"QC Measurement: Create new app identifier '%@' and wrote to file '%@'", newIdStr, identFile );
        }
    }
    
    return newIdStr;
}


-(BOOL)hasUserAdvertisingPrefChangeWithCurrentPref:(BOOL)inCurrentPref {

    NSString* cacheDir = [QuantcastUtils quantcastCacheDirectoryPathCreatingIfNeeded];
    NSString* adIdPrefFile = [cacheDir stringByAppendingPathComponent:QCMEASUREMENT_ADIDPREF_FILENAME];

    BOOL adIdPrefHasChanged = NO;
    NSNumber* adIdPrefValue = [NSNumber numberWithBool:inCurrentPref];
    NSString* currentAdIdPref = [adIdPrefValue stringValue];
    NSError* writeError = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:adIdPrefFile] ) {
        NSError* readError = nil;
        
        NSString* savedAdIdPref = [NSString stringWithContentsOfFile:adIdPrefFile encoding:NSUTF8StringEncoding error:&readError];
        
        
        if ( [savedAdIdPref compare:currentAdIdPref] != NSOrderedSame ) {
            adIdPrefHasChanged = YES;
            
            writeError = nil;
            
            [currentAdIdPref writeToFile:adIdPrefFile atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
            
            if ( nil != writeError && self.enableLogging ) {
                NSLog(@"QC Measurement: Error writing user's ad tracking preference to file = %@", writeError );
            }
        }
    }
    else {
        writeError = nil;
        
        [currentAdIdPref writeToFile:adIdPrefFile atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
        
        if ( nil != writeError && self.enableLogging ) {
            NSLog(@"QC Measurement: Error writing user's ad tracking preference to file = %@", writeError );
        }
    }
    
    return adIdPrefHasChanged;

}

#pragma mark - Event Recording

-(void)recordEvent:(QuantcastEvent*)inEvent {
    
    [self.dataManager recordEvent:inEvent];
}

-(void)enableDataUploading {
    // this method is factored out primarily for unit testing reasons
    
    [self.dataManager enableDataUploadingWithReachability:self];

}

#pragma mark - Session Management
@synthesize currentSessionID;
@synthesize quantcastAPIKey;

+(NSString*)generateSessionID {
    CFUUIDRef sessionUUID = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef sessionIDStr = CFUUIDCreateString(kCFAllocatorDefault, sessionUUID);
    
    NSString* sessionID = [NSString stringWithString:(NSString*)sessionIDStr];
    
    CFRelease(sessionIDStr);
    CFRelease(sessionUUID);
    
    return sessionID;
}

-(BOOL)isMeasurementActive {
    return nil != self.currentSessionID;
}

-(void)startNewSessionAndGenerateEventWithReason:(NSString*)inReason withLabels:(id<NSObject>)inLabelsOrNil {
    
    self.currentSessionID = [QuantcastMeasurement generateSessionID];
    
    if ( nil != self.dataManager.policy ) {
        [self.dataManager.policy downloadLatestPolicyWithReachability:self];
    }

    QuantcastEvent* e = [QuantcastEvent openSessionEventWithClientUserHash:_hashedUserId
                                                          newSessionReason:inReason
                                                             networkStatus:[self currentReachabilityStatus]
                                                                 sessionID:self.currentSessionID
                                                           quantcastAPIKey:self.quantcastAPIKey
                                                          deviceIdentifier:self.deviceIdentifier
                                                             appInstallIdentifier:self.appInstallIdentifier
                                                           enforcingPolicy:self.dataManager.policy
                                                               eventLabels:inLabelsOrNil
                                                                   carrier:self.carrier];
    
    
    [self recordEvent:e];
    
    [self generateGeoEventWithCurrentLocation];
}


-(void)beginMeasurementSessionWithAPIKey:(NSString*)inQuantcastAPIKey labels:(id<NSObject>)inLabelsOrNil {
        
    // first check that app ID is proprly formatted
    
    if ( ![self isQuantcastAPIKeyValid:inQuantcastAPIKey] ) {
        return;
    }
    
    self.quantcastAPIKey = inQuantcastAPIKey;
 
    if ( !self.isOptedOut ) {
        [self startReachabilityNotifier];
        
        [self appendUserAgent:YES];
        
        if (nil == self.dataManager) {
            QuantcastPolicy* policy = [QuantcastPolicy policyWithAPIKey:self.quantcastAPIKey networkReachability:self carrier:self.carrier enableLogging:self.enableLogging];
            
            if ( nil == policy ) {
                // policy wasn't able to be built. Stop reachability and bail, thus not activating measurement.
                [self stopReachabilityNotifier];
                
                if (self.enableLogging) {
                    NSLog(@"QC Measurement: Unable to activate measurement due to policy object being nil.");
                }
                return;
            }
            
            self.dataManager = [[[QuantcastDataManager alloc] initWithOptOut:self.isOptedOut policy:policy] autorelease];
            self.dataManager.enableLogging = self.enableLogging;
            self.dataManager.uploadEventCount = uploadEventCount;

        }

        [self enableDataUploading];
        

        [self startNewSessionAndGenerateEventWithReason:QCPARAMETER_REASONTYPE_LAUNCH withLabels:inLabelsOrNil];
                
        if (self.enableLogging) {
            NSLog(@"QC Measurement: Using '%@' for upload server.",[QuantcastUtils updateSchemeForURL:[NSURL URLWithString:QCMEASUREMENT_UPLOAD_URL]]);
        }
    }
    
}

-(NSString*)beginMeasurementSessionWithAPIKey:(NSString*)inQuantcastAPIKey userIdentifier:(NSString*)inUserIdentifierOrNil labels:(id<NSObject>)inLabelsOrNil {
    
    NSString* hashedUserID = [self setUserIdentifier:inUserIdentifierOrNil];
    
    [self beginMeasurementSessionWithAPIKey:inQuantcastAPIKey labels:inLabelsOrNil];
    
    return hashedUserID;
}

-(void)endMeasurementSessionWithLabels:(id<NSObject>)inLabelsOrNil {
    if ( !self.isOptedOut  ) {
        
        if ( self.isMeasurementActive ) {
            QuantcastEvent* e = [QuantcastEvent closeSessionEventWithSessionID:self.currentSessionID enforcingPolicy:self.dataManager.policy eventLabels:inLabelsOrNil];
        
            [self recordEvent:e];
            
            [self stopGeoLocationMeasurement];
            [self stopReachabilityNotifier];
            
            self.currentSessionID = nil;
        }
        else {
            NSLog(@"QC Measurement: endMeasurementSessionWithLabels: was called without first calling beginMeasurementSession:");
        }
    }
}
-(void)pauseSessionWithLabels:(id<NSObject>)inLabelsOrNil {
    
    if ( !self.isOptedOut ) {
        if ( self.isMeasurementActive ) {
            
            QuantcastEvent* e = [QuantcastEvent pauseSessionEventWithSessionID:self.currentSessionID enforcingPolicy:self.dataManager.policy eventLabels:inLabelsOrNil];
            
            [self recordEvent:e];
            
            self.sessionPauseStartTime = [NSDate date];
            
            [self pauseGeoLocationMeasurement];
            [self stopReachabilityNotifier];
            [self.dataManager initiateDataUpload];
        }
        else {
            NSLog(@"QC Measurement: pauseSessionWithLabels: was called without first calling beginMeasurementSession:");
        }
    }
}
-(void)resumeSessionWithLabels:(id<NSObject>)inLabelsOrNil {
    // first, always check to see if iopt-out status has changed while the app was paused:
    
    [self setOptOutStatus:[QuantcastMeasurement isOptedOutStatus]];

    if ( !self.isOptedOut ) {
        
        if ( self.isMeasurementActive ) {
            QuantcastEvent* e = [QuantcastEvent resumeSessionEventWithSessionID:self.currentSessionID enforcingPolicy:self.dataManager.policy eventLabels:inLabelsOrNil];
        
            [self recordEvent:e];
            
            [self startNewSessionIfUsersAdPrefChanged];
            
            [self startReachabilityNotifier];
            [self resumeGeoLocationMeasurment];
            
            if ( self.sessionPauseStartTime != nil ) {
                NSDate* curTime = [NSDate date];
                
                if ( [curTime timeIntervalSinceDate:self.sessionPauseStartTime] > self.dataManager.policy.sessionPauseTimeoutSeconds ) {
                    
                    [self startNewSessionAndGenerateEventWithReason:QCPARAMETER_REASONTYPE_RESUME withLabels:inLabelsOrNil];
                    
                    if (self.enableLogging) {
                        NSLog(@"QC Measurement: Starting new session after app being paused for extend period of time.");
                    }
                }

                self.sessionPauseStartTime = nil;
            }
        
        }
        else {
            NSLog(@"QC Measurement: resumeSessionWithLabels: was called without first calling beginMeasurementSession:");
        }
    }
}

-(void)startNewSessionIfUsersAdPrefChanged {    
    if ( [self hasUserAdvertisingPrefChangeWithCurrentPref:self.advertisingTrackingEnabled]) {
        if (self.enableLogging) {
            NSLog(@"QC Measurement: The user has changed their advertising tracking preference. Adjusting identifiers and starting a new session.");
        }
        
        [self startNewSessionAndGenerateEventWithReason:QCPARAMETER_REASONTYPE_ADPREFCHANGE withLabels:nil];
    }
}

-(BOOL)isQuantcastAPIKeyValid:(NSString*)inQuantcastAppId {
    
    if ( nil == inQuantcastAppId ) {
        NSLog(@"QC Measurement: ERROR - No Quantcast API Key was passed to the SDK.");
        
        return NO;
    }
    
    
    NSString* apiKeyRegex = @"[a-zA-Z0-9]{16}-[a-zA-Z0-9]{16}";
    NSPredicate* checkAPIKey = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", apiKeyRegex];

    BOOL valid = [checkAPIKey evaluateWithObject:inQuantcastAppId];
    
    if ( !valid ) {
        NSLog(@"QC Measurement: ERROR - The Quantcast API Key passed to the SDK is malformed.");
        return NO;
    }
    
    return YES;
}

#pragma mark - Telephony

-(CTCarrier*)carrier{
    CTCarrier* carrier = nil;
    
    if ( nil != self.telephoneInfo ) {
        carrier = self.telephoneInfo.subscriberCellularProvider;
    }
        
    return carrier;
}


#pragma mark - Network Reachability

static void QuantcastReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
#pragma unused (target, flags)
    if ( info == NULL ) {
        NSLog(@"QC Measurement: info was NULL in QuantcastReachabilityCallback");
        return;
    }
    if ( ![(NSObject*) info isKindOfClass: [QuantcastMeasurement class]] ) {
        NSLog(@"QC Measurement: info was wrong class in QuantcastReachabilityCallback");
        return;
    }

    NSAutoreleasePool* myPool = [[NSAutoreleasePool alloc] init];
    
    QuantcastMeasurement* qcMeasurement = (QuantcastMeasurement*) info;
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kQuantcastNetworkReachabilityChangedNotification object:qcMeasurement];

    
    [qcMeasurement logNetworkReachability];
    
    [myPool release];
}


-(void)logNetworkReachability {
    if ( !self.isOptedOut && self.isMeasurementActive ) {
                
        
        QuantcastEvent* e = [QuantcastEvent networkReachabilityEventWithNetworkStatus:[self currentReachabilityStatus]
                                                                        withSessionID:self.currentSessionID
                                                                      enforcingPolicy:self.dataManager.policy];
        
        [self recordEvent:e];
    }
}


-(BOOL)startReachabilityNotifier
{
    BOOL retVal = NO;
    
    if ( NULL == _reachability ) {
        SCNetworkReachabilityContext    context = {0, self, NULL, NULL, NULL};

        NSURL* url = [NSURL URLWithString:QCMEASUREMENT_UPLOAD_URL];
        
        _reachability = SCNetworkReachabilityCreateWithName(NULL, [[url host] UTF8String]);
        

        if(SCNetworkReachabilitySetCallback(_reachability, QuantcastReachabilityCallback, &context))
        {
            if(SCNetworkReachabilityScheduleWithRunLoop(_reachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode))
            {
                retVal = YES;
            }
        }
    }
    return retVal;
}

-(void)stopReachabilityNotifier
{
    if(NULL != _reachability )
    {
        SCNetworkReachabilityUnscheduleFromRunLoop(_reachability, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        
        CFRelease(_reachability);
        
        _reachability = NULL;
    }
}

-(QuantcastNetworkStatus)currentReachabilityStatus
{
    if ( NULL == _reachability ) {
        return QuantcastNotReachable;
    }

    QuantcastNetworkStatus retVal = QuantcastNotReachable;
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(_reachability, &flags))
    {
        if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
        {
            // if target host is not reachable
            return QuantcastNotReachable;
        }

        if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
        {
            // if target host is reachable and no connection is required
            //  then we'll assume (for now) that your on Wi-Fi
            retVal = QuantcastReachableViaWiFi;
        }


        if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
             (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
        {
            // ... and the connection is on-demand (or on-traffic) if the
            //     calling application is using the CFSocketStream or higher APIs
            
            if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
            {
                // ... and no [user] intervention is needed
                retVal = QuantcastReachableViaWiFi;
            }
        }

        if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
        {
            // ... but WWAN connections are OK if the calling application
            //     is using the CFNetwork (CFSocketStream?) APIs.
            retVal = QuantcastReachableViaWWAN;
        }
    }
    return retVal;
}

#pragma mark - Measurement and Analytics

-(NSString*)setUserIdentifier:(NSString*)inUserIdentifierOrNil {
    
    if (self.isOptedOut) {
        return nil;
    }

    
    if ( nil == inUserIdentifierOrNil ) {
        // the "log out" semantics
        [_hashedUserId release];
        _hashedUserId = nil;
                
        return nil;
    }

    NSString* hashedUserID = [QuantcastUtils quantcastHash:inUserIdentifierOrNil];
        
    if ( nil != _hashedUserId ) {
        [_hashedUserId release];
        _hashedUserId = nil;
    }
    _hashedUserId = [hashedUserID retain];

    return hashedUserID;
}

-(NSString*)recordUserIdentifier:(NSString*)inUserIdentifierOrNil withLabels:(id<NSObject>)inLabelsOrNil {
    
    if (self.isOptedOut) {
        return nil;
    }
    
    if ( !self.isMeasurementActive ) {
        NSLog(@"QC Measurement: recordUserIdentifier:withLabels: was called without first calling beginMeasurementSession:");
        return nil;
    }
    
    // save current hashed user ID in order to detect session changes
    NSString* originalHashedUserId = nil;
    if ( _hashedUserId != nil ) {
        originalHashedUserId = [[_hashedUserId copy] autorelease];
    }
    
    NSString* hashedUserId = [self setUserIdentifier:inUserIdentifierOrNil];
    
    if ( ( originalHashedUserId == nil && hashedUserId != nil ) ||
         ( originalHashedUserId != nil && hashedUserId == nil ) ||
         ( originalHashedUserId != nil && [originalHashedUserId compare:hashedUserId] != NSOrderedSame ) ) {
        [self startNewSessionAndGenerateEventWithReason:QCPARAMETER_REASONTYPE_USERHASH withLabels:inLabelsOrNil];
    }

    return hashedUserId;
}

-(void)logEvent:(NSString*)inEventName withLabels:(id<NSObject>)inLabelsOrNil {
    
    if ( !self.isOptedOut ) {
        if (self.isMeasurementActive) {
            QuantcastEvent* e = [QuantcastEvent logEventEventWithEventName:inEventName
                                                               eventLabels:inLabelsOrNil
                                                                 sessionID:self.currentSessionID
                                                           enforcingPolicy:self.dataManager.policy];
                                 
            [self recordEvent:e];
        }
        else {
            NSLog(@"QC Measurement: logEvent:withLabels: was called without first calling beginMeasurementSession:");
        }
    }
}

-(void)logUploadLatency:(NSUInteger)inLatencyMilliseconds forUploadId:(NSString*)inUploadID {
    if ( !self.isOptedOut && self.isMeasurementActive ) {
        QuantcastEvent* e = [QuantcastEvent logUploadLatency:inLatencyMilliseconds
                                                 forUploadId:inUploadID
                                               withSessionID:self.currentSessionID
                                             enforcingPolicy:self.dataManager.policy];
        
        [self recordEvent:e];
    }
}



#pragma mark - Geo Location Handling
@synthesize geoCountry, geoProvince, geoCity;

-(BOOL)geoLocationEnabled {
    return _geoLocationEnabled;
}

-(void)setGeoLocationEnabled:(BOOL)inGeoLocationEnabled {
    
    Class geoCoderClass = NSClassFromString(@"CLGeocoder");
    
    if ( nil != geoCoderClass ) {
        CLAuthorizationStatus authStatus = [CLLocationManager authorizationStatus];
        
        _geoLocationEnabled = inGeoLocationEnabled && ( authStatus == kCLAuthorizationStatusNotDetermined || authStatus == kCLAuthorizationStatusAuthorized );
        
        if (_geoLocationEnabled) {
            [self startGeoLocationMeasurement];
        }
        else {
            [self stopGeoLocationMeasurement];
        }
        
    }
    
}

-(void)startGeoLocationMeasurement {
    self.geoCountry = nil;
    self.geoProvince = nil;
    self.geoCity = nil;
    
    if ( !self.isOptedOut && self.geoLocationEnabled ) {
        if (self.enableLogging) {
            NSLog(@"QC Measurement: Enabling geo-location measurement.");
        }
        // turn it on
        if (nil == self.locationManager) {
            self.locationManager = [[[CLLocationManager alloc] init] autorelease];
            self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
            self.locationManager.delegate = self;
        }
        
        [self.locationManager startMonitoringSignificantLocationChanges];
        
    }
}

-(void)stopGeoLocationMeasurement {
    if (self.enableLogging) {
        NSLog(@"QC Measurement: Disabling geo-location measurement.");
    }
    self.geoCountry = nil;
    self.geoProvince = nil;
    self.geoCity = nil;
    
    [self.locationManager stopMonitoringSignificantLocationChanges];
}

-(void)pauseGeoLocationMeasurement {
    if ( self.geoLocationEnabled && nil != self.locationManager ) {
        [self.locationManager stopMonitoringSignificantLocationChanges];
    }
}

-(void)resumeGeoLocationMeasurment {
    if ( self.geoLocationEnabled && nil != self.locationManager ) {
        [self.locationManager startMonitoringSignificantLocationChanges];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation
#pragma clang diagnostic pop
{
    // pre-iOS 6 version of this method
    
    NSArray* locationList = [NSArray arrayWithObject:newLocation];
    
    [self locationManager:manager didUpdateLocations:locationList];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if ([locations count] == 0 ) {
        if (self.enableLogging) {
            NSLog( @"QC Measurement: WARNING - locationManager:didUpdateLocations: Got a zero-lengthed locations list. Doing nothing");
        }
        
        return;
    }
    
    CLLocation* newLocation = [locations objectAtIndex:0];
    
    if (nil == self.geocoder ) {
        self.geocoder = [[[CLGeocoder alloc] init] autorelease];
    }
    
    
    if ( !self.geocoder.geocoding ) {
        [self.geocoder reverseGeocodeLocation:newLocation 
                            completionHandler:^(NSArray* inPlacemarkList, NSError* inError) {
                                if ( nil == inError && [inPlacemarkList count] > 0 && !self.isOptedOut && self.isMeasurementActive ) {
                                    CLPlacemark* placemark = (CLPlacemark*)[inPlacemarkList objectAtIndex:0];
                                    
                                    self.geoCountry = [placemark country];
                                    self.geoProvince = [placemark administrativeArea];
                                    self.geoCity = [placemark locality];
                                    
                                    [self generateGeoEventWithCurrentLocation];
                                }
                                else {
                                    self.geoCountry = nil;
                                    self.geoProvince = nil;
                                    self.geoCity = nil;
                                   
                                }
                                
                            } ];
        
    
    
    }
    
}

-(void)generateGeoEventWithCurrentLocation {
    if (!self.isOptedOut && self.geoLocationEnabled) {
        
        if ( nil != self.geoCountry || nil != self.geoProvince || nil != self.geoCity ) {
            
            
            QuantcastEvent* e = [QuantcastEvent geolocationEventWithCountry:self.geoCountry
                                                                   province:self.geoProvince
                                                                       city:self.geoCity
                                                              withSessionID:self.currentSessionID
                                                            enforcingPolicy:self.dataManager.policy ];
            
            [self recordEvent:e];
            
        }
        
        
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    if (self.enableLogging) {
        NSLog(@"QC Measurement: The location manager failed with error = %@", error );
    }
    
    self.geoCountry = nil;
    self.geoProvince = nil;
    self.geoCity = nil;
    
}

#pragma mark - User Privacy Management
@synthesize isOptedOut=_isOptedOut;

+(BOOL)isOptedOutStatus {
    
    // check Quantcast opt-out status
    
    UIPasteboard* optOutPastboard = [UIPasteboard pasteboardWithName:QCMEASUREMENT_OPTOUT_PASTEBOARD create:NO];
    
    // if there is no pasteboard, the user has not opted out
    if (nil != optOutPastboard) {
        optOutPastboard.persistent = YES;

        // if there is a pastboard, check the contents to verify opt-out status.
        if ( [QCMEASUREMENT_OPTOUT_STRING compare:[optOutPastboard string]] == NSOrderedSame ) {
            return YES;
        }
    }
    
    return NO;
}

-(void)setOptOutStatus:(BOOL)inOptOutStatus {
    
    if ( _isOptedOut != inOptOutStatus ) {
        _isOptedOut = inOptOutStatus;
        
        self.dataManager.isOptOut = inOptOutStatus;

        if ( inOptOutStatus ) {
            // setting the data manager to opt out will cause the cache directory to be emptied. No need to do further work here deleting files.
            
            // set data in pastboard to persist opt-out status and communicate with other apps using Quantcast Measurement
            UIPasteboard* optOutPastboard = [UIPasteboard pasteboardWithName:QCMEASUREMENT_OPTOUT_PASTEBOARD create:YES];
            optOutPastboard.persistent = YES;
            [optOutPastboard setString:QCMEASUREMENT_OPTOUT_STRING];
            
            
            // stop the various services
            
            [self stopGeoLocationMeasurement];
            [self stopReachabilityNotifier];
            [self appendUserAgent:NO];
            [self setOptOutCookie:YES];
        }
        else {
            // remove opt-out pastboard if it exists
            [UIPasteboard removePasteboardWithName:QCMEASUREMENT_OPTOUT_PASTEBOARD];
            
            // if the opt out status goes to NO (meaning we can do measurement), begin a new session
            [self beginMeasurementSessionWithAPIKey:self.quantcastAPIKey labels:@"OPT-IN"];
            
            [self startGeoLocationMeasurement];
            [self startReachabilityNotifier];
            [self setOptOutCookie:NO];
        }
    }
    
}

-(void)setOptOutCookie:(BOOL)add {
    if( add ) {
        NSHTTPCookie* optOutCookie = [NSHTTPCookie cookieWithProperties:@{NSHTTPCookieDomain : @".quantserve.com", NSHTTPCookiePath : @"/", NSHTTPCookieName: @"qoo", NSHTTPCookieValue: @"OPT_OUT", NSHTTPCookieExpires : [NSDate dateWithTimeIntervalSinceNow:60*60*24*365*10]}];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:optOutCookie];
    }
    else {
        for(NSHTTPCookie* cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]){
            if([cookie.name isEqualToString:@"qoo"] && [cookie.domain isEqualToString:@".quantserve.com"]) {
                [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
                break;
            }
        }
    }
    
}

-(void)displayUserPrivacyDialogOver:(UIViewController*)inCurrentViewController withDelegate:(id<QuantcastOptOutDelegate>)inDelegate {
 
    QuantcastOptOutViewController* optOutController = [[[QuantcastOptOutViewController alloc] initWithMeasurement:self delegate:inDelegate] autorelease];
    
    optOutController.modalPresentationStyle = UIModalPresentationFormSheet;
    
    if ([inCurrentViewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        [inCurrentViewController presentViewController:optOutController animated:YES completion:NULL];
    }
    else {
        // pre-iOS 5
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [inCurrentViewController presentModalViewController:optOutController animated:YES];
#pragma GCC diagnostic warning "-Wdeprecated-declarations"
    }

}

#pragma mark - SDK Customization
@synthesize uploadEventCount;

-(NSUInteger)uploadEventCount {
    if ( nil != self.dataManager ) {
        return self.dataManager.uploadEventCount;
    }
    
    return uploadEventCount;
}

-(void)setUploadEventCount:(NSUInteger)inUploadEventCount {
    
    if ( inUploadEventCount > 1 ){
        if ( nil != self.dataManager ) {
            self.dataManager.uploadEventCount = inUploadEventCount;
        }
        
        uploadEventCount = inUploadEventCount;
    }
    else {
        NSLog( @"QC Measurement: ERROR - Tried to set uploadEventCount to disallowed value %d", inUploadEventCount );
    }
}


#pragma mark - Debugging
@synthesize enableLogging=_enableLogging;

-(void)setEnableLogging:(BOOL)inEnableLogging {
    _enableLogging = inEnableLogging;
    
    self.dataManager.enableLogging=inEnableLogging;
}

- (NSString *)description {
    NSString* descStr = [NSString stringWithFormat:@"<QuantcastMeasurement %p: data manager = %@>", self, self.dataManager];
    
    return descStr;
}

-(void)logSDKError:(NSString*)inSDKErrorType withError:(NSError*)inErrorOrNil errorParameter:(NSString*)inErrorParametOrNil {
    if ( !self.isOptedOut && self.isMeasurementActive ) {

        QuantcastEvent* e = [QuantcastEvent logSDKError:inSDKErrorType withErrorObject:inErrorOrNil errorParameter:inErrorParametOrNil withSessionID:self.currentSessionID enforcingPolicy:self.dataManager.policy];
        
        [self recordEvent:e];
    }
    
}


@end
