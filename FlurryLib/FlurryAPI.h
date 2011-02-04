//
//  FlurryAPI.h
//  Flurry iPhone Analytics Agent
//
//  Copyright 2009 Flurry, Inc. All rights reserved.
//
#import <UIKit/UIKit.h>

@class CLLocationManager;
@class CLLocation;

@interface FlurryAPI : NSObject {
}

/*
 optional sdk settings that should be called before start session
 */
+ (void)setAppVersion:(NSString *)version;		// override the app version
+ (NSString *)getFlurryAgentVersion;			// get the Flurry Agent version number
+ (void)setAppCircleEnabled:(BOOL)value;		// default is NO
+ (void)setShowErrorInLogEnabled:(BOOL)value;	// default is NO
+ (void)unlockDebugMode:(NSString*)debugModeKey apiKey:(NSString *)apiKey;	// generate debug logs for Flurry support
+ (void)setPauseSecondsBeforeStartingNewSession:(int)seconds; // default is 10 seconds

/*
 start session, attempt to send saved sessions to server 
 */
+ (void)startSession:(NSString *)apiKey;

/*
 log events or errors after session has started
 */
+ (void)logEvent:(NSString *)eventName;
+ (void)logEvent:(NSString *)eventName withParameters:(NSDictionary *)parameters;
+ (void)logError:(NSString *)errorID message:(NSString *)message exception:(NSException *)exception;
+ (void)logError:(NSString *)errorID message:(NSString *)message error:(NSError *)error;

/* 
 start or end timed events
 */
+ (void)logEvent:(NSString *)eventName timed:(BOOL)timed;
+ (void)logEvent:(NSString *)eventName withParameters:(NSDictionary *)parameters timed:(BOOL)timed;
+ (void)endTimedEvent:(NSString *)eventName withParameters:(NSDictionary *)parameters;	// non-nil parameters will update the parameters

/*
 count page views
 */
+ (void)countPageViews:(id)target;		// automatically track page view on UINavigationController or UITabBarController
+ (void)countPageView;					// manually increment page view by 1

/*
 set user info
 */
+ (void)setUserID:(NSString *)userID;	// user's id in your system
+ (void)setAge:(int)age;				// user's age in years
+ (void)setGender:(NSString *)gender;	// user's gender m or f

/*
 optional session settings that can be changed after start session
 */
+ (void)setSessionReportsOnCloseEnabled:(BOOL)sendSessionReportsOnClose;	// default is YES
+ (void)setSessionReportsOnPauseEnabled:(BOOL)setSessionReportsOnPauseEnabled;	// default is YES
+ (void)setEventLoggingEnabled:(BOOL)value;		// default is YES

/* 
 create an AppCircle banner on a hook and a view parent 
 subsequent calls will return the same banner for the same hook and parent until removed with the API
 */
+ (UIView *)getHook:(NSString *)hook xLoc:(int)x yLoc:(int)y view:(UIView *)view;
/* 
 create an AppCircle banner on a hook and view parent using optional parameters 
 */
+ (UIView *)getHook:(NSString *)hook xLoc:(int)x yLoc:(int)y view:(UIView *)view attachToView:(BOOL)attachToView orientation:(NSString *)orientation canvasOrientation:(NSString *)canvasOrientation autoRefresh:(BOOL)refresh canvasAnimated:(BOOL)canvasAnimated;
/* 
 update an existing AppCircle banner with a new ad
 */
+ (void)updateHook:(UIView *)banner;
/* 
 remove an existing AppCircle banner from its hook and parent
 a new banner can be created on the same hook and parent after the existing banner is removed
 */
+ (void)removeHook:(UIView *)banner;
/*
 open the canvas without using a banner
 */
+ (void)openCatalog:(NSString *)hook canvasOrientation:(NSString *)canvasOrientation canvasAnimated:(BOOL)canvasAnimated;
/*
 refer to FlurryAdDelegate.h for delegate details
 */
+ (void)setAppCircleDelegate:(id)delegate;

@end
