import XCTest
@testable import WordPress

final class OverlayFrequencyTrackerTests: XCTestCase {

    private enum Constants {
        static let frequencyConfig = OverlayFrequencyTracker.FrequencyConfig(featureSpecificInDays: 4, generalInDays: 2)
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
        let key = OverlayFrequencyTracker.Constants.lastDateKeyPrefix + "-stats"
        let genericKey = OverlayFrequencyTracker.Constants.lastDateKeyPrefix
        let tracker = OverlayFrequencyTracker(source: JetpackFeaturesRemovalCoordinator.JetpackOverlaySource.stats,
                                              type: .featuresRemoval,
                                              persistenceStore: mockUserDefaults)

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
        let key = OverlayFrequencyTracker.Constants.lastDateKeyPrefix + "-card"
        let genericKey = OverlayFrequencyTracker.Constants.lastDateKeyPrefix
        let tracker = OverlayFrequencyTracker(source: JetpackFeaturesRemovalCoordinator.JetpackOverlaySource.card,
                                              type: .featuresRemoval,
                                              persistenceStore: mockUserDefaults)
        mockUserDefaults.set(Date(), forKey: key)
        mockUserDefaults.set(Date(), forKey: genericKey)

        // When & Then
        XCTAssertTrue(tracker.shouldShow(forced: false))
    }

    func testShowLoginOverlayOnlyOnce() {
        // Given
        let key = OverlayFrequencyTracker.Constants.lastDateKeyPrefix + "-login-phaseString"
        let genericKey = OverlayFrequencyTracker.Constants.lastDateKeyPrefix
        let tracker = OverlayFrequencyTracker(source: JetpackFeaturesRemovalCoordinator.JetpackOverlaySource.login,
                                              type: .featuresRemoval,
                                              phaseString: "phaseString",
                                              persistenceStore: mockUserDefaults)

        // When & Then
        XCTAssertTrue(tracker.shouldShow(forced: false))

        // Given
        let distantDate = Date.distantPast
        mockUserDefaults.set(distantDate, forKey: key)
        mockUserDefaults.set(distantDate, forKey: genericKey)

        // When & Then
        XCTAssertFalse(tracker.shouldShow(forced: false))
    }

    func testShowAppOpenOverlayOnlyOnce() {
        // Given
        let key = OverlayFrequencyTracker.Constants.lastDateKeyPrefix + "-app_open-phaseString"
        let genericKey = OverlayFrequencyTracker.Constants.lastDateKeyPrefix
        let tracker = OverlayFrequencyTracker(source: JetpackFeaturesRemovalCoordinator.JetpackOverlaySource.appOpen,
                                              type: .featuresRemoval,
                                              phaseString: "phaseString",
                                              persistenceStore: mockUserDefaults)

        // When & Then
        XCTAssertTrue(tracker.shouldShow(forced: false))

        // Given
        let distantDate = Date.distantPast
        mockUserDefaults.set(distantDate, forKey: key)
        mockUserDefaults.set(distantDate, forKey: genericKey)

        // When & Then
        XCTAssertFalse(tracker.shouldShow(forced: false))
    }

    func testOverridingFrequencyLogic() {
        // Given
        let key = OverlayFrequencyTracker.Constants.lastDateKeyPrefix + "-app_open-phaseString"
        let genericKey = OverlayFrequencyTracker.Constants.lastDateKeyPrefix
        let tracker = OverlayFrequencyTracker(source: JetpackFeaturesRemovalCoordinator.JetpackOverlaySource.appOpen,
                                              type: .featuresRemoval,
                                              phaseString: "phaseString",
                                              persistenceStore: mockUserDefaults)

        // When & Then
        XCTAssertTrue(tracker.shouldShow(forced: false))

        // Given
        let distantDate = Date.distantPast
        mockUserDefaults.set(distantDate, forKey: key)
        mockUserDefaults.set(distantDate, forKey: genericKey)

        // When & Then
        XCTAssertTrue(tracker.shouldShow(forced: true))
    }

