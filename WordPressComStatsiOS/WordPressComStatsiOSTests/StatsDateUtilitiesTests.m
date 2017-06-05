#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "StatsDateUtilities.h"

@interface StatsDateUtilitiesTests : XCTestCase

@property (nonatomic, strong) StatsDateUtilities *subject;

@end

@implementation StatsDateUtilitiesTests

- (void)setUp {
    [super setUp];
    
    self.subject = [[StatsDateUtilities alloc] init];
}

- (void)tearDown {
    [super tearDown];
    
    self.subject = nil;
}

- (void)testCalculateEndDateForPeriodUnitDay {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = 2014;
    dateComponents.month = 12;
    dateComponents.day = 30;
    dateComponents.hour = 0;
    dateComponents.minute = 0;
    dateComponents.second = 0;
    NSDate *date = [calendar dateFromComponents:dateComponents];
    
    NSDate *result = [self.subject calculateEndDateForPeriodUnit:StatsPeriodUnitDay withDateWithinPeriod:date];
    
    dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:result];
    
    XCTAssertEqual(dateComponents.year, 2014);
    XCTAssertEqual(dateComponents.month, 12);
    XCTAssertEqual(dateComponents.day, 30);
    XCTAssertEqual(dateComponents.hour, 23);
    XCTAssertEqual(dateComponents.minute, 59);
    XCTAssertEqual(dateComponents.second, 59);
    
}


- (void)testCalculateEndDateForPeriodUnitWeek {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = 2015;
    dateComponents.month = 1;
    dateComponents.day = 5;
    dateComponents.hour = 0;
    dateComponents.minute = 0;
    dateComponents.second = 0;
    NSDate *date = [calendar dateFromComponents:dateComponents];
    
    NSDate *result = [self.subject calculateEndDateForPeriodUnit:StatsPeriodUnitWeek withDateWithinPeriod:date];
    
    dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:result];
    
    XCTAssertEqual(dateComponents.year, 2015);
    XCTAssertEqual(dateComponents.month, 1);
    XCTAssertEqual(dateComponents.day, 11);
    XCTAssertEqual(dateComponents.hour, 23);
    XCTAssertEqual(dateComponents.minute, 59);
    XCTAssertEqual(dateComponents.second, 59);
}


- (void)testCalculateEndDateForPeriodUnitMonth {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = 2015;
    dateComponents.month = 1;
    dateComponents.day = 5;
    dateComponents.hour = 0;
    dateComponents.minute = 0;
    dateComponents.second = 0;
    NSDate *date = [calendar dateFromComponents:dateComponents];
    
    NSDate *result = [self.subject calculateEndDateForPeriodUnit:StatsPeriodUnitMonth withDateWithinPeriod:date];
    
    dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:result];
    
    XCTAssertEqual(dateComponents.year, 2015);
    XCTAssertEqual(dateComponents.month, 1);
    XCTAssertEqual(dateComponents.day, 31);
    XCTAssertEqual(dateComponents.hour, 23);
    XCTAssertEqual(dateComponents.minute, 59);
    XCTAssertEqual(dateComponents.second, 59);
}


- (void)testCalculateEndDateForPeriodUnitYear {
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = 2015;
    dateComponents.month = 1;
    dateComponents.day = 5;
    dateComponents.hour = 0;
    dateComponents.minute = 0;
    dateComponents.second = 0;
    NSDate *date = [calendar dateFromComponents:dateComponents];
    
    NSDate *result = [self.subject calculateEndDateForPeriodUnit:StatsPeriodUnitYear withDateWithinPeriod:date];
    
    dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:result];
    
    XCTAssertEqual(dateComponents.year, 2015);
    XCTAssertEqual(dateComponents.month, 12);
    XCTAssertEqual(dateComponents.day, 31);
    XCTAssertEqual(dateComponents.hour, 23);
    XCTAssertEqual(dateComponents.minute, 59);
    XCTAssertEqual(dateComponents.second, 59);
}

@end
