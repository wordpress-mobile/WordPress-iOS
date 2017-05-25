#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "StatsStreak.h"
#import "StatsStreakItem.h"

@interface StatsStreakTests : XCTestCase

@property (nonatomic, strong) StatsStreak *streak;
@property (nonatomic, strong) NSCalendar *calendar;

@end

@implementation StatsStreakTests

- (void)setUp
{
    [super setUp];
    
    self.streak = [[StatsStreak alloc] init];
    self.calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [self.calendar setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testStatsItemsPrune
{
    XCTAssertNil(self.streak.items);
    
    StatsStreakItem *item1 = [[StatsStreakItem alloc] init];
    item1.timeStamp = @"1454415120"; // 02/02/2016 @ 12:12pm (UTC)
    
    StatsStreakItem *item2 = [[StatsStreakItem alloc] init];
    item2.timeStamp = @"1455494400"; // 02/15/2016 @ 12:00am (UTC)
    
    StatsStreakItem *item3 = [[StatsStreakItem alloc] init];
    item3.timeStamp = @"1456057260"; // 02/21/2016 @ 12:21pm (UTC)
    
    StatsStreakItem *item4 = [[StatsStreakItem alloc] init];
    item4.timeStamp = @"1423958400"; // 02/15/2015 @ 12:00am (UTC)
    
    StatsStreakItem *item5 = [[StatsStreakItem alloc] init];
    item5.timeStamp = @"1451606340"; // 12/31/2015 @ 11:59pm (UTC)
    
    StatsStreakItem *item6 = [[StatsStreakItem alloc] init];
    item6.timeStamp = @"1460419200"; // 04/12/2016 @ 12:00am (UTC)
    
    StatsStreakItem *item7 = [[StatsStreakItem alloc] init];
    item7.timeStamp = @"1456704000"; // 02/29/2016 @ 12:00am (UTC)
    
    self.streak.items = @[item1, item2, item3, item4, item5, item6, item7];
    
    XCTAssertNotNil(self.streak.items);
    XCTAssertEqual(self.streak.items.count, 7);

    NSDateComponents *dateComponentsFeb = [[NSDateComponents alloc] init];
    dateComponentsFeb.calendar = self.calendar;
    dateComponentsFeb.month = 2;
    dateComponentsFeb.day = 15;
    dateComponentsFeb.year = 2016;
    [self.streak pruneItemsOutsideOfMonth:[dateComponentsFeb date]];
     
    XCTAssertNotNil(self.streak.items);
    XCTAssertEqual(self.streak.items.count, 4);
    
    StatsStreakItem *resultItem = [self.streak.items objectAtIndex:0];
    NSDateComponents *dateComponentsResult = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                              fromDate: resultItem.date];

    XCTAssertEqual(dateComponentsResult.year, 2016);
    XCTAssertEqual(dateComponentsResult.month, 2);
    XCTAssertEqual(dateComponentsResult.day, 2);
    
    resultItem = [self.streak.items objectAtIndex:3];
    dateComponentsResult = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                              fromDate:resultItem.date];
    
    XCTAssertEqual(dateComponentsResult.year, 2016);
    XCTAssertEqual(dateComponentsResult.month, 2);
    XCTAssertEqual(dateComponentsResult.day, 29);
}

@end
