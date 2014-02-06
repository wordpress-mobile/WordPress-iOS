/*
 * Copyright 2013 Quantcast Corp.
 *
 * This software is licensed under the Quantcast Mobile App Measurement Terms of Service
 * https://www.quantcast.com/learning-center/quantcast-terms/mobile-app-measurement-tos
 * (the “License”). You may not use this file unless (1) you sign up for an account at
 * https://www.quantcast.com and click your agreement to the License and (2) are in
 * compliance with the License. See the License for the specific language governing
 * permissions and limitations under the License.
 *
 */

#if QCMEASUREMENT_ENABLE_GEOMEASUREMENT

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "QuantcastEventLogger.h"

/*!
 @class QuantcastGeoManager
 @internal
 */

@interface QuantcastGeoManager : NSObject <CLLocationManagerDelegate>
@property (assign,nonatomic) BOOL geoLocationEnabled;
@property (assign,nonatomic) BOOL enableLogging;
@property (readonly,nonatomic) BOOL isGeoMonitoringActive;

-(id)initWithEventLogger:(id<QuantcastEventLogger>)inEventLogger enableLogging:(BOOL)inEnableLogging;


-(void)handleAppPause;
-(void)handleAppResume;

-(void)privacyPolicyUpdate:(NSNotification*)inNotification;

@end

#endif