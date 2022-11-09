import XCTest
@testable import WordPress

final class JetpackOverlayFrequencyTrackerTests: XCTestCase {

    private enum Constants {
        static let frequencyConfig = JetpackOverlayFrequencyTracker.FrequencyConfig(featureSpecificInDays: 4, generalInDays: 2)
        static let oneDayInSeconds: TimeInterval = 86_400
        static let threeDaysInSeconds: TimeInterval = 259_200
        static let fiveDaysInSeconds: TimeInterval = 432_000
    }

    private var mockUserDefaults: InMemoryUserDefaults!

    override func setUp() {
        mockUserDefaults = InMemoryUserDefaults()
    }

    func testTrackingOverlay() throws {
        // Given
        let key = JetpackOverlayFrequencyTracker.Constants.lastDateKeyPrefix + "-stats"
        let genericKey = JetpackOverlayFrequencyTracker.Constants.lastDateKeyPrefix
        let tracker = JetpackOverlayFrequencyTracker(source: .stats, persistenceStore: mockUserDefaults)

        // When
        tracker.track()

        // Then
        let savedDate = try XCTUnwrap(mockUserDefaults.object(forKey: key) as? Date)
        let savedGenericDate = try XCTUnwrap(mockUserDefaults.object(forKey: genericKey) as? Date)
        let savedDateInSeconds = savedDate.timeIntervalSince1970
        let savedGenericDateInSeconds = savedGenericDate.timeIntervalSince1970
        let nowInSeconds = Date().timeIntervalSince1970
        XCTAssertEqual(savedDateInSeconds, nowInSeconds, accuracy: 10)
        XCTAssertEqual(savedGenericDateInSeconds, nowInSeconds, accuracy: 10)
    }

    func testAlwaysShowCardOverlays() {
        // Given
        let key = JetpackOverlayFrequencyTracker.Constants.lastDateKeyPrefix + "-card"
        let genericKey = JetpackOverlayFrequencyTracker.Constants.lastDateKeyPrefix
        let tracker = JetpackOverlayFrequencyTracker(source: .card, persistenceStore: mockUserDefaults)
        mockUserDefaults.set(Date(), forKey: key)
        mockUserDefaults.set(Date(), forKey: genericKey)

        // When & Then
        XCTAssertTrue(tracker.shouldShow())
    }

    func testShowLoginOverlayOnlyOnce() {
        // Given
        let key = JetpackOverlayFrequencyTracker.Constants.lastDateKeyPrefix + "-login"
        let genericKey = JetpackOverlayFrequencyTracker.Constants.lastDateKeyPrefix
        let tracker = JetpackOverlayFrequencyTracker(source: .login, persistenceStore: mockUserDefaults)

        // When & Then
        XCTAssertTrue(tracker.shouldShow())

        // Given
        let distantDate = Date.distantPast
        mockUserDefaults.set(distantDate, forKey: key)
        mockUserDefaults.set(distantDate, forKey: genericKey)

        // When & Then
        XCTAssertFalse(tracker.shouldShow())
    }

    func testShowAppOpenOverlayOnlyOnce() {
        // Given
        let key = JetpackOverlayFrequencyTracker.Constants.lastDateKeyPrefix + "-app_open"
        let genericKey = JetpackOverlayFrequencyTracker.Constants.lastDateKeyPrefix
        let tracker = JetpackOverlayFrequencyTracker(source: .appOpen, persistenceStore: mockUserDefaults)

        // When & Then
        XCTAssertTrue(tracker.shouldShow())

        // Given
        let distantDate = Date.distantPast
        mockUserDefaults.set(distantDate, forKey: key)
        mockUserDefaults.set(distantDate, forKey: genericKey)

        // When & Then
        XCTAssertFalse(tracker.shouldShow())
    }

    func testFeatureSpecificFrequency() {
        // Given
        let statsKey = JetpackOverlayFrequencyTracker.Constants.lastDateKeyPrefix + "-stats"
        let genericKey = JetpackOverlayFrequencyTracker.Constants.lastDateKeyPrefix
        let tracker = JetpackOverlayFrequencyTracker(frequencyConfig: Constants.frequencyConfig,
                                                     source: .stats,
                                                     persistenceStore: mockUserDefaults)

        // When & Then
        XCTAssertTrue(tracker.shouldShow()) // First time

        // Given
        let threeDaysAgo = Date(timeInterval: -Constants.threeDaysInSeconds, since: Date())
        mockUserDefaults.set(threeDaysAgo, forKey: statsKey)
        mockUserDefaults.set(threeDaysAgo, forKey: genericKey)

        // When & Then
        XCTAssertFalse(tracker.shouldShow()) // Before feature-specific frequency have passed

        // Given
        let fiveDaysAgo = Date(timeInterval: -Constants.fiveDaysInSeconds, since: Date())
        mockUserDefaults.set(fiveDaysAgo, forKey: statsKey)
        mockUserDefaults.set(fiveDaysAgo, forKey: genericKey)

        // When & Then
        XCTAssertTrue(tracker.shouldShow()) // After feature-specific frequency have passed
    }

    func testGeneralFrequency() {
        // Given
        let statsKey = JetpackOverlayFrequencyTracker.Constants.lastDateKeyPrefix + "-stats"
        let genericKey = JetpackOverlayFrequencyTracker.Constants.lastDateKeyPrefix
        let statsTracker = JetpackOverlayFrequencyTracker(frequencyConfig: Constants.frequencyConfig,
                                                          source: .stats,
                                                          persistenceStore: mockUserDefaults)
        let readerTracker = JetpackOverlayFrequencyTracker(frequencyConfig: Constants.frequencyConfig,
                                                          source: .reader,
                                                          persistenceStore: mockUserDefaults)

        // When & Then
        XCTAssertTrue(statsTracker.shouldShow()) // First time
        XCTAssertTrue(readerTracker.shouldShow()) // First time

        // Given
        let oneDayAgo = Date(timeInterval: -Constants.oneDayInSeconds, since: Date())
        mockUserDefaults.set(oneDayAgo, forKey: statsKey)
        mockUserDefaults.set(oneDayAgo, forKey: genericKey)

        // When & Then
        XCTAssertFalse(statsTracker.shouldShow()) // Before generic frequency have passed
        XCTAssertFalse(readerTracker.shouldShow()) // Before generic frequency have passed

        // Given
        let threeDaysAgo = Date(timeInterval: -Constants.threeDaysInSeconds, since: Date())
        mockUserDefaults.set(threeDaysAgo, forKey: statsKey)
        mockUserDefaults.set(threeDaysAgo, forKey: genericKey)

        // When & Then
        XCTAssertFalse(statsTracker.shouldShow()) // Before feature-specific frequency have passed
        XCTAssertTrue(readerTracker.shouldShow()) // After generic frequency have passed
    }


}
