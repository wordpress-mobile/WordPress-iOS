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

#import <CoreTelephony/CTCarrier.h>
#import <Foundation/Foundation.h>
#import "QuantcastNetworkReachability.h"

/*!
 @class QuantcastPolicy
 @internal
 */

#define QUANTCAST_NOTIFICATION_POLICYLOAD @"quantcast-privacy-policy-load"

@interface QuantcastPolicy : NSObject <NSURLConnectionDataDelegate> {
    NSSet* _blacklistedParams;
    NSString* _didSalt;
    BOOL _isMeasurementBlackedout;
    BOOL _allowGeoMeasurement;
    
    BOOL _policyHasBeenLoaded;
    BOOL _policyHasBeenDownloaded;
    BOOL _waitingForUpdate;
    
    double _desiredGeoLocationAccuracy;
    double _geoMeasurementUpdateDistance;
    
    NSURL* _policyURL;
    NSURLConnection* _downloadConnection;
    NSMutableData* _downloadData;
    
    NSTimeInterval _sessionTimeout;
}
@property (readonly) NSString* deviceIDHashSalt;
@property (readonly) BOOL isMeasurementBlackedout;
@property (readonly) BOOL hasPolicyBeenLoaded;
@property (readonly) BOOL hasUpdatedPolicyBeenDownloaded;
@property (readonly) NSTimeInterval sessionPauseTimeoutSeconds;
@property (readonly) BOOL allowGeoMeasurement;
@property (readonly) double desiredGeoLocationAccuracy;
@property (readonly) double geoMeasurementUpdateDistance;

-(id)initWithPolicyURL:(NSURL*)inPolicyURL reachability:(id<QuantcastNetworkReachability>)inNetworkReachabilityOrNil enableLogging:(BOOL)inEnableLogging;
-(void)downloadLatestPolicyWithReachability:(id<QuantcastNetworkReachability>)inNetworkReachabilityOrNil;

-(BOOL)isBlacklistedParameter:(NSString*)inParamName;

+(BOOL)booleanValueForJSONObject:(id)inJSONObject defaultValue:(BOOL)inDefaultValue;
+(double)doubleValueForJSONObject:(id)inJSONObject defaultValue:(double)inDefaultValue;

+(QuantcastPolicy*)policyWithAPIKey:(NSString*)inQuantcastAPIKey networkPCode:(NSString*)inNetworkPCode networkReachability:(id<QuantcastNetworkReachability>)inReachability carrier:(CTCarrier*)carrier appIsDirectAtChildren:(BOOL)inAppIsDirectedAtChildren enableLogging:(BOOL)inEnableLogging;

#pragma mark - Debugging Support
@property (assign) BOOL enableLogging;


@end
