#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "WPStatsService.h"
#import "WPStatsServiceRemote.h"
#import "StatsItem.h"
@import OCMock;

@interface WPStatsServiceRemoteMock : WPStatsServiceRemote

@end

@interface WPStatsServiceTests : XCTestCase

@property (nonatomic, strong) WPStatsService *subject;

@end

@implementation WPStatsServiceTests

- (void)setUp {
    [super setUp];
    
    self.subject = [[WPStatsService alloc] initWithSiteId:@123456 siteTimeZone:[NSTimeZone localTimeZone] oauth2Token:@"token" andCacheExpirationInterval:50 * 6];
}

- (void)tearDown {
    [super tearDown];

    self.subject = nil;
}

- (void)testCompletionHandlers {
    WPStatsServiceRemoteMock *remoteMock = [WPStatsServiceRemoteMock new];
    self.subject.remote = remoteMock;

    XCTestExpectation *visitsExpectation = [self expectationWithDescription:@"visitsExpectation"];
    XCTestExpectation *eventsExpectation = [self expectationWithDescription:@"eventsExpectation"];
    XCTestExpectation *postsExpectation = [self expectationWithDescription:@"postsExpectation"];
    XCTestExpectation *referrersExpectation = [self expectationWithDescription:@"referrersExpectation"];
    XCTestExpectation *clicksExpectation = [self expectationWithDescription:@"clicksExpectation"];
    XCTestExpectation *countryExpectation = [self expectationWithDescription:@"countryExpectation"];
    XCTestExpectation *videosExpectation = [self expectationWithDescription:@"videosExpectation"];
    XCTestExpectation *authorsExpectation = [self expectationWithDescription:@"authorsExpectation"];
    XCTestExpectation *searchTermsExpectation = [self expectationWithDescription:@"searchTermsExpectation"];
    XCTestExpectation *overallExpectation = [self expectationWithDescription:@"overallExpectation"];
    
    [self.subject retrieveAllStatsForDate:[NSDate date]
                                     unit:StatsPeriodUnitDay
              withVisitsCompletionHandler:^(StatsVisits *visits, NSError *error) {
                  [visitsExpectation fulfill];
              }
                  eventsCompletionHandler:^(StatsGroup *group, NSError *error) {
                      [eventsExpectation fulfill];
                  }
                   postsCompletionHandler:^(StatsGroup *group, NSError *error) {
                       [postsExpectation fulfill];
                   }
               referrersCompletionHandler:^(StatsGroup *group, NSError *error) {
                   [referrersExpectation fulfill];
               }
                  clicksCompletionHandler:^(StatsGroup *group, NSError *error) {
                      [clicksExpectation fulfill];
                  }
                 countryCompletionHandler:^(StatsGroup *group, NSError *error) {
                     [countryExpectation fulfill];
                 }
                  videosCompletionHandler:^(StatsGroup *group, NSError *error) {
                      [videosExpectation fulfill];
                  }
                 authorsCompletionHandler:^(StatsGroup *group, NSError *error) {
                     [authorsExpectation fulfill];
                 }
             searchTermsCompletionHandler:^(StatsGroup *group, NSError *error) {
                 [searchTermsExpectation fulfill];
             }
                            progressBlock:nil
              andOverallCompletionHandler:^{
                  [overallExpectation fulfill];
              }];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testDateSanitizationDay
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = 2014;
    dateComponents.month = 12;
    dateComponents.day = 1;
    dateComponents.hour = 0;
    dateComponents.minute = 0;
    dateComponents.second = 0;
    NSDate *date = [calendar dateFromComponents:dateComponents];
    
    [self verifyDateSantizationWithBaseDate:date
                               periodUnit:StatsPeriodUnitDay
                             expectedYear:2014
                                    month:12
                                      day:1];
}


