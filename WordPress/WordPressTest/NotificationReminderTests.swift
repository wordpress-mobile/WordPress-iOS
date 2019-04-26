//
//  NotificationReminderTests.swift
//  WordPressTest
//
//  Created by James Frost on 26/04/2019.
//  Copyright © 2019 WordPress. All rights reserved.
//

import XCTest
@testable import WordPress

class NotificationReminderTests: XCTestCase {
    func test20MinutePeriod() {
        let period = NotificationReminderPeriod.in20minutes

        let startComponents = DateComponents(year: 2019, month: 04, day: 01, hour: 09, minute: 00, second: 00)
        let startDate = Calendar.current.date(from: startComponents)!

        let expectedComponents = DateComponents(year: 2019, month: 04, day: 01, hour: 09, minute: 20, second: 00)
        let triggerComponents = period.dateComponents(from: startDate)
        XCTAssertEqual(triggerComponents, expectedComponents)
    }

    func test1HourPeriod() {
        let period = NotificationReminderPeriod.in1hour

        let startComponents = DateComponents(year: 2019, month: 04, day: 01, hour: 09, minute: 00, second: 00)
        let startDate = Calendar.current.date(from: startComponents)!

        let expectedComponents = DateComponents(year: 2019, month: 04, day: 01, hour: 10, minute: 00, second: 00)
        let triggerComponents = period.dateComponents(from: startDate)
        XCTAssertEqual(triggerComponents, expectedComponents)
    }

    func test1HourPeriodAcrossDays() {
        let period = NotificationReminderPeriod.in1hour

        let startComponents = DateComponents(year: 2019, month: 04, day: 30, hour: 23, minute: 50, second: 00)
        let startDate = Calendar.current.date(from: startComponents)!

        let expectedComponents = DateComponents(year: 2019, month: 05, day: 01, hour: 00, minute: 50, second: 00)
        let triggerComponents = period.dateComponents(from: startDate)
        XCTAssertEqual(triggerComponents, expectedComponents)
    }

    func test3HourPeriod() {
        let period = NotificationReminderPeriod.in3hours

        let startComponents = DateComponents(year: 2019, month: 04, day: 01, hour: 09, minute: 00, second: 00)
        let startDate = Calendar.current.date(from: startComponents)!

        let expectedComponents = DateComponents(year: 2019, month: 04, day: 01, hour: 12, minute: 00, second: 00)
        let triggerComponents = period.dateComponents(from: startDate)
        XCTAssertEqual(triggerComponents, expectedComponents)
    }

    func testTomorrowPeriod() {
        let period = NotificationReminderPeriod.tomorrow

        let startComponents = DateComponents(year: 2019, month: 04, day: 01, hour: 08, minute: 00, second: 00)
        let startDate = Calendar.current.date(from: startComponents)!

        // The tomorrow period should trigger at 9am tomorrow.
        let expectedComponents = DateComponents(year: 2019, month: 04, day: 02, hour: 09, minute: 00, second: 00)
        let triggerComponents = period.dateComponents(from: startDate)
        XCTAssertEqual(triggerComponents, expectedComponents)
    }

    func testTomorrowPeriodAcrossMonths() {
        let period = NotificationReminderPeriod.tomorrow

        let startComponents = DateComponents(year: 2019, month: 04, day: 30, hour: 20, minute: 00, second: 00)
        let startDate = Calendar.current.date(from: startComponents)!

        let expectedComponents = DateComponents(year: 2019, month: 05, day: 01, hour: 09, minute: 00, second: 00)
        let triggerComponents = period.dateComponents(from: startDate)
        XCTAssertEqual(triggerComponents, expectedComponents)
    }

    func testNextWeekPeriod() {
        let period = NotificationReminderPeriod.nextWeek

        let startComponents = DateComponents(year: 2019, month: 04, day: 02, hour: 10, minute: 00, second: 00)
        let startDate = Calendar.current.date(from: startComponents)!

        let expectedComponents = DateComponents(year: 2019, month: 04, day: 08, hour: 09, minute: 00, second: 00)
        let triggerComponents = period.dateComponents(from: startDate)
        XCTAssertEqual(triggerComponents, expectedComponents)
    }
    func testNextWeekPeriodAcrossMonths() {
        let period = NotificationReminderPeriod.nextWeek

        let startComponents = DateComponents(year: 2019, month: 02, day: 27, hour: 12, minute: 00, second: 00)
        let startDate = Calendar.current.date(from: startComponents)!

        let expectedComponents = DateComponents(year: 2019, month: 03, day: 04, hour: 09, minute: 00, second: 00)
        let triggerComponents = period.dateComponents(from: startDate)
        XCTAssertEqual(triggerComponents, expectedComponents)
    }
}

private extension Date {
    static var today: Date {
        return Date()
    }

    var timeAndDateComponents: DateComponents {
        return Calendar.current.dateComponents([.day, .month, .year, .hour, .minute, .second],
                                               from: self)
    }

    func addingComponents(_ components: DateComponents) -> Date? {
        return Calendar.current.date(byAdding: components, to: self)
    }
}
