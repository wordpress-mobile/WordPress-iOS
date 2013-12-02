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

#ifndef QCMEASUREMENT_ENABLE_JSONKIT
#define QCMEASUREMENT_ENABLE_JSONKIT 0
#endif

#import <CoreTelephony/CTCarrier.h>
#import "QuantcastPolicy.h"
#import "QuantcastParameters.h"
#import "QuantcastUtils.h"
#import "QuantcastMeasurement.h"

#if QCMEASUREMENT_ENABLE_JSONKIT
#import "JSONKit.h"
#endif

#define QCMEASUREMENT_DO_NOT_SALT_STRING    @"MSG"

@interface QuantcastMeasurement ()
// declare "private" method here
-(void)logSDKError:(NSString*)inSDKErrorType withError:(NSError*)inErrorOrNil errorParameter:(NSString*)inErrorParametOrNil;
-(CTCarrier*)getCarrier;
@end

@interface QuantcastPolicy ()

-(void)setPolicywithJSONData:(NSData*)inJSONData;
-(void)networkReachabilityChanged:(NSNotification*)inNotification;
-(void)startPolicyDownloadWithURL:(NSURL*)inPolicyURL;
-(void)sendPolicyLoadNotification;

@end


@implementation QuantcastPolicy
@synthesize deviceIDHashSalt=_didSalt;
@synthesize isMeasurementBlackedout=_isMeasurementBlackedout;
@synthesize hasPolicyBeenLoaded=_policyHasBeenLoaded;
@synthesize hasUpdatedPolicyBeenDownloaded=_policyHasBeenDownloaded;
@synthesize sessionPauseTimeoutSeconds=_sessionTimeout;

-(id)initWithPolicyURL:(NSURL*)inPolicyURL reachability:(id<QuantcastNetworkReachability>)inNetworkReachabilityOrNil enableLogging:(BOOL)inEnableLogging {
    self = [super init];
    
    if (self) {
        enableLogging = inEnableLogging;
        
        _sessionTimeout = QCMEASUREMENT_DEFAULT_MAX_SESSION_PAUSE_SECOND;
        
        _policyHasBeenLoaded = NO;
        _policyHasBeenDownloaded = NO;
        _waitingForUpdate = NO;
        
        _allowGeoMeasurement = NO;
        _desiredGeoLocationAccuracy = 10.0;
        _geoMeasurementUpdateDistance = 50.0;

       // first, determine if there is a saved polciy on disk, if not, create it with default polciy
        NSString* cacheDir = [QuantcastUtils quantcastCacheDirectoryPath];
        
        NSString* policyFilePath = [cacheDir stringByAppendingPathComponent:QCMEASUREMENT_POLICY_FILENAME];
        
        NSFileManager* fileManager = [NSFileManager defaultManager];
        
        NSData* policyData = nil;
        
        if ( [fileManager fileExistsAtPath:policyFilePath] ) {
            
            policyData = [NSData dataWithContentsOfFile:policyFilePath];
            
            if ( (nil != policyData) && ([policyData length] != 0) ){
                [self setPolicywithJSONData:policyData];
            }
        }
                                                              
        //
        // Now set up for a download of policy 
        _policyURL = [inPolicyURL retain];
            
        [self downloadLatestPolicyWithReachability:inNetworkReachabilityOrNil];
    }
    
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_blacklistedParams release];
    if ( nil!= _downloadConnection) {
        [_downloadConnection cancel];
        [_downloadConnection release];
    }
    [_downloadData release];
    [_policyURL release];
    [_didSalt release];
    
    [super dealloc];
}

-(void)downloadLatestPolicyWithReachability:(id<QuantcastNetworkReachability>)inNetworkReachabilityOrNil {
    if ( nil != inNetworkReachabilityOrNil && nil != _policyURL && !_waitingForUpdate) {
        
        _waitingForUpdate = YES;
        
        
        // if the network is available, check to see if there is a new
        
        if ([inNetworkReachabilityOrNil currentReachabilityStatus] != QuantcastNotReachable ) {
            [self startPolicyDownloadWithURL:_policyURL];
        }
        else {
            
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkReachabilityChanged:) name:kQuantcastNetworkReachabilityChangedNotification object:inNetworkReachabilityOrNil];
        }
    }
    
}