- (void)testDateSanitizationWeek
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = 2014;
    dateComponents.month = 12;
    dateComponents.day = 1;
    dateComponents.hour = 0;
    dateComponents.minute = 0;
    dateComponents.second = 0;
    NSDate *date = [calendar dateFromComponents:dateComponents];
    
    [self verifyDateSantizationWithBaseDate:date
                                 periodUnit:StatsPeriodUnitWeek
                               expectedYear:2014
                                      month:12
                                        day:7];
}


- (void)testDateSanitizationWeek2
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = 2015;
    dateComponents.month = 1;
    dateComponents.day = 5;
    dateComponents.hour = 0;
    dateComponents.minute = 0;
    dateComponents.second = 0;
    NSDate *date = [calendar dateFromComponents:dateComponents];
    
    [self verifyDateSantizationWithBaseDate:date
                                 periodUnit:StatsPeriodUnitWeek
                               expectedYear:2015
                                      month:1
                                        day:11];
}


- (void)testDateSanitizationWeek3
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = 2015;
    dateComponents.month = 1;
    dateComponents.day = 6;
    dateComponents.hour = 0;
    dateComponents.minute = 0;
    dateComponents.second = 0;
    NSDate *date = [calendar dateFromComponents:dateComponents];
    
    [self verifyDateSantizationWithBaseDate:date
                                 periodUnit:StatsPeriodUnitWeek
                               expectedYear:2015
                                      month:1
                                        day:11];
}


- (void)testDateSanitizationAlreadySunday
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = 2014;
    dateComponents.month = 12;
    dateComponents.day = 28;
    dateComponents.hour = 0;
    dateComponents.minute = 0;
    dateComponents.second = 0;
    NSDate *date = [calendar dateFromComponents:dateComponents];
    
    [self verifyDateSantizationWithBaseDate:date
                                 periodUnit:StatsPeriodUnitWeek
                               expectedYear:2014
                                      month:12
                                        day:28];
}


- (void)testDateSanitizationWeekCrossesYear
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = 2014;
    dateComponents.month = 12;
    dateComponents.day = 30;
    dateComponents.hour = 0;
    dateComponents.minute = 0;
    dateComponents.second = 0;
    NSDate *date = [calendar dateFromComponents:dateComponents];
    
    [self verifyDateSantizationWithBaseDate:date
                                 periodUnit:StatsPeriodUnitWeek
                               expectedYear:2015
                                      month:1
                                        day:4];
}


- (void)testDateSanitizationMonth
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = 2014;
    dateComponents.month = 12;
    dateComponents.day = 1;
    dateComponents.hour = 0;
    dateComponents.minute = 0;
    dateComponents.second = 0;
    NSDate *date = [calendar dateFromComponents:dateComponents];
    
    [self verifyDateSantizationWithBaseDate:date
                                 periodUnit:StatsPeriodUnitMonth
                               expectedYear:2014
                                      month:12
                                        day:31];
}


- (void)testDateSanitizationMonthLeapYear
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = 2016;
    dateComponents.month = 2;
    dateComponents.day = 13;
    dateComponents.hour = 0;
    dateComponents.minute = 0;
    dateComponents.second = 0;
    NSDate *date = [calendar dateFromComponents:dateComponents];
    
    [self verifyDateSantizationWithBaseDate:date
                                 periodUnit:StatsPeriodUnitMonth
                               expectedYear:2016
                                      month:2
                                        day:29];
}


- (void)testDateSanitizationYear
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = 2014;
    dateComponents.month = 2;
    dateComponents.day = 13;
    dateComponents.hour = 0;
    dateComponents.minute = 0;
    dateComponents.second = 0;
    NSDate *date = [calendar dateFromComponents:dateComponents];
    
    [self verifyDateSantizationWithBaseDate:date
                                 periodUnit:StatsPeriodUnitYear
                               expectedYear:2014
                                      month:12
                                        day:31];
}


- (void)testDateSanitizationYearFirstOfYear
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = 2014;
    dateComponents.month = 1;
    dateComponents.day = 1;
    dateComponents.hour = 0;
    dateComponents.minute = 0;
    dateComponents.second = 0;
    NSDate *date = [calendar dateFromComponents:dateComponents];
    
    [self verifyDateSantizationWithBaseDate:date
                                 periodUnit:StatsPeriodUnitYear
                               expectedYear:2014
                                      month:12
                                        day:31];
}


