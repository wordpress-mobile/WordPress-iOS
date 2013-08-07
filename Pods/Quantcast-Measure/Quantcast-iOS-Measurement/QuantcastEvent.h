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

#import <UIKit/UIKit.h>
#import <CoreTelephony/CTCarrier.h>
#import "QuantcastNetworkReachability.h"

@class QuantcastPolicy;

/*!
 @class QuantcastEvent
 @internal
 */
@interface QuantcastEvent : NSObject {
    
    NSDate* _timestamp;
    NSString* _sessionID;
    
    NSMutableDictionary* _parameters;
    
}
@property (readonly) NSDate* timestamp;
@property (readonly) NSString* sessionID;

// time stamp is set to the current time
-(id)initWithSessionID:(NSString*)inSessionID;
-(id)initWithSessionID:(NSString*)inSessionID timeStamp:(NSDate*)inTimeStamp;


#pragma mark - Parameter Management
@property (readonly) NSDictionary* parameters;

-(void)putParameter:(NSString*)inParamKey withValue:(id)inValue enforcingPolicy:(QuantcastPolicy*)inPolicyOrNil;
-(id)getParameter:(NSString*)inParamKey;

-(void)putLabels:(id<NSObject>)inLabelsObjectOrNil enforcingPolicy:(QuantcastPolicy*)inPolicyOrNil;

#pragma mark - JSON conversion

-(NSString*)JSONStringEnforcingPolicy:(QuantcastPolicy*)inPolicyOrNil;

#pragma mark - Debugging
@property (assign,nonatomic) BOOL enableLogging;

- (NSString *)description;

#pragma mark - Event Factory

+(QuantcastEvent*)eventWithSessionID:(NSString*)inSessionID
                     enforcingPolicy:(QuantcastPolicy*)inPolicy;


+(QuantcastEvent*)openSessionEventWithClientUserHash:(NSString*)inHashedUserIDOrNil
                                    newSessionReason:(NSString*)inReason
                                       networkStatus:(QuantcastNetworkStatus)inNetworkStatus
                                           sessionID:(NSString*)inSessionID
                                     quantcastAPIKey:(NSString*)inQuantcastAPIKey
                                    deviceIdentifier:(NSString*)inDeviceID
                                appInstallIdentifier:(NSString*)inAppInstallID
                                     enforcingPolicy:(QuantcastPolicy*)inPolicy
                                         eventLabels:(id<NSObject>)inEventLabelsOrNil
                                             carrier:(CTCarrier*)carrier;

+(QuantcastEvent*)closeSessionEventWithSessionID:(NSString*)inSessionID 
                                 enforcingPolicy:(QuantcastPolicy*)inPolicy
                                     eventLabels:(id<NSObject>)inEventLabelsOrNil;

+(QuantcastEvent*)pauseSessionEventWithSessionID:(NSString*)inSessionID 
                                 enforcingPolicy:(QuantcastPolicy*)inPolicy
                                     eventLabels:(id<NSObject>)inEventLabelsOrNil;

+(QuantcastEvent*)resumeSessionEventWithSessionID:(NSString*)inSessionID 
                                  enforcingPolicy:(QuantcastPolicy*)inPolicy
                                      eventLabels:(id<NSObject>)inEventLabelsOrNil;


+(QuantcastEvent*)logEventEventWithEventName:(NSString*)inEventName
                                 eventLabels:(id<NSObject>)inEventLabelsOrNil   
                                   sessionID:(NSString*)inSessionID 
                             enforcingPolicy:(QuantcastPolicy*)inPolicy;

+(QuantcastEvent*)logUploadLatency:(NSUInteger)inLatencyMilliseconds
                       forUploadId:(NSString*)inUploadID
                     withSessionID:(NSString*)inSessionID 
                   enforcingPolicy:(QuantcastPolicy*)inPolicy;

+(QuantcastEvent*)geolocationEventWithCountry:(NSString*)inCountry
                                     province:(NSString*)inLocality
                                         city:(NSString*)inCity
                                withSessionID:(NSString*)inSessionID 
                              enforcingPolicy:(QuantcastPolicy*)inPolicy;



+(QuantcastEvent*)networkReachabilityEventWithNetworkStatus:(QuantcastNetworkStatus)inNetworkStatus
                                              withSessionID:(NSString*)inSessionID
                                            enforcingPolicy:(QuantcastPolicy*)inPolicy;

+(QuantcastEvent*)logSDKError:(NSString*)inSDKErrorType
              withErrorObject:(NSError*)inErrorDescOrNil
               errorParameter:(NSString*)inErrorParametOrNil
                withSessionID:(NSString*)inSessionID
              enforcingPolicy:(QuantcastPolicy*)inPolicy;


@end