-(void)setPolicywithJSONData:(NSData*)inJSONData {
    
    if ( nil == inJSONData ) {
        NSLog(@"QC Measurement: ERROR - Tried to set policy with a nil JSON data object.");
        @synchronized(self){
            _policyHasBeenLoaded = NO;
            _policyHasBeenDownloaded = NO;
        }
        return;
    }
    
    NSDictionary* policyDict = nil;
    NSError* jsonError = nil;
    
    // try to use NSJSONSerialization first. check to see if class is available (iOS 5 or later)
    Class jsonClass = NSClassFromString(@"NSJSONSerialization");
    
    if ( nil != jsonClass ) {
        policyDict = [jsonClass JSONObjectWithData:inJSONData
                                           options:NSJSONReadingMutableLeaves
                                             error:&jsonError];
    }
#if QCMEASUREMENT_ENABLE_JSONKIT 
    else if(nil != NSClassFromString(@"JSONDecoder")) {
        // try with JSONKit
       policyDict = [[JSONDecoder decoder] objectWithData:inJSONData error:&jsonError];
    }
#endif
    else {
        NSLog( @"QC Measurement: ERROR - There is no available JSON decoder to user. Please enable JSONKit in your project!" );
        @synchronized(self){
            _policyHasBeenLoaded = NO;
            _policyHasBeenDownloaded = NO;
        }
        return;
    }

    
    if ( nil != jsonError ) {
        NSString* jsonStr = [[[NSString alloc] initWithData:inJSONData
                                                   encoding:NSUTF8StringEncoding] autorelease];

        NSLog(@"QC Measurement: Unable to parse policy JSON data. error = %@, json = %@", jsonError, jsonStr);
        @synchronized(self){
            _policyHasBeenLoaded = NO;
            _policyHasBeenDownloaded = NO;
        }
        return;
    }
    
    @synchronized(self) {
    
        [_blacklistedParams release];
        _blacklistedParams = nil;
        
        if (nil != policyDict) {
            NSArray* blacklistedParams = [policyDict objectForKey:@"blacklist"];
            
            if ( nil != blacklistedParams && [blacklistedParams count] > 0 ) {
                _blacklistedParams = [[NSSet setWithArray:blacklistedParams] retain];
            }
            
            id saltObj = [policyDict objectForKey:@"salt"];
            
            if ( nil != saltObj && [saltObj isKindOfClass:[NSString class]] ) {
                NSString* saltStr = (NSString*)saltObj;
                
                _didSalt = [saltStr retain];
             }
            else if ( nil != saltObj && [saltObj isKindOfClass:[NSNumber class]] ) {
                NSNumber* saltNum = (NSNumber*)saltObj;
                
                _didSalt = [[saltNum stringValue] retain];
            }
            else {
                _didSalt = nil;
            }
            
            if ( _didSalt != nil && [QCMEASUREMENT_DO_NOT_SALT_STRING compare:_didSalt] == NSOrderedSame) {
                [_didSalt release];
                _didSalt = nil;
            }
            
            
            id blackoutTimeObj = [policyDict objectForKey:@"blackout"];
            
            if ( nil != blackoutTimeObj && [blackoutTimeObj isKindOfClass:[NSString class]]) {
                NSString* blackoutTimeStr = (NSString*)blackoutTimeObj;
                int64_t blackoutValue; // this value will be in terms of milliseconds since Jan 1, 1970
                
                if ( nil != blackoutTimeStr && [[NSScanner scannerWithString:blackoutTimeStr] scanLongLong:&blackoutValue]) {
                    NSDate* blackoutTime = [NSDate dateWithTimeIntervalSince1970:( (NSTimeInterval)blackoutValue/1000.0 )];
                    NSDate* nowTime = [NSDate date];
                    
                    // check to ensure that nowTime is greater than blackoutTime 
                    if ( [nowTime compare:blackoutTime] == NSOrderedDescending ) {
                        _isMeasurementBlackedout = NO;
                    }
                    else {
                        _isMeasurementBlackedout = YES;
                    }
                    
                }
                else {
                    _isMeasurementBlackedout = NO;
                }
            }
            else if ( nil != blackoutTimeObj && [blackoutTimeObj isKindOfClass:[NSNumber class]] ) {
                int64_t blackoutValue = [(NSNumber*)blackoutTimeObj longLongValue];
                
                NSDate* blackoutTime = [NSDate dateWithTimeIntervalSince1970:( (NSTimeInterval)blackoutValue/1000.0 )];
                NSDate* nowTime = [NSDate date];
                
                // check to ensure that nowTime is greater than blackoutTime 
                if ( [nowTime compare:blackoutTime] == NSOrderedDescending ) {
                    _isMeasurementBlackedout = NO;
                }
                else {
                    _isMeasurementBlackedout = YES;
                }
            }
            else {
                _isMeasurementBlackedout = NO;
            }
            
            id sessionTimeOutObj = [policyDict objectForKey:@"sessionTimeOutSeconds"];
            _sessionTimeout = QCMEASUREMENT_DEFAULT_MAX_SESSION_PAUSE_SECOND;
            
            if ( nil != sessionTimeOutObj && [sessionTimeOutObj isKindOfClass:[NSString class]]) {
                NSString* timeoutStr = (NSString*)sessionTimeOutObj;
                int64_t timeoutValue; // this value will be in terms of milliseconds since Jan 1, 1970
                
                if ( nil != timeoutStr && [[NSScanner scannerWithString:timeoutStr] scanLongLong:&timeoutValue]) {
                    
                    _sessionTimeout = timeoutValue;
                }
            }
            else if ( nil != sessionTimeOutObj && [sessionTimeOutObj isKindOfClass:[NSNumber class]] ) {
                _sessionTimeout = [(NSNumber*)sessionTimeOutObj doubleValue];
            }
            
            _allowGeoMeasurement = [QuantcastPolicy booleanValueForJSONObject:[policyDict objectForKey:@"allowGeoMeasurement"] defaultValue:YES];
            _desiredGeoLocationAccuracy = [QuantcastPolicy doubleValueForJSONObject:[policyDict objectForKey:@"desiredGeoLocationAccuracy"] defaultValue:10.0];
            _geoMeasurementUpdateDistance = [QuantcastPolicy doubleValueForJSONObject:[policyDict objectForKey:@"geoMeasurementUpdateDistance"] defaultValue:50.0];
            
            _policyHasBeenLoaded = YES;
            
            [self sendPolicyLoadNotification];
        }
    }
}