- (void)testDateSanitizationYearLastOfYear
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = 2014;
    dateComponents.month = 12;
    dateComponents.day = 31;
    dateComponents.hour = 0;
    dateComponents.minute = 0;
    dateComponents.second = 0;
    NSDate *date = [calendar dateFromComponents:dateComponents];
    
    [self verifyDateSantizationWithBaseDate:date
                                 periodUnit:StatsPeriodUnitYear
                               expectedYear:2014
                                      month:12
                                        day:31];
}


#pragma mark - Private test helper methods

- (void)verifyDateSantizationWithBaseDate:(NSDate *)baseDate periodUnit:(StatsPeriodUnit)unit expectedYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day
{
    WPStatsServiceRemote *remote = OCMClassMock([WPStatsServiceRemote class]);
    
    id dateCheckBlock = [OCMArg checkWithBlock:^BOOL(id obj) {
        NSDate *date = obj;
        NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];
        BOOL isOkay = dateComponents.year == year && dateComponents.month == month && dateComponents.day == day;
        
        return isOkay;
    }];
    
    OCMExpect([remote batchFetchStatsForDate:dateCheckBlock
                                        unit:unit
                 withVisitsCompletionHandler:[OCMArg any]
                     eventsCompletionHandler:[OCMArg any]
                      postsCompletionHandler:[OCMArg any]
                  referrersCompletionHandler:[OCMArg any]
                     clicksCompletionHandler:[OCMArg any]
                    countryCompletionHandler:[OCMArg any]
                     videosCompletionHandler:[OCMArg any]
                    authorsCompletionHandler:[OCMArg any]
                searchTermsCompletionHandler:[OCMArg any]
                               progressBlock:[OCMArg any]
                 andOverallCompletionHandler:[OCMArg any]]);
    
    self.subject.remote = remote;
    
    [self.subject retrieveAllStatsForDate:baseDate
                                     unit:unit
              withVisitsCompletionHandler:nil
                  eventsCompletionHandler:nil
                   postsCompletionHandler:nil
               referrersCompletionHandler:nil
                  clicksCompletionHandler:nil
                 countryCompletionHandler:nil
                  videosCompletionHandler:nil
                 authorsCompletionHandler:nil
             searchTermsCompletionHandler:nil
                            progressBlock:nil
               andOverallCompletionHandler:^{
                   // Don't do anything
               }];
    
    OCMVerifyAll((id)remote);
}

@end


@implementation WPStatsServiceRemoteMock

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
                 progressBlock:(void (^)(NSUInteger, NSUInteger))progressBlock
   andOverallCompletionHandler:(void (^)())completionHandler
{
    if (visitsCompletion) {
        visitsCompletion([StatsVisits new], nil);
    }
    if (eventsCompletion) {
        eventsCompletion(@[[StatsItem new]], nil, false, nil);
    }
    if (postsCompletion) {
        postsCompletion(@[[StatsItem new]], nil, false, nil);
    }
    if (referrersCompletion) {
        referrersCompletion(@[[StatsItem new]], nil, false, nil);
    }
    if (clicksCompletion) {
        clicksCompletion(@[[StatsItem new]], nil, false, nil);
    }
    if (countryCompletion) {
        countryCompletion(@[[StatsItem new]], nil, false, nil);
    }
    if (videosCompletion) {
        videosCompletion(@[[StatsItem new]], nil, false, nil);
    }
    if (authorsCompletion) {
        authorsCompletion(@[[StatsItem new]], nil, false, nil);
    }
    if (searchTermsCompletion) {
        searchTermsCompletion(@[[StatsItem new]], nil, false, nil);
    }
    
    if (progressBlock) {
        progressBlock(1, 1);
    }
    
    if (completionHandler) {
        completionHandler();
    }
}

@end
