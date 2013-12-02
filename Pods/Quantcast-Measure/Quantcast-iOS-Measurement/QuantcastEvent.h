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

-(void)putAppLabels:(id<NSObject>)inAppLabelsObjectOrNil networkLabels:(id<NSObject>)inNetworkLabelsObjectOrNil enforcingPolicy:(QuantcastPolicy*)inPolicyOrNil;

#pragma mark - JSON conversion

-(NSString*)JSONStringEnforcingPolicy:(QuantcastPolicy*)inPolicyOrNil;

#pragma mark - Debugging
@property (assign,nonatomic) BOOL enableLogging;

- (NSString *)description;

#pragma mark - Event Factory

+(QuantcastEvent*)eventWithSessionID:(NSString*)inSessionID
                applicationInstallID:(NSString*)inAppInstallID
                     enforcingPolicy:(QuantcastPolicy*)inPolicy;


+(QuantcastEvent*)openSessionEventWithClientUserHash:(NSString*)inHashedUserIDOrNil
                                    newSessionReason:(NSString*)inReason
                                      connectionType:(NSString*)connectionType
                                           sessionID:(NSString*)inSessionID
                                     quantcastAPIKey:(NSString*)inQuantcastAPIKey
                               quantcastNetworkPCode:(NSString*)inQuantcastNetworkPCode
                                    deviceIdentifier:(NSString*)inDeviceID
                                appInstallIdentifier:(NSString*)inAppInstallID
                                     enforcingPolicy:(QuantcastPolicy*)inPolicy
                                      eventAppLabels:(id<NSObject>)inEventAppLabelsOrNil
                                  eventNetworkLabels:(id<NSObject>)inEventNetworkLabelsOrNil
                                             carrier:(CTCarrier*)inCarrier;

+(QuantcastEvent*)closeSessionEventWithSessionID:(NSString*)inSessionID 
                            applicationInstallID:(NSString*)inAppInstallID
                                 enforcingPolicy:(QuantcastPolicy*)inPolicy
                                  eventAppLabels:(id<NSObject>)inEventAppLabelsOrNil
                              eventNetworkLabels:(id<NSObject>)inEventNetworkLabelsOrNil;

+(QuantcastEvent*)pauseSessionEventWithSessionID:(NSString*)inSessionID
                            applicationInstallID:(NSString*)inAppInstallID
                                 enforcingPolicy:(QuantcastPolicy*)inPolicy
                                  eventAppLabels:(id<NSObject>)inEventAppLabelsOrNil
                              eventNetworkLabels:(id<NSObject>)inEventNetworkLabelsOrNil;

+(QuantcastEvent*)resumeSessionEventWithSessionID:(NSString*)inSessionID 
                             applicationInstallID:(NSString*)inAppInstallID
                                  enforcingPolicy:(QuantcastPolicy*)inPolicy
                                   eventAppLabels:(id<NSObject>)inEventAppLabelsOrNil
                               eventNetworkLabels:(id<NSObject>)inEventNetworkLabelsOrNil;


+(QuantcastEvent*)logEventEventWithEventName:(NSString*)inEventName
                              eventAppLabels:(id<NSObject>)inEventAppLabelsOrNil
                          eventNetworkLabels:(id<NSObject>)inEventNetworkLabelsOrNil
                                   sessionID:(NSString*)inSessionID
                        applicationInstallID:(NSString*)inAppInstallID
                             enforcingPolicy:(QuantcastPolicy*)inPolicy;

+(QuantcastEvent*)logNetworkEventEventWithEventName:(NSString*)inEventName
                                 eventNetworkLabels:(id<NSObject>)inEventNetworkLabelsOrNil
                                          sessionID:(NSString*)inSessionID
                               applicationInstallID:(NSString*)inAppInstallID
                                    enforcingPolicy:(QuantcastPolicy*)inPolicy;

+(QuantcastEvent*)logUploadLatency:(NSUInteger)inLatencyMilliseconds
                       forUploadId:(NSString*)inUploadID
                     withSessionID:(NSString*)inSessionID 
              applicationInstallID:(NSString*)inAppInstallID
                   enforcingPolicy:(QuantcastPolicy*)inPolicy;

+(QuantcastEvent*)geolocationEventWithCountry:(NSString*)inCountry
                                     province:(NSString*)inProvince
                                         city:(NSString*)inCity
                               eventTimestamp:(NSDate*)inTimestamp
                            appIsInBackground:(BOOL)inIsAppInBackground
                                withSessionID:(NSString*)inSessionID
                         applicationInstallID:(NSString*)inAppInstallID
                              enforcingPolicy:(QuantcastPolicy*)inPolicy;

+(QuantcastEvent*)networkReachabilityEventWithConnectionType:(NSString*)connectionType
                                               withSessionID:(NSString*)inSessionID
                                        applicationInstallID:(NSString*)inAppInstallID
                                             enforcingPolicy:(QuantcastPolicy*)inPolicy;

+(QuantcastEvent*)logSDKError:(NSString*)inSDKErrorType
              withErrorObject:(NSError*)inErrorDescOrNil
               errorParameter:(NSString*)inErrorParametOrNil
                withSessionID:(NSString*)inSessionID
         applicationInstallID:(NSString*)inAppInstallID
              enforcingPolicy:(QuantcastPolicy*)inPolicy;


@end