-(void)sendPolicyLoadNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:QUANTCAST_NOTIFICATION_POLICYLOAD object:self];
}

+(BOOL)booleanValueForJSONObject:(id)inJSONObject defaultValue:(BOOL)inDefaultValue {
    
    if ( nil != inJSONObject ) {
        if ( [inJSONObject isKindOfClass:[NSString class]] ) {
            NSSet* trueValues = [NSSet setWithArray:@[ @"YES", @"TRUE", @"yes", @"true", @"1"]];
                                 
            return [trueValues containsObject:inJSONObject];
        }
        else if ( [inJSONObject isKindOfClass:[NSNumber class]] ) {
            NSNumber* value = (NSNumber*)inJSONObject;
            
            return [value boolValue];
        }
    }

    return inDefaultValue;
}

+(double)doubleValueForJSONObject:(id)inJSONObject defaultValue:(double)inDefaultValue {
    if ( nil != inJSONObject ) {
        if ( [inJSONObject isKindOfClass:[NSString class]] ) {
            double value = inDefaultValue;
            
            if ( [[NSScanner scannerWithString:(NSString*)inJSONObject] scanDouble:&value] ) {
                return value;
            }
        }
        else if ( [inJSONObject isKindOfClass:[NSNumber class]] ) {
            NSNumber* value = (NSNumber*)inJSONObject;
            
            return [value doubleValue];
        }
    }
    
    return inDefaultValue;
}

#pragma mark - Policy Values

-(BOOL)isBlacklistedParameter:(NSString*)inParamName {
    
    BOOL isBlacklisted = NO;
    
    @synchronized(self) {
        isBlacklisted = [_blacklistedParams containsObject:inParamName];
    }
    
    return isBlacklisted;
}

-(BOOL)allowGeoMeasurement {
    return _allowGeoMeasurement;
}

-(double)desiredGeoLocationAccuracy {
    return _desiredGeoLocationAccuracy;
}

-(double)geoMeasurementUpdateDistance {
    return _geoMeasurementUpdateDistance;
}

#pragma mark - Download Handling

-(void)networkReachabilityChanged:(NSNotification*)inNotification {
    
    id<QuantcastNetworkReachability> reachabilityObj = (id<QuantcastNetworkReachability>)[inNotification object];
    
    
    if ([reachabilityObj currentReachabilityStatus] != QuantcastNotReachable ) {
        [self startPolicyDownloadWithURL:_policyURL];
    }
  
}

