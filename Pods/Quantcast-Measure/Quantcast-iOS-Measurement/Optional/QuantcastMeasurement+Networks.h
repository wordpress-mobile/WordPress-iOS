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


#import "QuantcastMeasurement.h"

/*!
 @class QuantcastMeasurement+Networks
 @abstract This extension to QuantcastMeasurement allows app networks and platforms to quantify all of their network app traffic while still permitting individual apps to be indepently quantify, even under a seperate network.
 @discussion This class extenison should only be used by app networks, most notably app platforms, app development shops, and companies with a large number of branded apps where they want to maintain the app's brand when quantifing but still have the app traffic attributed to a parent network. Entities quantifying a single app or a number of apps under the same network should not use the Networks extension. If what is described as a "network integration" doesn't make sense to you, it is likely that you should not use the Network integration.
 
 The Networks extension adds the ability to identify a parent network, referred to as an "attributed network", for each app in addition to or instead of the app's API Key. However, only apps with an API Key will get a full profile on Quantcast.com. Apps without an API Key or an API Key from a different network will (additionally) have their activity attributed to the attributed (parent) network as "syndicated app traffic", contributing to the parent network's overall network traffic and demographics. Furthermore, the Networks extension allows the assignment of app-specific and network-specifc labels. App-specific labels will be used to create audience segments under the network of the API Key of the app. Network labels will be used to create audience segments under the attributed network of the app. If the API Key's network and the attributed network are the same, then app labels and network labels will both create audience segments under that network.
 */

/*
 Detailed Implmentation Notes
 ----------------------------
 
 To implement the Networks extension, you should use the methods desclared under this Networks category rather than their original form equivalents from QuantcastMeasurment.h. You must ust the four-point minimum "begin measurement" integration rather than the single point "setup measurement" integration. The mapping the original form methods to the Networks replacement is:
 
    Original Form Method                                       --> Networks Extension Method
 
    beginMeasurementSessionWithAPIKey:userIdentifier:labels:   --> beginMeasurementSessionWithAPIKey:attributedNetwork:userIdentifier:appLabels:networkLabels:appIsDirectedAtChildren:
    beginMeasurementSessionWithAPIKey:labels:                  --> beginMeasurementSessionWithAPIKey:attributedNetwork:userIdentifier:appLabels:networkLabels:appIsDirectedAtChildren:
    setupMeasurementSessionWithAPIKey:userIdentifier:labels:   --> beginMeasurementSessionWithAPIKey:attributedNetwork:userIdentifier:appLabels:networkLabels:appIsDirectedAtChildren:
    endMeasurementSessionWithLabels:                           --> endMeasurementSessionWithAppLabels:networkLabels:
    pauseSessionWithLabels:                                    --> pauseSessionWithAppLabels:networkLabels:
    resumeSessionWithLabels:                                   --> resumeSessionWithAppLabels:networkLabels:
    recordUserIdentifier:withLabels:                           --> recordUserIdentifier:withAppLabels:networkLabels:
    logEvent:withLabels:                                       --> logEvent:withAppLabels:networkLabels:
 
 All mehtods listed above will generate an error if you mix usage of Original Form Methods with Networks Extension Methods.
 
 */
@interface QuantcastMeasurement (Networks)

/*!
 @property networkLabels
 @abstract Property that contains a static network labels
 @discussion This property can be set to either an NSString or an NSArray of NSStrings.  When set, the label(s) will be automatically passed to all calls which take network labels.  This is a convience property for applications that segment their audience by a fairly static group of labels.   This property can be changed at any time.
 */
@property (retain,nonatomic) id<NSObject> networkLabels;

