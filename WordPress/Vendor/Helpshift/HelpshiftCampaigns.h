/*
 *    HelpshiftCampaigns.h
 *    SDK Version 5.10.0
 *
 *    Get the documentation at http://www.helpshift.com/docs
 *
 */

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "HelpshiftCore.h"
#import "HelpshiftInbox.h"

@interface HelpshiftCampaigns : NSObject <HsApiProvider>
{
    BOOL isInitialized;
}

/**
 *  Delegate for getting callbacks related to Campaigns inbox messages.
 */
@property (weak, nonatomic) id<HelpshiftInboxDelegate> inboxDelegate;

/**
 *  Return the shared instance object of the HelpshiftCampaigns class
 *
 *  @return object of HelpshiftCampaigns class
 */
+ (HelpshiftCampaigns *) sharedInstance;

/**
 *  Add an integer property for current user
 *
 *  @param key   name of the key with which you want to associate data
 *  @param value integer value of the key
 *
 *  @return YES if property key is valid, NO otherwise
 */
+ (BOOL) addProperty:(NSString *)key withInteger:(NSInteger)value;


/**
 *  Add a string property for current user
 *
 *  @param key   name of the key with which you want to associate data
 *  @param value string value of the key
 *
 *  @return YES if property key is valid, NO otherwise
 */
+ (BOOL) addProperty:(NSString *)key withString:(NSString *)value;

/**
 *  Add a boolean property for current user
 *
 *  @param key   name of the key with which you want to associate data
 *  @param value BOOL value of the key
 *
 *  @return YES if property key is valid, NO otherwise
 */
+ (BOOL) addProperty:(NSString *)key withBoolean:(BOOL)value;

/**
 *  Add a Date property for current user
 *
 *  @param key   name of the key with which you want to associate data
 *  @param value NSDate value of the key
 *
 *  @return YES if property key is valid, NO otherwise
 */
+ (BOOL) addProperty:(NSString *)key withDate:(NSDate *)value;

/**
 *  Add multiple properties at once for the current user
 *
 *  @param keyValues A dictionary of keys and values which represent properties to be added for the current user
 *
 *  @return Array of strings which represent valid keys.
 */
+ (NSArray *) addProperties:(NSDictionary *)keyValues;

/**
 *  Show the campaigns inbox UI screen
 *
 *  @param viewController    viewController on which the Inbox UI will be presented
 *  @param optionsDictionary config options which can customize and change the behaviour of the Helpshift SDK. Currently supported flags are :
 *  presentFullScreenOniPad : Show the Inbox UI in fullscreen mode on iPad.
 */
+ (void) showInboxOnViewController:(UIViewController *)viewController withOptions:(NSDictionary *)optionsDictionary;

/**
 *  Show the campaigns inbox UI screen
 *
 *  @param viewController    viewController on which the Inbox UI will be presented
 *  @param configObject      API  config object which can customize and change the behaviour of the Helpshift SDK. Currently supported flags are :
 *  presentFullScreenOniPad : Show the Inbox UI in fullscreen mode on iPad.
 */
+ (void) showInboxOnViewController:(UIViewController *)viewController withConfig:(HelpshiftAPIConfig *)configObject;

/**
 *  Show the campaign detail screen.
 *
 *  @param messageId        Campaign id which is received in the push packet
 *  @param viewController    viewController on which Detail UI will be shown
 *  @param optionsDictionary config options which can customize and change the behaviour of the Helpshift SDK. Currently supported flags are :
 *  presentFullScreenOniPad : Show the Inbox UI in fullscreen mode on iPad.
 */
+ (void) showMessageWithId:(NSString *)messageId onViewController:(UIViewController *)viewController withOptions:(NSDictionary *)optionsDictionary;

/**
 *  Show the campaign detail screen.
 *
 *  @param campaignId        Campaign id which is received in the push packet
 *  @param viewController    viewController on which Detail UI will be shown
 *  @param configObject      API config object which can customize and change the behaviour of the Helpshift SDK. Currently supported flags are :
 *  presentFullScreenOniPad : Show the Inbox UI in fullscreen mode on iPad.
 */
+ (void) showMessageWithId:(NSString *)messageId onViewController:(UIViewController *)viewController withConfig:(HelpshiftAPIConfig *)configObject;

/**
 *  Refetch new campaigns and add them to the Inbox. This call will result in a network call being made. Applications should use this call sparingly and only when they absolutely need to.
 */
+ (void) refetchMessages;

/**
 *  Return the current count of unread campaign messages in the Inbox.
 *
 *  @return count of unread campaign messages.
 */
+ (NSInteger) getCountOfUnreadMessages;

+ (void) configureWithOptions:(NSDictionary *)configOptions;

@end
