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

//
// ** IMPORTANT **
//
// Requires iOS 4 and Xcode 4.5 or later. 
//
// Frameworks required:
//      SystemConfiguration, Foundation, UIKit, CoreLocation, CoreTelephony
//
// Frameworks that should be weak-linked:
//      AdSupport
//
// Libraries required:
//      libz, libsqlite3
//
// Additional code repositories required is running on iOS 4 (not require for iOS 5 and later):
//      JSONKit         - https://github.com/johnezang/JSONKit
//
//      And place the following in your precompiled header:
//          #define QCMEASUREMENT_ENABLE_JSONKIT 1
//
// Additional frameworks that are required if secure data uploads (https) are desired:
//      Security
//
//      And place the following in your precompiled header:
//          #define QCMEASUREMENT_USE_SECURE_CONNECTIONS 1
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "QuantcastNetworkReachability.h"
#import "QuantcastOptOutDelegate.h"

#ifndef __IPHONE_4_0
#error "Quantcast Measurement is only available for iOS SDK 4.0 and later. "
#endif

@class QuantcastPolicy;

/*!
 @class QuantcastMeasurement
 @abstract The main interface with Quantcast's iOS App Measurement SDK
 @discussion
 */
@interface QuantcastMeasurement : NSObject <CLLocationManagerDelegate,QuantcastNetworkReachability> {
    SCNetworkReachabilityRef _reachability;
    
    NSString* _hashedUserId;
    
    BOOL _enableLogging;
    BOOL _isOptedOut;
    BOOL _geoLocationEnabled;
}

/*!
 @method sharedInstance
 @abstract Returns the Quantcast Measurement instance, creating it if necessary.
 @result The QuantcastMeasurement instance
 */
+(QuantcastMeasurement*)sharedInstance;

/*!
 @property deviceIdentifier
 @abstract The device identifier used by Quantcast Measurement. 
 @discussion Returns the device identifier used by Quantcast. A non-nil value is only available on iOS 6 or later. Will return nil if the user is opted out of Quantcast measurement, the user has turned off advertising tracking for their device, the app is running on an iOS version prior to 6.0, or if the iOS 6.0.0 advertising identifier bug is present.
 */
@property (readonly) NSString* deviceIdentifier;


/*!
 @property appInstallIdentifier
 @abstract An application scoped identifier used by Quantcast Measurement.
 @discussion Returns a unique installation identifier for this app. Will return nil if the user is opted out of Quantcast measurement. This identifier is created and managed by the Quantcast Measurement SDK, and persists only as long as the app is installed on a device, or the user opts out of Quantcast Measurement on the device.
 */
@property (readonly) NSString* appInstallIdentifier;

#pragma mark - Session Management

/*!
 @methodgroup Session Management
 */

/*!
 @method beginMeasurementSession:withLabels:
 @abstract Starts a Quantcast Measurement session. 
 @discussion Start a Quantcast Measurement session. Nothing in the Quantcast Measurement API will work until this method (or beginMeasurementSession:withUserIdentifier:labels:) is called. Must be called first, preferably in the UIApplication delegate's application:didFinishLaunchingWithOptions: method.
 @param inQuantcastAPIKey The Quantcast API key that activity for this app should be reported under. Obtain this key from the Quantcast website.
 @param inLabelsOrNil Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, you might use one of two labels in your app: one for user who ave not purchased an app upgrade, and one for users who have purchased an upgrade.
 */
-(void)beginMeasurementSessionWithAPIKey:(NSString*)inQuantcastAPIKey labels:(id<NSObject>)inLabelsOrNil;