    func testFeatureSpecificFrequency() {
        // Given
        let statsKey = OverlayFrequencyTracker.Constants.lastDateKeyPrefix + "-stats"
        let genericKey = OverlayFrequencyTracker.Constants.lastDateKeyPrefix
        let tracker = OverlayFrequencyTracker(source: JetpackFeaturesRemovalCoordinator.JetpackOverlaySource.stats,
                                              type: .featuresRemoval,
                                              frequencyConfig: Constants.frequencyConfig,
                                              persistenceStore: mockUserDefaults)

        // When & Then
        XCTAssertTrue(tracker.shouldShow(forced: false)) // First time

        // Given
        let threeDaysAgo = Date(timeInterval: -Constants.threeDaysInSeconds, since: Date())
        mockUserDefaults.set(threeDaysAgo, forKey: statsKey)
        mockUserDefaults.set(threeDaysAgo, forKey: genericKey)

        // When & Then
        XCTAssertFalse(tracker.shouldShow(forced: false)) // Before feature-specific frequency have passed

        // Given
        let fiveDaysAgo = Date(timeInterval: -Constants.fiveDaysInSeconds, since: Date())
        mockUserDefaults.set(fiveDaysAgo, forKey: statsKey)
        mockUserDefaults.set(fiveDaysAgo, forKey: genericKey)

        // When & Then
        XCTAssertTrue(tracker.shouldShow(forced: false)) // After feature-specific frequency have passed
    }

    func testGeneralFrequency() {
        // Given
        let statsKey = OverlayFrequencyTracker.Constants.lastDateKeyPrefix + "-stats"
        let genericKey = OverlayFrequencyTracker.Constants.lastDateKeyPrefix
        let statsTracker = OverlayFrequencyTracker(source: JetpackFeaturesRemovalCoordinator.JetpackOverlaySource.stats,
                                                   type: .featuresRemoval,
                                                   frequencyConfig: Constants.frequencyConfig,
                                                   persistenceStore: mockUserDefaults)
        let readerTracker = OverlayFrequencyTracker(source: JetpackFeaturesRemovalCoordinator.JetpackOverlaySource.reader,
                                                    type: .featuresRemoval,
                                                    frequencyConfig: Constants.frequencyConfig,
                                                    persistenceStore: mockUserDefaults)

        // When & Then
        XCTAssertTrue(statsTracker.shouldShow(forced: false)) // First time
        XCTAssertTrue(readerTracker.shouldShow(forced: false)) // First time

        // Given
        let oneDayAgo = Date(timeInterval: -Constants.oneDayInSeconds, since: Date())
        mockUserDefaults.set(oneDayAgo, forKey: statsKey)
        mockUserDefaults.set(oneDayAgo, forKey: genericKey)

        // When & Then
        XCTAssertFalse(statsTracker.shouldShow(forced: false)) // Before generic frequency have passed
        XCTAssertFalse(readerTracker.shouldShow(forced: false)) // Before generic frequency have passed

        // Given
        let threeDaysAgo = Date(timeInterval: -Constants.threeDaysInSeconds, since: Date())
        mockUserDefaults.set(threeDaysAgo, forKey: statsKey)
        mockUserDefaults.set(threeDaysAgo, forKey: genericKey)

        // When & Then
        XCTAssertFalse(statsTracker.shouldShow(forced: false)) // Before feature-specific frequency have passed
        XCTAssertTrue(readerTracker.shouldShow(forced: false)) // After generic frequency have passed
    }

    func testNegativeFrequencyIsTreatedAsShowOnce() {
        // Given
        let key = OverlayFrequencyTracker.Constants.lastDateKeyPrefix + "-phase_four_overlay"
        let genericKey = OverlayFrequencyTracker.Constants.lastDateKeyPrefix
        let tracker = OverlayFrequencyTracker(source: JetpackFeaturesRemovalCoordinator.JetpackOverlaySource.phaseFourOverlay,
                                              type: .featuresRemoval,
                                              frequencyConfig: .init(featureSpecificInDays: 0, generalInDays: -1),
                                              persistenceStore: mockUserDefaults)

        // When & Then
        XCTAssertTrue(tracker.shouldShow(forced: false))

        // Given
        let distantDate = Date.distantPast
        mockUserDefaults.set(distantDate, forKey: key)
        mockUserDefaults.set(distantDate, forKey: genericKey)

        // When & Then
        XCTAssertFalse(tracker.shouldShow(forced: false))
    }


}
