//
//  NotificationFilteringServiceTests.swift
//  WordPressTest
//
//  Created by Povilas Staskus on 2022-11-04.
//  Copyright © 2022 WordPress. All rights reserved.
//

import XCTest
@testable import WordPress

final class NotificationFilteringServiceTests: XCTestCase {

    private var sut: NotificationFilteringService!
    private var notificationSettingsLoader: NotificationSettingsLoaderMock!

    override func setUpWithError() throws {
        notificationSettingsLoader = NotificationSettingsLoaderMock()
    }

    override func tearDownWithError() throws {
        sut = nil
        notificationSettingsLoader = nil
    }

    // MARK: - Should show notification control

    func testShouldShowNotificationControlInWordPressWhenFeatureFlagEnabledAndNotificationsEnabled() {
        setup(allowDisablingWPNotifications: true, isWordPress: true, notificationsEnabled: true)

        XCTAssertTrue(sut.shouldShowNotificationControl())
    }

    func testShouldShowNotificationControlInWordPressWhenFeatureFlagEnabledAndNotificationsDisabled() {
        setup(allowDisablingWPNotifications: true, isWordPress: true, notificationsEnabled: false)

        XCTAssertFalse(sut.shouldShowNotificationControl())
    }

    func testShouldShowNotificationControlInWordPressWhenFeatureFlagDisabled() {
        setup(allowDisablingWPNotifications: false, isWordPress: true, notificationsEnabled: true)

        XCTAssertFalse(sut.shouldShowNotificationControl())
    }

    func testShouldShowNotificationControlInJetpackWhenFeatureFlagEnabled() {
        setup(allowDisablingWPNotifications: true, isWordPress: false, notificationsEnabled: true)

        XCTAssertFalse(sut.shouldShowNotificationControl())
    }

    // MARK: - WordPress notifications enabled

    func testWordPressNotificationsEnabled() {
        setup(allowDisablingWPNotifications: true, isWordPress: true)

        XCTAssertTrue(sut.wordPressNotificationsEnabled)
        sut.wordPressNotificationsEnabled = false
        XCTAssertFalse(sut.wordPressNotificationsEnabled)
        sut.wordPressNotificationsEnabled = true
        XCTAssertTrue(sut.wordPressNotificationsEnabled)
    }

    // MARK: - Disable WordPress notifications

    func testDisableWPNotificationsIfNeededInJetpackWhenFeatureFlagEnabled() {
        setup(allowDisablingWPNotifications: true, isWordPress: false)
        XCTAssertTrue(sut.wordPressNotificationsEnabled)

        sut.disableWordPressNotificationsIfNeeded()

        XCTAssertFalse(sut.wordPressNotificationsEnabled)
    }

    func testDisableWPNotificationsIfNeededInJetpackWhenFeatureFlagDisabled() {
        setup(allowDisablingWPNotifications: false, isWordPress: false)
        XCTAssertTrue(sut.wordPressNotificationsEnabled)

        sut.disableWordPressNotificationsIfNeeded()

        XCTAssertTrue(sut.wordPressNotificationsEnabled)
    }

    func testDisableWPNotificationsIfNeededInWordPresskWhenFeatureFlagEnabled() {
        setup(allowDisablingWPNotifications: true, isWordPress: true)
        XCTAssertTrue(sut.wordPressNotificationsEnabled)

        sut.disableWordPressNotificationsIfNeeded()

        XCTAssertTrue(sut.wordPressNotificationsEnabled)
    }

    // MARK: - Should filter WordPress notifications

    func testShouldFilterWordPressNotificationsInWordPressWhenFeatureFlagEnabledAndWordPressNotificationsDisabled() {
        setup(allowDisablingWPNotifications: true, isWordPress: true)
        sut.wordPressNotificationsEnabled = false

        XCTAssertTrue(sut.shouldFilterWordPressNotifications())
    }

    func testShouldFilterWordPressNotificationsInWordPressWhenFeatureFlagDisabledAndWordPressNotificationsDisabled() {
        setup(allowDisablingWPNotifications: false, isWordPress: true)
        sut.wordPressNotificationsEnabled = false

        XCTAssertFalse(sut.shouldFilterWordPressNotifications())
    }

    func testShouldFilterWordPressNotificationsInWordPressWhenFeatureFlagEnabledAndWordPressNotificationsEnabled() {
        setup(allowDisablingWPNotifications: true, isWordPress: true)
        sut.wordPressNotificationsEnabled = true

        XCTAssertFalse(sut.shouldFilterWordPressNotifications())
    }

    func testShouldFilterWordPressNotificationsInJetpack() {
        setup(allowDisablingWPNotifications: true, isWordPress: false)

        XCTAssertFalse(sut.shouldFilterWordPressNotifications())
    }
}

// MARK: - Helpers

private extension NotificationFilteringServiceTests {
    func setup(allowDisablingWPNotifications: Bool,
               isWordPress: Bool,
               notificationsEnabled: Bool = true) {
        notificationSettingsLoader.authorizationStatus = notificationsEnabled ? .authorized : .denied
        sut = NotificationFilteringService(notificationSettingsLoader: notificationSettingsLoader,
                                           allowDisablingWPNotifications: allowDisablingWPNotifications,
                                           isWordPress: isWordPress)
        sut.wordPressNotificationsEnabled = true
    }
}

private class NotificationSettingsLoaderMock: NotificationSettingsLoader {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    func getNotificationAuthorizationStatus(completionHandler: @escaping (UNAuthorizationStatus) -> Void) {
        completionHandler(authorizationStatus)
    }
}
