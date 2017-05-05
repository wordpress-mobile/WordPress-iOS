#import <Foundation/Foundation.h>
#import "StatsSummary.h"
#import "StatsVisits.h"
#import "StatsStreak.h"
#import "WPStatsService.h"

typedef void (^StatsRemoteSummaryCompletion)(StatsSummary *summary, NSError *error);
typedef void (^StatsRemoteVisitsCompletion)(StatsVisits *visits, NSError *error);
typedef void (^StatsRemoteStreakCompletion)(StatsStreak *streak, NSError *error);
typedef void (^StatsRemoteItemsCompletion)(NSArray *items, NSString *totalViews, BOOL moreViewsAvailable, NSError *error);
typedef void (^StatsRemotePostDetailsCompletion)(StatsVisits *visits, NSArray *monthsYearsItems, NSArray *averagePerDayItems, NSArray *recentWeeksItems, NSError *error);
typedef void (^StatsRemoteAllTimeCompletion)(NSString *posts, NSNumber *postsValue, NSString *views, NSNumber *viewsValue, NSString *visitors, NSNumber *visitorsValue, NSString *bestViews, NSNumber *bestViewsValue, NSString *bestViewsOn, NSError *error);
typedef void (^StatsRemoteLatestPostSummaryCompletion)(NSNumber *postID, NSString *postTitle, NSString *postURL, NSDate *postDate, NSString *views, NSNumber *viewsValue, NSString *likes, NSNumber *likesValue, NSString *comments, NSNumber *commentsValue, NSError *error);
typedef void (^StatsRemoteInsightsCompletion)(NSString *highestHour, NSString *highestHourPercent, NSNumber *highestHourPercentValue, NSString *highestDayOfWeek, NSString *highestDayPercent, NSNumber *highestDayPercentValue, NSError *error);

@interface WPStatsServiceRemote : NSObject

- (instancetype)initWithOAuth2Token:(NSString *)oauth2Token siteId:(NSNumber *)siteId andSiteTimeZone:(NSTimeZone *)timeZone;

/**
 Batches all remote calls locally to retrieve stats for a particular set of dates and period.  Completion handlers are called
 
 @param date End date of period to fetch stats for
 @param unit Period unit to run stats for
 @param summaryCompletion
 @param visitsCompletion
 @param postsCompletion
 @param referrersCompletion
 @param clicksCompletion
 @param countryCompletion
 @param videosCompletion
 @param commentsCompletion items is an array of arrays = position 0 = authors, position 1 = posts (hacky)
 @param tagsCategoriesCompletion
 @param followersDotComCompletion
 @param followersEmailCompletion
 @param publicizeCompletion
 @param failureHandler
 */
- (void)batchFetchStatsForDate:(NSDate *)date
                          unit:(StatsPeriodUnit)unit
   withVisitsCompletionHandler:(StatsRemoteVisitsCompletion)visitsCompletion
       eventsCompletionHandler:(StatsRemoteItemsCompletion)eventsCompletion
        postsCompletionHandler:(StatsRemoteItemsCompletion)postsCompletion
    referrersCompletionHandler:(StatsRemoteItemsCompletion)referrersCompletion
       clicksCompletionHandler:(StatsRemoteItemsCompletion)clicksCompletion
      countryCompletionHandler:(StatsRemoteItemsCompletion)countryCompletion
       videosCompletionHandler:(StatsRemoteItemsCompletion)videosCompletion
      authorsCompletionHandler:(StatsRemoteItemsCompletion)authorsCompletion
  searchTermsCompletionHandler:(StatsRemoteItemsCompletion)searchTermsCompletion
                 progressBlock:(void (^)(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations))progressBlock
    andOverallCompletionHandler:(void (^)())completionHandler;