/*!
 @method beginMeasurementSession:withUserIdentifier:labels:
 @abstract Starts a Quantcast Measurement session and records the user identifier that should be used for this session at the same time.
 @discussion Start a Quantcast Measurement session. Nothing in the Quantcast Measurement API will work until this method (or beginMeasurementSession:withLabels:) is called. Must be called first, preferably in the UIApplication delegate's application:didFinishLaunchingWithOptions: method. This form of the method allows you to simultaneously start a session and recurd the user identifier at the same time. If the user identifier is available at the start of the sesion, it is prefered that this method be called rather than consecutive calls to beginMeasurementSession:withLabels: then recordUserIdentifier:.
 @param inQuantcastAPIKey The Quantcast API key that activity for this app should be reported under. Obtain this key from the Quantcast website.
 @param inUserIdentifierOrNil a user identifier string that is meanigful to the app publisher. There is no requirement on format of this other than that it is a meaningful user identifier to you. Quantcast will immediately one-way hash this value, thus not recording it in its raw form. You should pass nil to indicate that there is no user identifier available, either at the start of the session or at all.
 @param inLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, you might use one of two labels in your app: one for user who ave not purchased an app upgrade, and one for users who have purchased an upgrade.
 @result The hashed version of the uer identifier passed on to Quantcast. You do not need to take any action with this. It is only returned for your reference. nil will be returned if the user has opted out or an error occurs.
 */

-(NSString*)beginMeasurementSessionWithAPIKey:(NSString*)inQuantcastAPIKey userIdentifier:(NSString*)inUserIdentifierOrNil labels:(id<NSObject>)inLabelsOrNil;

/*!
 @method endMeasurementSessionWithLabels:
 @abstract Ends a Quantcast Measurement session and closes all conections.
 @discussion Returns the Quantcast Measurement SDK to the state it was in prior the the beginMeasurementSession:withLabels: call. Ideally, this method is called from the UIApplication delegate's applicationWillTerminate: method.
 @param inLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, you might use one of two labels in your app: one for user who ave not purchased an app upgrade, and one for users who have purchased an upgrade.
 */
-(void)endMeasurementSessionWithLabels:(id<NSObject>)inLabelsOrNil;

/*!
 @method pauseSessionWithLabels:
 @abstract Pauses the Quantcast Measurement Session..
 @discussion Temporarily suspends the operations of the Quantcast Measurement API. Ideally, this method is called from the UIApplication delegate's applicationDidEnterBackground: method.
 @param inLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, you might use one of two labels in your app: one for user who ave not purchased an app upgrade, and one for users who have purchased an upgrade.
 */
-(void)pauseSessionWithLabels:(id<NSObject>)inLabelsOrNil;

/*!
 @method resumeSessionWithLabels:
 @abstract Resumes the Quantcast Measurement Session.
 @discussion Resumes the operations of the Quantcast Measurement API after it was suspended. Ideally, this method is called from the UIApplication delegate's applicationWillEnterForeground: method.
 @param inLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, you might use one of two labels in your app: one for user who ave not purchased an app upgrade, and one for users who have purchased an upgrade. 
 */
-(void)resumeSessionWithLabels:(id<NSObject>)inLabelsOrNil;

#pragma mark - Measurement and Analytics

/*!
 @methodgroup Measurement and Analytics
 */

/*!
 @method recordUserIdentifier:
 @abstract Records the user identifier that should be used for this session. 
 @discussion This feature is only useful if you implement a similar (hashed) user identifier recording with Quantcast Measurement on other platforms, such as the web. This method only needs to be called once per session, preferably immediately after the session has begun, or when the user identifier has changed (e.g., the user logged out and a new user logged in). Quantcast will use a one-way hash to encode the user identifier and record the results of that one-way hash, not what is passed here. The method will return the results of that one-way hash for your reference. You do not need to take any action on the results.
 @param inUserIdentifierOrNil a user identifier string. There is no requirement on format of this other than that it is a meaningful user identifier to you. Quantcast will immediately one-way hash this value, thus not recording it in its raw form. You should pass nil to indicate that a user has logged out.
 @param inLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, you might use one of two labels in your app: one for user who ave not purchased an app upgrade, and one for users who have purchased an upgrade.
 @result The hashed version of the uer identifier passed on to Quantcast. You do not need to take any action with this. It is only returned for your reference. nil will be returned if the user has opted out or an error occurs.
 */
-(NSString*)recordUserIdentifier:(NSString*)inUserIdentifierOrNil withLabels:(id<NSObject>)inLabelsOrNil;

