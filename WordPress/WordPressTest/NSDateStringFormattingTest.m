#import <XCTest/XCTest.h>
#import "NSDate+StringFormatting.h"

@interface NSDateStringFormattingTest : XCTestCase
@end

static const NSTimeInterval OneSecond = 1;
static const NSTimeInterval OneMinute = 1 + 60;
static const NSTimeInterval OneHour =  1 + (60 * 60);
static const NSTimeInterval OneDay = 1 + (60 * 60 * 24);

@implementation NSDateStringFormattingTest

- (void)testShortStringSeconds
{
    NSTimeInterval interval = -OneSecond;
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:interval];
    XCTAssertTrue([[date shortString] isEqualToString:@"Just now"]);
}

- (void)testShortStringMinutes
{
    NSTimeInterval interval = -OneMinute;
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:interval];
    XCTAssertTrue([[date shortString] isEqualToString:@"1m"]);
}

- (void)testShortStringHours
{
    NSTimeInterval interval = -OneHour;
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:interval];
    XCTAssertTrue([[date shortString] isEqualToString:@"1h"]);
}

- (void)testShortStringDays
{
    NSTimeInterval interval = -OneDay;
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:interval];
    XCTAssertTrue([[date shortString] isEqualToString:@"1d"]);
}

- (void)testShortStringFutureSeconds
{
    NSTimeInterval interval = OneSecond;
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:interval];
    XCTAssertTrue([[date shortString] isEqualToString:@"In seconds"]);
}

- (void)testShortStringFutureMinutes
{
    NSTimeInterval interval = OneMinute;
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:interval];
    XCTAssertTrue([[date shortString] isEqualToString:@"In 1m"]);
}

- (void)testShortStringFutureHours
{
    NSTimeInterval interval = OneHour;
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:interval];
    XCTAssertTrue([[date shortString] isEqualToString:@"In 1h"]);
}

- (void)testShortStringFutureDays
{
    NSTimeInterval interval = OneDay;
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:interval];
    XCTAssertTrue([[date shortString] isEqualToString:@"In 1d"]);
}

@end