- (void)batchFetchInsightsStatsWithAllTimeCompletionHandler:(StatsRemoteAllTimeCompletion)allTimeCompletion
                                  insightsCompletionHandler:(StatsRemoteInsightsCompletion)insightsCompletion
                              todaySummaryCompletionHandler:(StatsRemoteSummaryCompletion)todaySummaryCompletion
                         latestPostSummaryCompletionHandler:(StatsRemoteLatestPostSummaryCompletion)latestPostCompletion
                                  commentsCompletionHandler:(StatsRemoteItemsCompletion)commentsCompletion
                            tagsCategoriesCompletionHandler:(StatsRemoteItemsCompletion)tagsCategoriesCompletion
                           followersDotComCompletionHandler:(StatsRemoteItemsCompletion)followersDotComCompletion
                            followersEmailCompletionHandler:(StatsRemoteItemsCompletion)followersEmailCompletion
                                 publicizeCompletionHandler:(StatsRemoteItemsCompletion)publicizeCompletion
                                    streakCompletionHandler:(StatsRemoteStreakCompletion)streakCompletion
                                              progressBlock:(void (^)(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations))progressBlock
                                andOverallCompletionHandler:(void (^)())completionHandler;

- (void)fetchPostDetailsStatsForPostID:(NSNumber *)postID
                 withCompletionHandler:(StatsRemotePostDetailsCompletion)completionHandler;

- (void)fetchSummaryStatsForDate:(NSDate *)date
           withCompletionHandler:(StatsRemoteSummaryCompletion)completionHandler;

- (void)fetchEventsForDate:(NSDate *)date
                   andUnit:(StatsPeriodUnit)unit
     withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler;

- (void)fetchVisitsStatsForDate:(NSDate *)date
                           unit:(StatsPeriodUnit)unit
          withCompletionHandler:(StatsRemoteVisitsCompletion)completionHandler;

- (void)fetchPostsStatsForDate:(NSDate *)date
                       andUnit:(StatsPeriodUnit)unit
         withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler;

- (void)fetchReferrersStatsForDate:(NSDate *)date
                           andUnit:(StatsPeriodUnit)unit
             withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler;

- (void)fetchClicksStatsForDate:(NSDate *)date
                        andUnit:(StatsPeriodUnit)unit
          withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler;

- (void)fetchCountryStatsForDate:(NSDate *)date
                         andUnit:(StatsPeriodUnit)unit
           withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler;

- (void)fetchVideosStatsForDate:(NSDate *)date
                        andUnit:(StatsPeriodUnit)unit
          withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler;

- (void)fetchAuthorsStatsForDate:(NSDate *)date
                         andUnit:(StatsPeriodUnit)unit
           withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler;

- (void)fetchSearchTermsStatsForDate:(NSDate *)date
                             andUnit:(StatsPeriodUnit)unit
               withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler;

- (void)fetchCommentsStatsWithCompletionHandler:(StatsRemoteItemsCompletion)completionHandler;

- (void)fetchTagsCategoriesStatsWithCompletionHandler:(StatsRemoteItemsCompletion)completionHandler;

- (void)fetchFollowersStatsForFollowerType:(StatsFollowerType)followerType
                     withCompletionHandler:(StatsRemoteItemsCompletion)completionHandler;

- (void)fetchPublicizeStatsWithCompletionHandler:(StatsRemoteItemsCompletion)completionHandler;

- (void)fetchAllTimeStatsWithCompletionHandler:(StatsRemoteAllTimeCompletion)completionHandler;

- (void)fetchInsightsWithCompletionHandler:(StatsRemoteInsightsCompletion)completionHandler;

- (void)fetchLatestPostSummaryWithCompletionHandler:(StatsRemoteLatestPostSummaryCompletion)completionHandler;

- (void)fetchStreakStatsForStartDate:(NSDate *)startDate
                          andEndDate:(NSDate *)endDate
               withCompletionHandler:(StatsRemoteStreakCompletion)completionHandler;

- (void)cancelAllRemoteOperations;

@end