/*!
 @method logEvent:withLabels:
 @abstract Logs an arbitray event to the Quantcast Measurement SDK.
 @discussion This is the primarily means for logging events with Quantcast Measurement. What gets logged in this method is completely up to the app developper.
 @param inEventName A string that identifies the event being logged. Hierarchical information can be indicated by using a left-to-right notation with a period as a seperator. For example, logging one event named "button.left" and another named "button.right" will create three reportable items in Quantcast App Measurement: "button.left", "button.right", and "button". There is no limit on the cardinality that this hierarchal scheme can create, though low-frequency events may not have an audience report on due to the lack of a statistically significant population.
 @param inLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, you might use one of two labels in your app: one for user who ave not purchased an app upgrade, and one for users who have purchased an upgrade.
 */
-(void)logEvent:(NSString*)inEventName withLabels:(id<NSObject>)inLabelsOrNil;

/*!
 @property geoLocationEnabled
 @abstract Property that controls whether geo-location is logged
 @discussion By default, geo-location logging is off (NO). If you wish for Quantcast to provide measurement services pertaining to the user's geo-location, you should enable (set to YES) this property shortly after starting a measurement session. In order to protect user privacy, Quantcast will not log locations any more granular than "city", and will not log device location while your app is in the background. NOTE - Geolocation measurment is only supported on iOS 5 or later. Attempting to set this property to YES on a device running iOS 4.x will have no affect. You do not have to set this property to NO in order to pause geo-location tracking when the app goes into the background, as this is done automatically by the API.
 */
@property (assign,nonatomic) BOOL geoLocationEnabled;

#pragma mark - User Privacy Management

/*!
 @methodgroup User Privacy Management
 */

/*!
 @property isOptedOut
 @abstract Indicates whether the user has opted out of Quantcast Measurement or not.
 @discussion You can use this method to determine if the user has opted out of measurement on this device either via your app or another on the device. Whether the user opted out via this app or another is not determinable as Quantcast Measurement opt out is on a per-device basis. If the user wishes to change their opt out status on their device, they must do so through the Quantcast User Privacy dialog presented with the displayUserPrivacyDialogOver:withDelegate: method. 
 */
@property (readonly,nonatomic) BOOL isOptedOut;

/*!
 @method displayUserPrivacyDialogOver:withDelegate:
 @abstract Displays the Quantcast User Privacy dialog, which enables the user to opt out of Quantcast Measurement on a device.
 @discussion Will display a model dialog that provides the user with information on Quantcast Measurement and allows them to adjust their Quantcast App Measurement privacy settings for their device. 
 @param inCurrentViewController This should be the current UIViewController. The Quantcast dialog will be displayed over this view. 
 @param inDelegateOrNil An optional object that adopts the QuantcastOptOutDelegate protocol. 
 */
-(void)displayUserPrivacyDialogOver:(UIViewController*)inCurrentViewController withDelegate:(id<QuantcastOptOutDelegate>)inDelegateOrNil;

#pragma mark - SDK Customization

/*!
 @property uploadEventCount
 @abstract The maximum number of events the SDK will retain locally before attempting to upload them to the Quantcast servers.
 @discussion This is the integer number of events the SDK will collect before initiating an upload to the Quantcast servers. Uploads that occur too often will drain the device's battery. Uploads that don't occur often enough will cause significant delays in uploading data to the Quantcast server for analysis and reporting. You may set this property to an integer value greater than or equal to 2. This value defaults to 100 if it is unset by you.
 */
 
@property (assign,nonatomic) NSUInteger uploadEventCount;

#pragma mark - Debugging

/*!
 @methodgroup Debugging
 */

/*!
 @property enableLogging
 @abstract Enables logging of important events and errors withing the Quantcast Measurement SDK
 @discussion Enabling logging provides you the developper some insight into what is happening in the Quantcast Measurement SDK. You should not release your app with debugging turned on, as it is fairly verbose.
 */
@property (assign,nonatomic) BOOL enableLogging;

/*!
 @method description
 @abstract Returns a string description of this object. Used only for debugging.
 */
- (NSString *)description;

@end
