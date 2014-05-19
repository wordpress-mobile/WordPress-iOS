//
//  Taplytics.h
//  Taplytics
//
//  Copyright (c) 2014 Syrp Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TaplyticsManager.h"

typedef void(^TLExperimentBlock)(NSDictionary *variables);

@protocol TaplyticsDelegate <NSObject>

@optional
/** 
 Delegate method called when an experiment is changed, use this to call runCodeExperiment:withBaseline:variations: again
 in your code to test and visually see the different code experiments. Only necessary for code experiments, visual experiments
 will update themselves.
 @param experimentName the name of the experiment
 @param variationName the name of the experiment variation, nil if Baseline
 */
- (void)taplyticsExperimentChanged:(NSString*)experimentName variationName:(NSString*)variationName;

@end


@interface Taplytics : NSObject

/**
 Start the Taplytics SDK with your api key. the api key can be found in the 'project settings' page.
 Console Logging: Taplytics will only log to the console in development builds.
 @param apiKey your api key
 */
+ (void)startTaplyticsAPIKey:(NSString*)apiKey;

/**
 Start the Taplytics SDK with your api key. the api key can be found in the 'project settings' page.
 Console Logging: Taplytics will only log to the console in development builds.
 @param apiKey your api key
 @param options taplytics options dictionary, used for testing. Options include:
            - @{@"delayLoad":@2} allows Taplytics to show your app's launch image and load its configuration for a maximum number of seconds
                on app launch. This is useful when running a code experiments on the first screen of your app, this will ensure that your users
                will get shown a variation on the first launch of your app.
            - @{@"liveUpdate":@NO} Taplytics will auto-detect an app store build or a development build. But to force production mode use @NO,
                or @YES to force live update mode for testing.
            - @{@"shakeMenu":@NO} To disable the Taplytics development mode shake menu set @NO, only use if you have your own development shake menu.
 */
+ (void)startTaplyticsAPIKey:(NSString*)apiKey options:(NSDictionary*)options;

/**
 Updates Taplytics configuration in a background fetch, only available in iOS 7. It is HIGHLY recommended to implement background fetch
 in 'application:performFetchWithCompletionHandler:' in your UIApplicationDelegate, to allow Taplytics to update its configuration regularly.
 For Example:
 
 - (void)application:(UIApplication *)app performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completeBlock {
    [Taplytics performBackgroundFetch:completeBlock];
 }
 
 @param completionBlock completion block called when fetch is complete
 */
+ (void)performBackgroundFetch:(void(^)(UIBackgroundFetchResult result))completionBlock NS_AVAILABLE_IOS(7_0);

/**
 Optionally set the taplytics delegate when you need to know when a experiment has changed. For example if you are testing 
 a code experiment on your root view and want to visually see the different variations.
 @param delegate The delegate for the receiver. The delegate must implement the TaplyticsDelegate protocol.
 */
+ (void)setTaplyticsDelegate:(id<TaplyticsDelegate>)delegate;

/**
 Run code experiment with experiment defined by experimentName, one baseline or variation block will be run synchronously.
 If the "delayLoad" option is set in the options dictionary of startTaplyticsAPIKey:options: the block will be called asynchronously
 once the Taplytics configuration has been loaded, but before the launch image is hidden.
 
 If no experiment has been defined or no configuration has been loaded the baseline block will be called. 
 Variation blocks are defined in a NSDictionary with a key of the variation name, and a value of TLExperimentBlock. For Example:
 
 [Taplytics runCodeExperiment:@"testExperiment" withBaseline:^(NSDictionary *variables) {
 
 } variations:@{@"variation1": ^(NSDictionary *variables) {
 
 }, @"variation2": ^(NSDictionary *variables) {
 
 }}];
 
 @param experimentName Name of the experiment to run
 @param baselineBlock baseline block called if experiment is in baseline variation
 @param variationNamesAndBlocks NSDictionary with keys of variation names and values of variation blocks.
 */
+ (void)runCodeExperiment:(NSString*)experimentName withBaseline:(TLExperimentBlock)baselineBlock variations:(NSDictionary*)variationNamesAndBlocks;

/**
 Report that an experiment goal has been achieved.
 @param goalName the name of the experiment goal
 */
+ (void)goalAchieved:(NSString*)goalName;

/**
 Report that an experiment goal has been achieved, optionally pass number value to track goal such as purchase revenue.
 @param goalName the name of the experiment goal
 @param value a numerical value to be tracked with the goal. For example purcahse revenue.
 */
+ (void)goalAchieved:(NSString*)goalName value:(NSNumber*)value;

/**
 DEPRECATED Start Taplytics Methods, please use startTaplyticsAPIKey:options:
 */
+ (void)startTaplyticsAPIKey:(NSString*)apiKey liveUpdate:(BOOL)liveUpdate __deprecated;

+ (void)startTaplyticsAPIKey:(NSString*)apiKey server:(TLServer)server __deprecated;

+ (void)startTaplyticsAPIKey:(NSString*)apiKey server:(TLServer)server liveUpdate:(BOOL)liveUpdate __deprecated;

@end