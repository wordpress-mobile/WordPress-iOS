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
#import "QuantcastMeasurement+Internal.h"
#import "QuantcastParameters.h"
#import "QuantcastDataManager.h"
#import "QuantcastEvent.h"
#import "QuantcastUtils.h"
#import "QuantcastPolicy.h"
#import "QuantcastOptOutViewController.h"
#import "QuantcastNetworkReachability.h"
#import "QuantcastOptOutDelegate.h"

#if QCMEASUREMENT_ENABLE_GEOMEASUREMENT
#import "QuantcastGeoManager.h"
#endif

QuantcastMeasurement* gSharedInstance = nil;


@interface QuantcastMeasurement () <QuantcastNetworkReachability> {
    SCNetworkReachabilityRef _reachability;
    
    NSString* _hashedUserId;
    
    BOOL _enableLogging;
    BOOL _isOptedOut;
    BOOL _geoLocationEnabled;
    
    id<NSObject> _networkLabels;
}

#if QCMEASUREMENT_ENABLE_GEOMEASUREMENT
@property (retain,nonatomic) QuantcastGeoManager* geoManager;
#endif

@property (retain,nonatomic) NSString* cachedAppInstallIdentifier;
@property (retain,nonatomic) QuantcastDataManager* dataManager;
@property (retain,nonatomic) NSString* quantcastAPIKey;
@property (retain,nonatomic) NSString* quantcastNetworkPCode;
@property (assign,nonatomic) BOOL appIsDeclaredDirectedAtChildren;
@property (retain,nonatomic) NSDate* sessionPauseStartTime;
@property (readonly,nonatomic) BOOL advertisingTrackingEnabled;
@property (retain, nonatomic) CTTelephonyNetworkInfo* telephoneInfo;
@property (readonly,nonatomic) CTCarrier* carrier;
@property (retain, nonatomic) NSString* radioAccess;
@property (retain, nonatomic) id<NSObject> setupLabels;
@property (assign,nonatomic) BOOL usesOneStep;

+(NSString*)generateSessionID;
+(NSString*)getSessionID:(BOOL)inLoadSavedIfAvailable withLogging:(BOOL)inDoLogging;
+(BOOL)isOptedOutStatus;

-(NSString*)appInstallIdentifierWithUserAdvertisingPreference:(BOOL)inAdvertisingTrackingEnabled;
-(BOOL)hasUserAdvertisingPrefChangeWithCurrentPref:(BOOL)inCurrentPref;

-(void)enableDataUploading;
-(void)recordEvent:(QuantcastEvent*)inEvent;

-(void)logUploadLatency:(NSUInteger)inLatencyMilliseconds forUploadId:(NSString*)inUploadID;
-(void)logSDKError:(NSString*)inSDKErrorType withError:(NSError*)inErrorOrNil errorParameter:(NSString*)inErrorParametOrNil;


-(void)setOptOutStatus:(BOOL)inOptOutStatus;
-(void)startNewSessionAndGenerateEventWithReason:(NSString*)inReason withAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabelsOrNil;
-(BOOL)startNewSessionIfUsersAdPrefChangedWithAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabels;
+(BOOL)validateQuantcastAPIKey:(NSString*)inQuantcastAppId quantcastNetworkPCode:(NSString*)inQuantcastNetworkPCode;

-(NSString*)setUserIdentifier:(NSString*)inUserIdentifierOrNil;

-(void)logNetworkReachability;
-(BOOL)startReachabilityNotifier;
-(void)stopReachabilityNotifier;

-(void)setGeoManagerGeoLocationEnable:(BOOL)inGeoLocationEnabled;

@end

@implementation QuantcastMeasurement
@synthesize sessionPauseStartTime;
@synthesize telephoneInfo;
@synthesize setupLabels;
@synthesize appLabels;

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
        _appIsDeclaredDirectedAtChildren = NO;
        _enableLogging = NO;
        _geoLocationEnabled = NO;
        _cachedAppInstallIdentifier = nil;
        
        // the first thing to do is determine user opt-out status, as that will guide everything else.
        _isOptedOut = [QuantcastMeasurement isOptedOutStatus];
        if (_isOptedOut) {
            [self setOptOutCookie:YES];
        }
        
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
    