/*!
 @method beginMeasurementSessionWithAPIKey:attributedNetwork:userIdentifier:appLabels:networkLabels:appIsDirectedAtChildren:
 @abstract Starts a Quantcast Measurement session for a network integration and records the user identifier that should be used for this session at the same time.
 @discussion Start a Quantcast Measurement session for a Network integration. No network-based method in the Quantcast Measurement API will work until this method is called. Must be called first, preferably in the UIApplication delegate's application:didFinishLaunchingWithOptions: method. This method allows you to simultaneously start a session and recurd the user identifier at the same time. If the user identifier is available at the start of the sesion, it is prefered that this method be called rather than passing nil in the userIdentifier argument and then the recordUserIdentifier: method.
 @param inQuantcastAPIKeyOrNil The Quantcast API key that activity for this app should be reported under. Obtain this key from the Quantcast website. This value may be nil iff a Network P-code is passed. If the API Key is nil, all activity for this app will be attributed to the network (p-code) as syndicated app traffic.
 @param inNetworkPCode The Quantcast p-code (of the form "p-aBcDeFgHi0123") for the network that this app's traffic should be attributed to in addition to the API Key (if passed). Must not be nil. If no network p-code is available, your Quantcast integration should use one of the "begin measurement" methods found in QuantcastMeasurement.h.
 @param inUserIdentifierOrNil a user identifier string that is meanigful to the app publisher. This is usually a user login name or anything that identifies the user (different from a device id), but there is no requirement on format of this other than that it is a meaningful user identifier to you and unique to each user of your app. Quantcast will immediately one-way hash this value, thus not recording it in its raw form. You should pass nil to indicate that there is no user identifier available, either at the start of the session or at all.
 @param inAppLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event for the app's API Key. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, you might use one of two labels in your app: one for user who ave not purchased an app upgrade, and one for users who have purchased an upgrade.
 @param inNetworkLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event for the network's p-code. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, a network or many apps might use labels to indicate the kinds of app, or to indicate clients the apps were built for.
 @param appIsDirectedAtChildren A boolean indicating whether the app is known to be directed at children under the age of 13 or not (YES means the app is known to be directed at children). Some jurisdictions, most notably the Unite States, has laws limiting what data may be collected by apps if the app is directed at children. The information passed in this argument will be combined with any configution provided by the app owner for this app at Quantcast.com to craft a dynamic data privacy policy that is most appropiate for the current laws and best practices of the jurisdiction the app user is currently in.
 @result The hashed version of the uer identifier passed on to Quantcast. You do not need to take any action with this. It is only returned for your reference. nil will be returned if the user has opted out or an error occurs.
 */
-(NSString*)beginMeasurementSessionWithAPIKey:(NSString*)inQuantcastAPIKeyOrNil
                            attributedNetwork:(NSString*)inNetworkPCode
                               userIdentifier:(NSString*)inUserIdentifierOrNil
                                    appLabels:(id<NSObject>)inAppLabelsOrNil
                                networkLabels:(id<NSObject>)inNetworkLabelsOrNil
                      appIsDirectedAtChildren:(BOOL)inIsAppDirectedAtChildren;


/*!
 @method endMeasurementSessionWithAppLabels:networkLabels:
 @abstract Ends a Quantcast Measurement session and closes all conections (Network form).
 @discussion Returns the Quantcast Measurement SDK to the state it was in prior the the beginMeasurementSessionWithAPIKey:attributedNetwork:userIdentifier:appLabels:networkLabels:appIsDirectedAtChildren: call. This method should only be used in conjunction with a Network integration.  Ideally, this method is called from the UIApplication delegate's applicationWillTerminate: method.
 @param inAppLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event for the app's API Key. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, you might use one of two labels in your app: one for user who ave not purchased an app upgrade, and one for users who have purchased an upgrade.
 @param inNetworkLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event for the network's p-code. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, a network or many apps might use labels to indicate the kinds of apps, or to indicate client an app was built for.
 */
-(void)endMeasurementSessionWithAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabelsOrNil;

/*!
 @method pauseSessionWithAppLabels:networkLabels:
 @abstract Pauses the Quantcast Measurement Session (Network form).
 @discussion Temporarily suspends the operations of the Quantcast Measurement API. This method should only be used in conjunction with a Network integration. Ideally, this method is called from the UIApplication delegate's applicationDidEnterBackground: method.
 @param inAppLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event for the app's API Key. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, you might use one of two labels in your app: one for user who ave not purchased an app upgrade, and one for users who have purchased an upgrade.
 @param inNetworkLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event for the network's p-code. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, a network or many apps might use labels to indicate the kinds of apps, or to indicate client an app was built for.
 */
-(void)pauseSessionWithAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabelsOrNil;

/*!
 @method resumeSessionWithAppLabels:networkLabels:
 @abstract Resumes the Quantcast Measurement Session (Network Form).
 @discussion Resumes the operations of the Quantcast Measurement API after it was suspended. This method should only be used in conjunction with a Network integration. Ideally, this method is called from the UIApplication delegate's applicationWillEnterForeground: method.
 @param inAppLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event for the app's API Key. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, you might use one of two labels in your app: one for user who ave not purchased an app upgrade, and one for users who have purchased an upgrade.
 @param inNetworkLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event for the network's p-code. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, a network or many apps might use labels to indicate the kinds of apps, or to indicate client an app was built for.
 */
