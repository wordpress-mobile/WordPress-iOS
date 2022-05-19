//
//  PromptRemindersSchedulerTests.swift
//  WordPressTest
//
//  Created by David Christiandy on 19/05/22.
//  Copyright © 2022 WordPress. All rights reserved.
//

import XCTest
import OHHTTPStubs

@testable import WordPress

class PromptRemindersSchedulerTests: XCTestCase {

    typealias Schedule = BloggingRemindersScheduler.Schedule
    typealias Weekday = BloggingRemindersScheduler.Weekday

    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    var contextManager: ContextManagerMock!
    var serviceFactory: BloggingPromptsServiceFactory!
    var notificationScheduler: NotificationScheduler!
    var pushAuthorizer: PushNotificationAuthorizer!
    var scheduler: PromptRemindersScheduler!

    override func setUp() {
        contextManager = ContextManagerMock()
        serviceFactory = BloggingPromptsServiceFactory(contextManager: contextManager)
        notificationScheduler = MockNotificationScheduler()
        pushAuthorizer = PushNotificationsAuthorizerMock()
        scheduler = PromptRemindersScheduler(bloggingPromptsServiceFactory: serviceFactory,
                                             notificationScheduler: notificationScheduler,
                                             pushAuthorizer: pushAuthorizer)

        super.setUp()
    }

    override func tearDown() {
        contextManager = nil
        serviceFactory = nil
        notificationScheduler = nil
        pushAuthorizer = nil
        scheduler = nil
        HTTPStubs.removeAllStubs()

        super.tearDown()
    }

    // MARK: Tests

    func test_schedule_addsNotificationRequestsCorrectly() {

    }

    func test_schedule_givenEmptySchedule_doesNothing() {

    }

    func test_schedule_givenTodayIsIncluded_withReminderTimeAfterCurrentTime_includesTodayInSchedule() {

    }

    func test_schedule_givenTodayIsIncluded_withReminderTimeBeforeCurrentTime_excludesTodayFromSchedule() {

    }
}

// MARK: - Private Helpers

private extension PromptRemindersSchedulerTests {

    func stubFetchPromptsResponse() {
        stub(condition: isMethodGET()) { _ in
            return .init(jsonObject: self.makeDynamicPromptObjects(), statusCode: 200, headers: ["Content-Type": "application/json"])
        }
    }

    func makeDynamicPromptObjects(count: Int = 15) -> Any {
        var objects = [Any]()
        let calendar = Calendar.current
        let currentDate = Date()

        for i in 0..<count {
            let date = calendar.date(byAdding: .day, value: i, to: currentDate)!
            objects.append([
                "id": 100 + i,
                "text": "Prompt text \(i)",
                "title": "Prompt title \(i)",
                "content": "Prompt content \(i)",
                "attribution": "",
                "date": Self.dateFormatter.string(from: date),
                "answered": false,
                "answered_users_count": 0,
                "answered_users_sample": []
            ])
        }

        return ["prompts": objects]
    }


    class MockNotificationScheduler: NotificationScheduler {
        var requests = [UNNotificationRequest]()

        func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?) {
            requests.append(request)
            completionHandler?(nil)
        }

        func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
            // no-op
        }
    }
}
