#import <Foundation/Foundation.h>

// General
extern NSString *const StatsEventAppClosed;
extern NSString *const StatsEventAppOpenedDueToPushNotification;

// Super Properties

// General
extern NSString *const StatsSuperPropertyNumberOfTimesOpenedReader;
extern NSString *const StatsSuperPropertyNumberOfTimesOpenedNotifications;
extern NSString *const StatsSuperPropertyNumberOfTimesOpenedStats;
extern NSString *const StatsSuperPropertyNumberOfTimesOpenedViewAdmin;

// Reader
extern NSString *const StatsSuperPropertyNumberOfItemsOpenedInReader;
extern NSString *const StatsSuperPropertyNumberOfItemsLikedInReader;
extern NSString *const StatsSuperPropertyNumberOfItemsUnlikedInReader;
extern NSString *const StatsSuperPropertyNumberOfItemsRebloggedInReader;

// Sharing
extern NSString *const StatsSuperPropertyNumberOfItemsShared;
extern NSString *const StatsSuperPropertyNumberOfItemsSharedViaEmail;
extern NSString *const StatsSuperPropertyNumberOfItemsSharedViaSMS;
extern NSString *const StatsSuperPropertyNumberOfItemsSharedViaTwitter;
extern NSString *const StatsSuperPropertyNumberOfItemsSharedViaFacebook;
extern NSString *const StatsSuperPropertyNumberOfItemsSharedViaWeibo;
extern NSString *const StatsSuperPropertyNumberOfItemsSentToPocket;
extern NSString *const StatsSuperPropertyNumberOfItemsSentToInstapaper;
extern NSString *const StatsSuperPropertyNumberOfItemsSentToGooglePlus;

// Notifications
extern NSString *const StatsSuperPropertyNumberOfTimesOpenedNotificationDetails;
extern NSString *const StatsSuperPropertyNumberOfNotificationsResultingInActions;
extern NSString *const StatsSuperPropertyNumberOfNotificationsRepliedTo;
extern NSString *const StatsSuperPropertyNumberOfNotificationsApproved;
extern NSString *const StatsSuperPropertyNumberOfNotificationsUnapproved;
extern NSString *const StatsSuperPropertyNumberOfNotificationsTrashed;
extern NSString *const StatsSuperPropertyNumberOfNotificationsUntrashed;
extern NSString *const StatsSuperPropertyNumberOfNotificationsFlaggedAsSpam;
extern NSString *const StatsSuperPropertyNumberOfNotificationsUnflaggedAsSpam;
extern NSString *const StatsSuperPropertyNumberOfNotificationsResultingInAFollow;
extern NSString *const StatsSuperPropertyNumberOfNotificationsResultingInAnUnfollow;

// Posts
extern NSString *const StatsSuperPropertyNumberOfPostsPublished;
extern NSString *const StatsSuperPropertyNumberOfPostsUpdated;
extern NSString *const StatsSuperPropertyNumberOfPhotosAddedToPosts;
extern NSString *const StatsSuperPropertyNumberOfVideosAddedToPosts;
extern NSString *const StatsSuperPropertyNumberOfFeaturedImagesAssignedToPosts;
extern NSString *const StatsSuperPropertyNumberOfPostsWithPhotos;
extern NSString *const StatsSuperPropertyNumberOfPostsWithVideos;
extern NSString *const StatsSuperPropertyNumberOfPostsWithCategories;
extern NSString *const StatsSuperPropertyNumberOfPostsWithTags;



@interface WPMobileStats : NSObject

+ (void)initializeStats;

+ (void)pauseSession;

+ (void)recordAppOpenedForEvent:(NSString *)event;
+ (void)trackEventForSelfHostedAndWPCom:(NSString *)event;
+ (void)trackEventForSelfHostedAndWPCom:(NSString *)event properties:(NSDictionary *)properties;
+ (void)trackEventForSelfHostedAndWPComWithSavedProperties:(NSString *)event;
+ (void)trackEventForWPCom:(NSString *)event;
+ (void)trackEventForWPCom:(NSString *)event properties:(NSDictionary *)properties;
+ (void)trackEventForWPComWithSavedProperties:(NSString *)event;
+ (void)pingWPComStatsEndpoint:(NSString *)statName;

/*
    Mixpanel has both properties and super properties which should be used differently depending on the
    circumstance. A property in general can be attached to any event, so for example an event with
    the title "Opened from External Source" can have a property "external_source" which identifies the
    source of the event. Properties are useful to attach to events because they allow us to drill down
    into certain events with more detail. Super properties are different from properties in that super
    properties are attached to *every* event that gets sent up to Mixpanel. Things that you might
    use as super properties are perhaps certain things that you want to track across events that may
    help you determine certain patterns in the app. For example 'number_of_blogs' is a super property
    attached to every single event.
 */
+ (void)clearPropertiesForAllEvents;
+ (void)incrementProperty:(NSString *)property forEvent:(NSString *)event;
+ (void)setValue:(id)value forProperty:(NSString *)property forEvent:(NSString *)event;
+ (void)flagProperty:(NSString *)property forEvent:(NSString *)event;
+ (void)unflagProperty:(NSString *)property forEvent:(NSString *)event;


+ (void)flagSuperProperty:(NSString *)property;
+ (void)incrementSuperProperty:(NSString *)property;
+ (void)setValue:(id)value forSuperProperty:(NSString *)property;

+ (void)flagPeopleProperty:(NSString *)property;
+ (void)incrementPeopleProperty:(NSString *)property;
+ (void)setValue:(id)value forPeopleProperty:(NSString *)property;

+ (void)flagPeopleAndSuperProperty:(NSString *)property;
+ (void)incrementPeopleAndSuperProperty:(NSString *)property;
+ (void)setValue:(id)value forPeopleAndSuperProperty:(NSString *)property;

@end