-(void)startPolicyDownloadWithURL:(NSURL*)inPolicyURL {
    
    if ( nil != inPolicyURL ) {
                
        @synchronized(self) {
            if ( nil == _downloadConnection ) {

                if (self.enableLogging) {
                    NSLog(@"QC Measurement: Starting policy download with URL = %@", inPolicyURL);
                }

                NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:inPolicyURL
                                                                       cachePolicy:NSURLRequestReloadIgnoringLocalCacheData 
                                                                   timeoutInterval:QCMEASUREMENT_CONN_TIMEOUT_SECONDS];
                
                
                _downloadData = [[NSMutableData dataWithCapacity:512] retain];
                _downloadConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
            }
        }
        
    }
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ( nil == _downloadData ) {
        NSLog(@"QC Measurement: Error downloading policy JSON from connection %@, download data object has gone nil", connection );
        
        [connection cancel];
        
        return;
    }
        
    @synchronized(self) {
        [_downloadData setLength:0];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if ( nil == _downloadData ) {
        NSLog(@"QC Measurement: Error downloading policy JSON from connection %@, download data object has gone nil", connection );
        
        [connection cancel];
        
        return;
    }

    @synchronized(self) {
        [_downloadData appendData:data];
    }
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    
    [[QuantcastMeasurement sharedInstance] logSDKError:QC_SDKERRORTYPE_POLICYDOWNLOADFAILURE
                                             withError:error
                                        errorParameter:_policyURL.description];

    if (self.enableLogging) {
        NSLog(@"QC Measurement: Error downloading policy JSON from connection %@, error = %@", connection, error );
    }

    @synchronized(self) {
        [_downloadConnection release];
        _downloadConnection = nil;
        
        [_downloadData release];
        _downloadData = nil;

        _waitingForUpdate = NO;
    }

}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    
    NSData* policyData = nil;
    
    @synchronized(self) {
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];

        policyData = [_downloadData retain];
        [_downloadData release];
        _downloadData = nil;
        
        [_downloadConnection release];
        _downloadConnection = nil;

        
        [self setPolicywithJSONData:policyData];
        // check to see if the policy succesfully loaded
        
        if ( self.hasPolicyBeenLoaded ) {
            _policyHasBeenDownloaded = YES;
            _waitingForUpdate = NO;
        }
        else {
            // download failed for somereason. don't bother trying to download again this session, but do log an error.
            NSLog(@"QC Measurement: ERROR - Successfully downloaded policy data but failed to load into into policy object.");

            _policyHasBeenDownloaded = NO;
            _waitingForUpdate = NO;
        }
        
    }
    
    // save the policy data to a file (outside of the mutex)
    if (nil != policyData) {
        if ( self.hasUpdatedPolicyBeenDownloaded ) {
           
            if (self.enableLogging) {
                NSString* jsonStr = [[[NSString alloc] initWithData:policyData
                                                           encoding:NSUTF8StringEncoding] autorelease];
                
                NSLog(@"QC Measurement: Successfully downloaded policy with json = %@", jsonStr);
            }

            // first, determine if there is a saved policy on disk, if not, create it with default polciy
            NSString* cacheDir = [QuantcastUtils quantcastCacheDirectoryPath];
            
            NSString* policyFilePath = [cacheDir stringByAppendingPathComponent:QCMEASUREMENT_POLICY_FILENAME];
            
            NSFileManager* fileManager = [NSFileManager defaultManager];
            
            BOOL fileWriteSuccess = [fileManager createFileAtPath:policyFilePath contents:_downloadData attributes:nil];
            
            if ( !fileWriteSuccess && self.enableLogging ) {
                NSLog(@"QC Measurement: ERROR - Could not create downloaded policy JSON at path = %@",policyFilePath);
            }
            
        }
        else {
            NSString* jsonStr = [[[NSString alloc] initWithData:policyData
                                                       encoding:NSUTF8StringEncoding] autorelease];
            
            NSLog(@"QC Measurement: ERROR - Failed to load downloaded policy with json = %@", jsonStr);
        }
      
        [policyData release];
    }

}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    [QuantcastUtils handleConnection:connection didReceiveAuthenticationChallenge:challenge withTrustedHost:[_policyURL host] loggingEnabled:self.enableLogging];

}


#pragma mark - Policy Factory
#ifndef QCMEASUREMENT_POLICY_URL_FORMAT_APIKEY
#define QCMEASUREMENT_POLICY_URL_FORMAT_APIKEY      @"http://m.quantcount.com/policy.json?a=%@&v=%@&t=%@&c=%@"
#endif
#ifndef QCMEASUREMENT_POLICY_URL_FORMAT_PKID
#define QCMEASUREMENT_POLICY_URL_FORMAT_PKID        @"http://m.quantcount.com/policy.json?p=%@&n=%@&v=%@&t=%@&c=%@"
#endif
#define QCMEASUREMENT_POLICY_PARAMETER_CHILD        @"&k=YES"

