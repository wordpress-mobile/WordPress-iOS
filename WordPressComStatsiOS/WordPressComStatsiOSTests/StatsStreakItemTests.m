#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "StatsStreakItem.h"

@interface StatsStreakItemTests : XCTestCase

@property (nonatomic, strong) StatsStreakItem *streakItem;

@end

@implementation StatsStreakItemTests

- (void)setUp {
    [super setUp];
    
    self.streakItem = [[StatsStreakItem alloc] init];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testDateFromTimeStamp {
    self.streakItem.timeStamp = @"1395718074";
    NSDate *result = self.streakItem.date;
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [calendar setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:result];
    
    XCTAssertNotNil(result);
    XCTAssertEqual(dateComponents.year, 2014);
    XCTAssertEqual(dateComponents.month, 3);
    XCTAssertEqual(dateComponents.day, 25);
    XCTAssertEqual(dateComponents.hour, 3);
    XCTAssertEqual(dateComponents.minute, 27);
    XCTAssertEqual(dateComponents.second, 54);
    
    // Set it again, make sure the getter updates properly
    self.streakItem.timeStamp = @"1455148316";
    result = self.streakItem.date;
    dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:result];
    
    XCTAssertNotNil(result);
    XCTAssertEqual(dateComponents.year, 2016);
    XCTAssertEqual(dateComponents.month, 2);
    XCTAssertEqual(dateComponents.day, 10);
    XCTAssertEqual(dateComponents.hour, 23);
    XCTAssertEqual(dateComponents.minute, 51);
    XCTAssertEqual(dateComponents.second, 56);
    
    // One more time...
    self.streakItem.timeStamp = @"1401473695";
    result = self.streakItem.date;
    dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:result];
    
    XCTAssertNotNil(result);
    XCTAssertEqual(dateComponents.year, 2014);
    XCTAssertEqual(dateComponents.month, 5);
    XCTAssertEqual(dateComponents.day, 30);
    XCTAssertEqual(dateComponents.hour, 18);
    XCTAssertEqual(dateComponents.minute, 14);
    XCTAssertEqual(dateComponents.second, 55);
}

- (void)testEmptyTimeStamp {
    self.streakItem.timeStamp = @"";
    NSDate *result = self.streakItem.date;
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [calendar setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:result];
    
    XCTAssertNotNil(result);
    XCTAssertEqual(dateComponents.year, 1970);
    XCTAssertEqual(dateComponents.month, 1);
    XCTAssertEqual(dateComponents.day, 1);
    XCTAssertEqual(dateComponents.hour, 0);
    XCTAssertEqual(dateComponents.minute, 0);
    XCTAssertEqual(dateComponents.second, 0);
}

- (void)testNilTimeStamp {
    self.streakItem.timeStamp = nil;
    NSDate *result = self.streakItem.date;
    
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    [calendar setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:result];
    
    XCTAssertNil(result);
}

@end