#if QCMEASUREMENT_ENABLE_GEOMEASUREMENT
    self.geoLocationEnabled = NO;
    [_geoManager release];
#endif

    [sessionPauseStartTime release];
    [quantcastAPIKey release];
    
    [_dataManager release];
    [_hashedUserId release];

    [telephoneInfo release];
    [_radioAccess release];
    [_cachedAppInstallIdentifier release];
    
    [appLabels release];
    [setupLabels release];
    [_networkLabels release];
    
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
        
        ASIdentifierManager* adPrefManager = [ASIdentifierManager sharedManager];
        
        userAdvertisingPreference = adPrefManager.advertisingTrackingEnabled;
    }

    return userAdvertisingPreference;
}

-(QuantcastPolicy*)policy {
    if (nil != self.dataManager ) {
        return self.dataManager.policy;
    }
    
    return nil;
}

#pragma mark - Device Identifier
-(NSString*)deviceIdentifier {
    
    if ( self.isOptedOut ) {
        return nil;
    }
    
    NSString* udidStr = nil;
    
    Class adManagerClass = NSClassFromString(@"ASIdentifierManager");
    
    if ( nil != adManagerClass ) {
        
        ASIdentifierManager* manager = [ASIdentifierManager sharedManager];
        
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
    if ( nil == self.cachedAppInstallIdentifier ) {
        self.cachedAppInstallIdentifier = [self appInstallIdentifierWithUserAdvertisingPreference:self.advertisingTrackingEnabled];
    }
    
    return self.cachedAppInstallIdentifier;
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

-(void)recordEvent:(QuantcastEvent*)inEvent synchronously:(BOOL)sync{
    if (sync) {
        [self.dataManager recordEventSynchronouslyWithoutUpload:inEvent];
    }
    else {
        [self.dataManager recordEvent:inEvent];
    }
}

-(void)recordEvent:(QuantcastEvent*)inEvent {
    
    [self recordEvent:inEvent synchronously:NO];
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

+(NSString*)getSessionID:(BOOL)inLoadSavedIfAvailable withLogging:(BOOL)inDoLogging {
    NSString* cacheDir = [QuantcastUtils quantcastCacheDirectoryPathCreatingIfNeeded];
    NSString* sessionIdFile = [cacheDir stringByAppendingPathComponent:QCMEASUREMENT_SESSIONID_FILENAME];
   
    NSString* sessionID = nil;
    
    if ( inLoadSavedIfAvailable && [[NSFileManager defaultManager] fileExistsAtPath:sessionIdFile]) {
        NSError* readError = nil;
        
        sessionID = [NSString stringWithContentsOfFile:sessionIdFile encoding:NSUTF8StringEncoding error:&readError];
        
        if ( nil != readError ) {
            if ( inDoLogging ) {
                NSLog(@"QC Measurement: Error in loding sessions ID from file. Creating new session ID. Error = %@", readError);
            }
            sessionID = nil;
        }
        else if ( nil != sessionID && sessionID.length != 36 ) {
            if ( inDoLogging ) {
                NSLog(@"QC Measurement: Loaded improperly formated session ID from file. Creating new session ID. Bad session ID = %@", sessionID );
            }
            sessionID = nil;
        }
    }
    
    if ( nil == sessionID ) {
        sessionID = [QuantcastMeasurement generateSessionID];
        
        NSError* writeError = nil;
        
        [sessionID writeToFile:sessionIdFile atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
        
        if ( nil != writeError && inDoLogging ) {
            NSLog(@"QC Measurement: Error writing new session id '%@' to file. error = %@", sessionID, writeError );
        }
    }

    return sessionID;
}

-(BOOL)isMeasurementActive {
    return nil != self.currentSessionID;
}

-(NSString*)setupMeasurementSessionWithAPIKey:(NSString*)inQuantcastAPIKey userIdentifier:(NSString*)userIdentifierOrNil labels:(id<NSObject>)inLabelsOrNil{
    NSString* userhash = nil;
    if ( !self.isOptedOut ) {
        
        if(self.isMeasurementActive){
            NSLog(@"QC Measurement: ERROR - beginMeasurementSessionWithAPIKey was already called.  Remove all beginMeasurementSessionWithAPIKey, pauseSessionWithLabels, resumeSessionWithLabels, and endMeasurementSessionWithLabels calls when you use setupMeasurementSessionWithAPIKey.");
            return nil;
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(terminateNotification) name:UIApplicationWillTerminateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseNotification) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeNotification) name:UIApplicationWillEnterForegroundNotification object:nil];
        
        NSMutableArray* labels = [NSMutableArray array];
        if ([inLabelsOrNil isKindOfClass:[NSArray class]]) {
            [labels addObjectsFromArray:(NSArray*)inLabelsOrNil];
        }
        else if ([inLabelsOrNil isKindOfClass:[NSString class]]) {
            [labels addObject:inLabelsOrNil];
        }
        [labels addObject:@"_sdk.ios.setup"];
        self.setupLabels = [QuantcastUtils combineLabels:self.appLabels withLabels:labels];
        
        userhash = [self internalBeginSessionWithAPIKey:inQuantcastAPIKey attributedNetwork:nil userIdentifier:userIdentifierOrNil appLabels:self.setupLabels networkLabels:nil appIsDeclaredDirectedAtChildren:NO];
    }
    self.usesOneStep = YES;
    return userhash;
}

-(void)terminateNotification{
    [self endMeasurementSessionWithLabels:self.setupLabels];
}

-(void)pauseNotification{
    [self internalPauseSessionWithAppLabels:self.setupLabels networkLabels:nil];
}

-(void)resumeNotification{
    [self internalResumeSessionWithAppLabels:self.setupLabels networkLabels:nil];
}

-(void)startNewSessionAndGenerateEventWithReason:(NSString*)inReason withAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabelsOrNil {
    
    // if app is launched in background, load last saved session instead of generating a new one.
    
    BOOL isAppLaunchedInBackground = [UIApplication sharedApplication].applicationState == UIApplicationStateBackground && [inReason compare:QCPARAMETER_REASONTYPE_LAUNCH] == NSOrderedSame;
    self.currentSessionID = [QuantcastMeasurement getSessionID:isAppLaunchedInBackground withLogging:self.enableLogging];
    
    if ( nil != self.dataManager.policy ) {
        [self.dataManager.policy downloadLatestPolicyWithReachability:self];
    }
    
    if (!isAppLaunchedInBackground) {
        QuantcastEvent* e = [QuantcastEvent openSessionEventWithClientUserHash:_hashedUserId
                                                              newSessionReason:inReason
                                                                connectionType:[self connectionTypeForNetworkStatus:[self currentReachabilityStatus]]
                                                                     sessionID:self.currentSessionID
                                                               quantcastAPIKey:self.quantcastAPIKey
                                                         quantcastNetworkPCode:self.quantcastNetworkPCode
                                                              deviceIdentifier:self.deviceIdentifier
                                                          appInstallIdentifier:self.appInstallIdentifier
                                                               enforcingPolicy:self.dataManager.policy
                                                                eventAppLabels:[QuantcastUtils combineLabels:self.appLabels withLabels:inAppLabelsOrNil]
                                                            eventNetworkLabels:inNetworkLabelsOrNil
                                                                       carrier:self.carrier];
        
        
        [self recordEvent:e];
        
        [self.dataManager initiateDataUpload];
    }
    else if (self.enableLogging) {
        NSLog(@"QC Measurement: App was launched in the background. Not generating an open session event.");
    }
    
}


-(void)beginMeasurementSessionWithAPIKey:(NSString*)inQuantcastAPIKey labels:(id<NSObject>)inLabelsOrNil {
    if(self.usesOneStep){
        NSLog(@"QC Measurement: ERROR - No need to explictly call any beginMeasurementSessionWithAPIKey when setupMeasurementSessionWithAPIKey is used.");
        return;
    }
    [self internalBeginSessionWithAPIKey:inQuantcastAPIKey attributedNetwork:nil userIdentifier:nil appLabels:inLabelsOrNil networkLabels:nil appIsDeclaredDirectedAtChildren:NO];
}

-(NSString*)beginMeasurementSessionWithAPIKey:(NSString*)inQuantcastAPIKey userIdentifier:(NSString*)inUserIdentifierOrNil labels:(id<NSObject>)inLabelsOrNil {

    if(self.usesOneStep){
        NSLog(@"QC Measurement: ERROR - No need to explictly call any beginMeasurementSessionWithAPIKey when setupMeasurementSessionWithAPIKey is used.");
        return nil;
    }
    
    NSString* hashedUserID = [self internalBeginSessionWithAPIKey:inQuantcastAPIKey attributedNetwork:nil userIdentifier:inUserIdentifierOrNil appLabels:inLabelsOrNil networkLabels:nil appIsDeclaredDirectedAtChildren:NO];
    
    return hashedUserID;
}


-(void)endMeasurementSessionWithLabels:(id<NSObject>)inLabelsOrNil {
    if (self.hasNetworkIntegration) {
        NSLog(@"QC Measurement: ERROR - The direct app integration form of endMeasurementSessionWithLabels should not be called for network integrations. Please see QuantcastMeasurement+Networks.h for more information");
    }
    [self internalEndMeasurementSessionWithAppLabels:inLabelsOrNil networkLabels:nil];
}

-(void)pauseSessionWithLabels:(id<NSObject>)inLabelsOrNil {
    if (self.usesOneStep) {
        NSLog(@"QC Measurement: ERROR - No need to explictly call pauseSessionWithLabels when setupMeasurementSessionWithAPIKey is used.");
        return;
    }
    if (self.hasNetworkIntegration) {
        NSLog(@"QC Measurement: ERROR - The direct app integration form of pauseSessionWithLabels should not be called for network integrations. Please see QuantcastMeasurement+Networks.h for more information");
    }

    [self internalPauseSessionWithAppLabels:inLabelsOrNil networkLabels:nil];
        

}

-(void)resumeSessionWithLabels:(id<NSObject>)inLabelsOrNil {
    if (self.usesOneStep) {
        NSLog(@"QC Measurement: ERROR - No need to explictly call any resumeSessionWithLabels when setupMeasurementSessionWithAPIKey is used.");
        return;
    }
    if (self.hasNetworkIntegration) {
        NSLog(@"QC Measurement: ERROR - The direct app integration form of resumeSessionWithLabels should not be called for network integrations. Please see QuantcastMeasurement+Networks.h for more information");
    }

    [self internalResumeSessionWithAppLabels:inLabelsOrNil networkLabels:nil];
}


-(BOOL)startNewSessionIfUsersAdPrefChangedWithAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabels {
    if ( [self hasUserAdvertisingPrefChangeWithCurrentPref:self.advertisingTrackingEnabled]) {
        if (self.enableLogging) {
            NSLog(@"QC Measurement: The user has changed their advertising tracking preference. Adjusting identifiers and starting a new session.");
        }
        
        [self startNewSessionAndGenerateEventWithReason:QCPARAMETER_REASONTYPE_ADPREFCHANGE withAppLabels:inAppLabelsOrNil networkLabels:inNetworkLabels];
        return YES;
    }
    
    return NO;
}

+(BOOL)validateQuantcastAPIKey:(NSString*)inQuantcastAPIKeyId quantcastNetworkPCode:(NSString*)inQuantcastNetworkPCode {
    
    if ( nil == inQuantcastAPIKeyId && nil == inQuantcastNetworkPCode ) {
        NSLog(@"QC Measurement: ERROR - No Quantcast API Key or Network P-Code was passed to the SDK.");
        
        return NO;
    }
    
    if ( nil != inQuantcastAPIKeyId ) {
        NSString* apiKeyRegex = @"[a-zA-Z0-9]{16}-[a-zA-Z0-9]{16}";
        NSPredicate* checkAPIKey = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", apiKeyRegex];

        BOOL valid = [checkAPIKey evaluateWithObject:inQuantcastAPIKeyId];
        
        if ( !valid ) {
            NSLog(@"QC Measurement: ERROR - The Quantcast API Key passed to the SDK is malformed.");
            return NO;
        }
    }
    
    if ( nil != inQuantcastNetworkPCode ) {
        NSString* pcodeRegex = @"p\\-[\\-_a-zA-Z0-9]{13}";
        
        NSPredicate* checkPCode = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pcodeRegex];
        
        BOOL valid = [checkPCode evaluateWithObject:inQuantcastNetworkPCode];
        
        if ( !valid ) {
            NSLog(@"QC Measurement: ERROR - The Quantcast Network P-Code passed to the SDK is malformed.");
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Internal Session Management
-(BOOL)hasNetworkIntegration {
    return ( nil != self.quantcastNetworkPCode );
}

/*!
 @method internalBeginSessionWithAPIKey:attributedNetwork:userIdentifier:appLabels:networkLabels:appIsDirectedAtChildren:
 @internal
 @abstract Begins Quantcast Measure for Apps. Common internal method for both direct app and platform/network integrations.
 @param inQuantcastAPIKey The declared API Key for this app. May be nil, in which case inNetworkPCode must not be nil.
 @param inNetworkPCode The network p-code this app's traffic though be syndicated to. May be nil, in which case inQuantcastAPIKey must not be nil.
 @param inUserIdentifierOrNil the user identifier passed by the SDK user
 @param inAppLabelsOrNil labels that should be attributed to the app integration (API Key)
 @param inNetworkLabelsOrNil labels that should be attributed to the platform/network integration (network p-code)
 @param inAppIsDirectedAtChildren Whether the app has declared itself as directed at children under 13 or not. This is only used (that is, not NO) for network/platform integrations. Directly quantified apps (apps with an API Key) should declare their "directed at children under 13" status at the Quantcast.com website. Ultimately, this value and the Quantcast.com value will be OR'ed together to get final determination.
 */
-(NSString*)internalBeginSessionWithAPIKey:(NSString*)inQuantcastAPIKey attributedNetwork:(NSString*)inNetworkPCode userIdentifier:(NSString*)inUserIdentifierOrNil appLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabelsOrNil appIsDeclaredDirectedAtChildren:(BOOL)inAppIsDirectedAtChildren {
    // first check that app ID is proprly formatted
    
    if ( ![QuantcastMeasurement validateQuantcastAPIKey:inQuantcastAPIKey quantcastNetworkPCode:inNetworkPCode] ) {
        return nil;
    }
    
    NSString* hashedUserID = nil;
    if (nil != inUserIdentifierOrNil) {
        hashedUserID = [self setUserIdentifier:inUserIdentifierOrNil];
    }
    
    self.quantcastAPIKey = inQuantcastAPIKey;
    self.quantcastNetworkPCode = inNetworkPCode;
    self.appIsDeclaredDirectedAtChildren = inAppIsDirectedAtChildren;
    
    if ( !self.isOptedOut ) {
        [self startReachabilityNotifier];
#ifdef __IPHONE_7_0
        if ( nil != self.telephoneInfo ){
            BOOL radioNotificationExists = (&CTRadioAccessTechnologyDidChangeNotification != NULL);
            if( [telephoneInfo respondsToSelector:@selector(currentRadioAccessTechnology)] && radioNotificationExists ){
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(radioAccessChanged:) name:CTRadioAccessTechnologyDidChangeNotification object:nil];
            }
        }
#endif
        [self appendUserAgent:YES];
        
        if (nil == self.dataManager) {
            QuantcastPolicy* policy = [QuantcastPolicy policyWithAPIKey:self.quantcastAPIKey networkPCode:self.quantcastNetworkPCode networkReachability:self carrier:self.carrier appIsDirectAtChildren:inAppIsDirectedAtChildren enableLogging:self.enableLogging];
            
            
            if ( nil == policy ) {
                // policy wasn't able to be built. Stop reachability and bail, thus not activating measurement.
                [self stopReachabilityNotifier];
                
                if (self.enableLogging) {
                    NSLog(@"QC Measurement: Unable to activate measurement due to policy object being nil.");
                }
                return nil;
            }
            
            self.dataManager = [[[QuantcastDataManager alloc] initWithOptOut:self.isOptedOut policy:policy] autorelease];
            self.dataManager.enableLogging = self.enableLogging;
            self.dataManager.uploadEventCount = self.uploadEventCount;
            
#if QCMEASUREMENT_ENABLE_GEOMEASUREMENT
            if (nil == self.geoManager ) {
                self.geoManager = [[[QuantcastGeoManager alloc] initWithEventLogger:self enableLogging:self.enableLogging] autorelease];
                self.geoManager.geoLocationEnabled = self.geoLocationEnabled;
            }
#endif
            
        }
        
        [self enableDataUploading];
        
        
        [self startNewSessionAndGenerateEventWithReason:QCPARAMETER_REASONTYPE_LAUNCH withAppLabels:inAppLabelsOrNil networkLabels:inNetworkLabelsOrNil];
        
        if (self.enableLogging) {
            NSLog(@"QC Measurement: Using '%@' for upload server.",[QuantcastUtils updateSchemeForURL:[NSURL URLWithString:QCMEASUREMENT_UPLOAD_URL]]);
        }
    }
    
    return hashedUserID;
}

-(void)internalEndMeasurementSessionWithAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabels {
    if ( !self.isOptedOut  ) {
        
        if ( self.isMeasurementActive ) {
            QuantcastEvent* e = [QuantcastEvent closeSessionEventWithSessionID:self.currentSessionID applicationInstallID:self.appInstallIdentifier enforcingPolicy:self.dataManager.policy
                                                                eventAppLabels:[QuantcastUtils combineLabels:self.appLabels withLabels:inAppLabelsOrNil] eventNetworkLabels:inNetworkLabels];
            
            [self recordEvent:e];
            
#if QCMEASUREMENT_ENABLE_GEOMEASUREMENT
            self.geoManager = nil;
#endif
            
            [self stopReachabilityNotifier];
            
            self.currentSessionID = nil;
            
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
            self.setupLabels = nil;
            self.usesOneStep = NO;
        }
        else {
            NSLog(@"QC Measurement: endMeasurementSessionWithLabels: was called without first calling beginMeasurementSession:");
        }
    }
}

-(void)internalPauseSessionWithAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabels {
    
    if ( !self.isOptedOut ) {
        
        if ( self.isMeasurementActive ) {
            QuantcastEvent* e = [QuantcastEvent pauseSessionEventWithSessionID:self.currentSessionID applicationInstallID:self.appInstallIdentifier enforcingPolicy:self.dataManager.policy
                                                                eventAppLabels:[QuantcastUtils combineLabels:self.appLabels withLabels:inAppLabelsOrNil] eventNetworkLabels:inNetworkLabels];
            
            BOOL exitsOnSuspend = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIApplicationExitsOnSuspend"] boolValue];
            [self recordEvent:e synchronously:exitsOnSuspend];
            
            self.sessionPauseStartTime = [NSDate date];
            
#if QCMEASUREMENT_ENABLE_GEOMEASUREMENT
            if ( nil != self.geoManager) {
                [self.geoManager handleAppPause];
            }
#endif
            [self stopReachabilityNotifier];
            [self.dataManager initiateDataUpload];
        }
        else {
            NSLog(@"QC Measurement: pauseSessionWithLabels: was called without first calling beginMeasurementSession:");
        }
    }
}

-(void)internalResumeSessionWithAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabels {
    [self setOptOutStatus:[QuantcastMeasurement isOptedOutStatus]];
    
    if ( !self.isOptedOut ) {
        
        if ( self.isMeasurementActive ) {
            QuantcastEvent* e = [QuantcastEvent resumeSessionEventWithSessionID:self.currentSessionID applicationInstallID:self.appInstallIdentifier enforcingPolicy:self.dataManager.policy
                                                                 eventAppLabels:[QuantcastUtils combineLabels:self.appLabels withLabels:inAppLabelsOrNil] eventNetworkLabels:inNetworkLabels];
            
            [self recordEvent:e];
            
            [self startReachabilityNotifier];
            
#if QCMEASUREMENT_ENABLE_GEOMEASUREMENT
            if ( nil != self.geoManager) {
                [self.geoManager handleAppResume];
            }
#endif
            if (![self startNewSessionIfUsersAdPrefChangedWithAppLabels:inAppLabelsOrNil networkLabels:inNetworkLabels] && self.sessionPauseStartTime != nil ) {
                NSDate* curTime = [NSDate date];
                
                if ( [curTime timeIntervalSinceDate:self.sessionPauseStartTime] > self.dataManager.policy.sessionPauseTimeoutSeconds ) {
                    [self startNewSessionAndGenerateEventWithReason:QCPARAMETER_REASONTYPE_RESUME withAppLabels:inAppLabelsOrNil networkLabels:inNetworkLabels];
                    
                    if (self.enableLogging) {
                        NSLog(@"QC Measurement: Starting new session after app being paused for extend period of time.");
                    }
                }
            }
            self.sessionPauseStartTime = nil;
            
        }
        else {
            NSLog(@"QC Measurement: resumeSessionWithLabels: was called without first calling beginMeasurementSession:");
        }
    }
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
                
        
        QuantcastEvent* e = [QuantcastEvent networkReachabilityEventWithConnectionType:[self connectionTypeForNetworkStatus:[self currentReachabilityStatus]]
                                                                        withSessionID:self.currentSessionID
                                                                 applicationInstallID:self.appInstallIdentifier
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

-(NSString*)currentRadioAccess{
    return self.radioAccess;
}

#ifdef __IPHONE_7_0
-(void)radioAccessChanged:(NSNotification*) inNotification{
    self.radioAccess = self.telephoneInfo.currentRadioAccessTechnology;
    [self logNetworkReachability];
}
#endif

-(NSString*)connectionTypeForNetworkStatus:(QuantcastNetworkStatus)inNetworkStatus {
    NSString* connectionType = @"unknown";
    
    switch ( inNetworkStatus ) {
        case QuantcastReachableViaWiFi:
            connectionType = @"wifi";
            break;
        case QuantcastReachableViaWWAN:
            connectionType = self.radioAccess == nil ? @"wwan" : self.radioAccess;
            break;
        case QuantcastNotReachable:
            connectionType = @"disconnected";
            break;
        default:
            break;
    }
    
    return connectionType;
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
    if (self.hasNetworkIntegration) {
        NSLog(@"QC Measurement: ERROR - The direct app integration form of recordUserIdentifier should not be called for network integrations. Please see QuantcastMeasurement+Networks.h for more information");
    }

    return [self internalRecordUserIdentifier:inUserIdentifierOrNil withAppLabels:inLabelsOrNil networkLabels:nil];
}

-(NSString*)internalRecordUserIdentifier:(NSString*)inUserIdentifierOrNil withAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabels {
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
        [self startNewSessionAndGenerateEventWithReason:QCPARAMETER_REASONTYPE_USERHASH withAppLabels:inAppLabelsOrNil networkLabels:inNetworkLabels];
    }
    
    return hashedUserId;
}

-(void)logEvent:(NSString*)inEventName withLabels:(id<NSObject>)inLabelsOrNil {
    if (self.hasNetworkIntegration) {
        NSLog(@"QC Measurement: ERROR - The direct app integration form of logEvent should not be called for network integrations. Please see QuantcastMeasurement+Networks.h for more information");
    }

    [self internalLogEvent:inEventName withAppLabels:inLabelsOrNil networkLabels:nil];
}

-(void)internalLogEvent:(NSString*)inEventName withAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabels {

    if ( !self.isOptedOut ) {
        if (self.isMeasurementActive) {
            QuantcastEvent* e = [QuantcastEvent logEventEventWithEventName:inEventName
                                                            eventAppLabels:[QuantcastUtils combineLabels:self.appLabels withLabels:inAppLabelsOrNil]
                                                        eventNetworkLabels:inNetworkLabels
                                                                 sessionID:self.currentSessionID
                                                      applicationInstallID:self.appInstallIdentifier
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
                                        applicationInstallID:self.appInstallIdentifier
                                             enforcingPolicy:self.dataManager.policy];
        
        [self recordEvent:e];
    }
}



#pragma mark - Geo Location Handling

-(BOOL)geoLocationEnabled {
#if QCMEASUREMENT_ENABLE_GEOMEASUREMENT
    return _geoLocationEnabled;
#else
    return NO;
#endif
}

-(void)setGeoLocationEnabled:(BOOL)inGeoLocationEnabled {
    _geoLocationEnabled = inGeoLocationEnabled;
    [self setGeoManagerGeoLocationEnable:inGeoLocationEnabled];
}

-(void)setGeoManagerGeoLocationEnable:(BOOL)inGeoLocationEnabled {
#if QCMEASUREMENT_ENABLE_GEOMEASUREMENT
    if ( nil != self.geoManager ) {
        self.geoManager.geoLocationEnabled = inGeoLocationEnabled;
    }
#else
    if ( inGeoLocationEnabled) {
        NSLog(@"QC Measurement: ERROR - Tried to turn geo-measurement on but code has not been compiled. Please add '#define QCMEASUREMENT_ENABLE_GEOMEASUREMENT 1' to your pre-compiled header.");
    }
#endif
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
        
        self.cachedAppInstallIdentifier = nil;
        self.dataManager.isOptOut = inOptOutStatus;

        if ( inOptOutStatus ) {
            // setting the data manager to opt out will cause the cache directory to be emptied. No need to do further work here deleting files.
            
            // set data in pastboard to persist opt-out status and communicate with other apps using Quantcast Measurement
            UIPasteboard* optOutPastboard = [UIPasteboard pasteboardWithName:QCMEASUREMENT_OPTOUT_PASTEBOARD create:YES];
            optOutPastboard.persistent = YES;
            [optOutPastboard setString:QCMEASUREMENT_OPTOUT_STRING];
            
            // stop the various services
#if QCMEASUREMENT_ENABLE_GEOMEASUREMENT
            if ( nil != self.geoManager ) {
                [self setGeoManagerGeoLocationEnable:NO];
            }
#endif
            [self stopReachabilityNotifier];
            [self appendUserAgent:NO];
            [self setOptOutCookie:YES];
            
            if (self.usesOneStep) {
                [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
                [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
                [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
                self.setupLabels = nil;
            }
            self.currentSessionID = nil;
        }
        else {
            // remove opt-out pastboard if it exists
            [UIPasteboard removePasteboardWithName:QCMEASUREMENT_OPTOUT_PASTEBOARD];
            
            // if the opt out status goes to NO (meaning we can do measurement), begin a new session
            if (self.usesOneStep) {
                [self setupMeasurementSessionWithAPIKey:self.quantcastAPIKey userIdentifier:nil labels:@"_OPT-IN"];
            }
            else {
                [self beginMeasurementSessionWithAPIKey:self.quantcastAPIKey labels:@"_OPT-IN"];
            }
            
            if ( self.geoLocationEnabled ) {
                [self setGeoManagerGeoLocationEnable:self.geoLocationEnabled];
            }
            
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
    UINavigationController* navWrapper = [[[UINavigationController alloc] initWithRootViewController:optOutController] autorelease];
    
    navWrapper.modalPresentationStyle = UIModalPresentationFormSheet;
    if ([inCurrentViewController respondsToSelector:@selector(presentViewController:animated:completion:)]) {
        [inCurrentViewController presentViewController:navWrapper animated:YES completion:NULL];
    }
    else {
        // pre-iOS 5
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        [inCurrentViewController presentModalViewController:navWrapper animated:YES];
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
    
    self.dataManager.enableLogging = inEnableLogging;
#if QCMEASUREMENT_ENABLE_GEOMEASUREMENT
    self.geoManager.enableLogging = inEnableLogging;
#endif
}

- (NSString *)description {
    NSString* descStr = [NSString stringWithFormat:@"<QuantcastMeasurement %p: data manager = %@>", self, self.dataManager];
    
    return descStr;
}

-(void)logSDKError:(NSString*)inSDKErrorType withError:(NSError*)inErrorOrNil errorParameter:(NSString*)inErrorParametOrNil {
    if ( !self.isOptedOut && self.isMeasurementActive ) {

        QuantcastEvent* e = [QuantcastEvent logSDKError:inSDKErrorType withErrorObject:inErrorOrNil errorParameter:inErrorParametOrNil withSessionID:self.currentSessionID applicationInstallID:self.appInstallIdentifier enforcingPolicy:self.dataManager.policy];
        
        [self recordEvent:e];
    }
    
}


@end