+(QuantcastPolicy*)policyWithAPIKey:(NSString*)inQuantcastAPIKey networkPCode:(NSString*)inNetworkPCode networkReachability:(id<QuantcastNetworkReachability>)inReachability carrier:(CTCarrier*)carrier appIsDirectAtChildren:(BOOL)inAppIsDirectedAtChildren enableLogging:(BOOL)inEnableLogging {
    
    NSURL* policyURL = [QuantcastPolicy generatePolicyRequestURLWithAPIKey:inQuantcastAPIKey networkPCode:inNetworkPCode carrier:carrier appIsDirectAtChildren:inAppIsDirectedAtChildren enableLogging:inEnableLogging];
    
    if (inEnableLogging) {
        NSLog(@"QC Measurement: Creating policy object with policy URL = %@", policyURL);
    }
        
    return [[[QuantcastPolicy alloc] initWithPolicyURL:policyURL reachability:inReachability enableLogging:inEnableLogging] autorelease];
}

/*!
 @method generatePolicyRequestURLWithAPIKey:networkReachability:carrier:appIsDirectAtChildren:enableLogging:
 @internal
 @abstract Gerates a URL for downlaiding the most appropiate privacy policy for this app.
 @param inQuantcastAPIKey The declared API Key for this app. May be nil, in which case the app's bundle identifier is used.
 @param inReachability used to determine the country the device is in
 @param inAppIsDirectedAtChildren Whether the app has declared itself as directed at children under 13 or not. This is typically only used (that is, not NO) for network/platform integrations. Directly quantified apps (apps with an API Key) should declare their "directed at children under 13" status at the Quantcast.com website.
 @param inEnableLogging whether logging is enabled
 */
+(NSURL*)generatePolicyRequestURLWithAPIKey:(NSString*)inQuantcastAPIKey networkPCode:(NSString*)inNetworkPCode carrier:(CTCarrier*)inCarrier appIsDirectAtChildren:(BOOL)inAppIsDirectedAtChildren enableLogging:(BOOL)inEnableLogging {
    NSString* mcc = nil;
    
    if ( nil != inCarrier ) {
        
        
        // Get mobile country code
        NSString* countryCode = [inCarrier isoCountryCode];
        
        if ( nil != countryCode ) {
            mcc = countryCode;
        }
    }
    
    // if the cellular country is not available, use locale country as a proxy
    if ( nil == mcc ) {
        NSLocale* locale = [NSLocale currentLocale];
        
        NSString* localeCountry = [locale objectForKey:NSLocaleCountryCode];
        
        if ( nil != localeCountry ) {
            mcc = [localeCountry uppercaseString];
        }
        else {
            // country is unknown
            mcc = @"XX";
        }
    }
    
    NSString* osString = @"IOS";
    
    NSString* osVersion = [[UIDevice currentDevice] systemVersion];
    
    if ([osVersion compare:@"4.0" options:NSNumericSearch] == NSOrderedAscending) {
        NSLog(@"QC Measurement: Unable to support iOS version %@",osVersion);
        return nil;
    }
    else if ([osVersion compare:@"5.0" options:NSNumericSearch] == NSOrderedAscending) {
        osString = @"IOS4";
    }
    else if ([osVersion compare:@"6.0" options:NSNumericSearch] == NSOrderedAscending) {
        osString = @"IOS5";
    }
    else {
        osString = @"IOS";
    }
    
    NSString* policyURLStr = nil;
    
    if ( nil != inQuantcastAPIKey ) {
        policyURLStr = [NSString stringWithFormat:QCMEASUREMENT_POLICY_URL_FORMAT_APIKEY,inQuantcastAPIKey,QCMEASUREMENT_API_VERSION,osString,[mcc uppercaseString]];
    }
    else {
        NSString* appBundleID = [[NSBundle mainBundle] bundleIdentifier];
        
        policyURLStr = [NSString stringWithFormat:QCMEASUREMENT_POLICY_URL_FORMAT_PKID,[QuantcastUtils urlEncodeString:appBundleID],inNetworkPCode,QCMEASUREMENT_API_VERSION,osString,[mcc uppercaseString]];
    }
    
    if ( inAppIsDirectedAtChildren ) {
        policyURLStr = [policyURLStr stringByAppendingString:QCMEASUREMENT_POLICY_PARAMETER_CHILD];
        
    }
    
    NSURL* policyURL =  [QuantcastUtils updateSchemeForURL:[NSURL URLWithString:policyURLStr]];

    return policyURL;
}

#pragma mark - Debugging Support
@synthesize enableLogging;

@end