-(void)resumeSessionWithAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabelsOrNil;

/*!
 @method recordUserIdentifier:withAppLabels:networkLabels:
 @abstract Records the user identifier that should be used for this session (Network form).
 @discussion This feature is only useful if you implement a similar (hashed) user identifier recording with Quantcast Measurement on other platforms, such as the web. This method should only be used in conjunction with a Network integration. This method only needs to be called once per session, preferably immediately after the session has begun, or when the user identifier has changed (e.g., the user logged out and a new user logged in). Quantcast will use a one-way hash to encode the user identifier and record the results of that one-way hash, not what is passed here. The method will return the results of that one-way hash for your reference. You do not need to take any action on the results.
 @param inUserIdentifierOrNil a user identifier string that is meanigful to the app publisher. This is usually a user login name or anything that identifies the user (different from a device id), but there is no requirement on format of this other than that it is a meaningful user identifier to you. Quantcast will immediately one-way hash this value, thus not recording it in its raw form. You should pass nil to indicate that a user has logged out.
 @param inAppLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event for the app's API Key. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, you might use one of two labels in your app: one for user who ave not purchased an app upgrade, and one for users who have purchased an upgrade.
 @param inNetworkLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event for the network's p-code. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, a network or many apps might use labels to indicate the kinds of apps, or to indicate client an app was built for.
 @result The hashed version of the uer identifier passed on to Quantcast. You do not need to take any action with this. It is only returned for your reference. nil will be returned if the user has opted out or an error occurs.
 */
-(NSString*)recordUserIdentifier:(NSString*)inUserIdentifierOrNil withAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabelsOrNil;

/*!
 @method logEvent:withAppLabels:networkLabels:
 @abstract Logs an arbitray app event to the Quantcast Measurement SDK (Network form).
 @discussion This is the primarily means for logging events with Quantcast Measurement. What gets logged in this method is completely up to the app developper.
 @param inEventName A string that identifies the event being logged. Hierarchical information can be indicated by using a left-to-right notation with a period as a seperator. For example, logging one event named "button.left" and another named "button.right" will create three reportable items in Quantcast App Measurement: "button.left", "button.right", and "button". There is no limit on the cardinality that this hierarchal scheme can create, though low-frequency events may not have an audience report on due to the lack of a statistically significant population. This method should only be used in conjunction with a Network integration. 
 @param inAppLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event for the app's API Key. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, you might use one of two labels in your app: one for user who ave not purchased an app upgrade, and one for users who have purchased an upgrade.
 @param inNetworkLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event for the network's p-code. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, a network or many apps might use labels to indicate the kinds of apps, or to indicate client an app was built for.
 */
-(void)logEvent:(NSString*)inEventName withAppLabels:(id<NSObject>)inAppLabelsOrNil networkLabels:(id<NSObject>)inNetworkLabelsOrNil;



/*!
 @method logNetworkEvent:withNetworkLabels:
 @abstract Logs an arbitray network event to the Quantcast Measurement SDK.
 @discussion This is the primarily means for logging Network events with Quantcast Measurement. Events logged via this method will only be reported against the attributed network.
 @param inNetworkEventName A string that identifies the event being logged. Hierarchical information can be indicated by using a left-to-right notation with a period as a seperator. For example, logging one event named "button.left" and another named "button.right" will create three reportable items in Quantcast App Measurement: "button.left", "button.right", and "button". There is no limit on the cardinality that this hierarchal scheme can create, though low-frequency events may not have an audience report on due to the lack of a statistically significant population. This method should only be used in conjunction with a Network integration.
 @param inNetworkLabelsOrNil  Either an NSString object or NSArray object containing one or more NSString objects, each of which are a distinct label to be applied to this event for the network's p-code. A label is any arbitrary string that you want to be ascociated with this event, and will create a second dimension in Quantcast Measurement reporting. Nominally, this is a "user class" indicator. For example, a network or many apps might use labels to indicate the kinds of apps, or to indicate client an app was built for.
 */
-(void)logNetworkEvent:(NSString*)inNetworkEventName withNetworkLabels:(id<NSObject>)inNetworkLabelsOrNil;


@end
