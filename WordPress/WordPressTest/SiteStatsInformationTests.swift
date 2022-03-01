import XCTest
@testable import WordPress

class SiteStatsInformationTests: XCTestCase {

    class MockUserDefaults: UserDefaults {

        let mockInsightValues: [SiteStatsInformation.SiteInsights] = [["1": [3, 4]], ["2": [1, 3]]]

        var setUserDefaultsExpectation: XCTestExpectation?

        override func object(forKey defaultName: String) -> Any? {
            mockInsightValues
        }

        override func set(_ value: Any?, forKey defaultName: String) {
            setUserDefaultsExpectation?.fulfill()
        }
    }

    func testReadCustomInsights() {
        // Given
        let mockUserDefaults = MockUserDefaults()
        let mockTypes = InsightType.typesForValues([3, 4])
        SiteStatsInformation.sharedInstance.siteID = 1
        // When
        let returnedTypes = SiteStatsInformation.sharedInstance.getCurrentSiteInsights(mockUserDefaults)
        // Then
        XCTAssertEqual(returnedTypes, mockTypes)
    }

    func testReadDefaultInsights() {
        // Given
        let mockUserDefaults = MockUserDefaults()
        SiteStatsInformation.sharedInstance.siteID = 3
        // When
        let returnedTypes = SiteStatsInformation.sharedInstance.getCurrentSiteInsights(mockUserDefaults)
        // Then
        XCTAssertEqual(returnedTypes, InsightType.defaultInsights)
    }

    func testWriteInsights() {
        // Given
        let mockUserDefaults = MockUserDefaults()
        mockUserDefaults.setUserDefaultsExpectation = expectation(description: "UserDefaults were written")
        // When
        SiteStatsInformation.sharedInstance.saveCurrentSiteInsights([.comments], mockUserDefaults)
        // Then
        waitForExpectations(timeout: 4) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
    }

    func testRemoveCustomizeGrowCards() {
        // Given Current Inights with customize and growaudience cards
        let userDefaults = UserDefaults(suiteName: "testRemoveCustomizeGrowCards")!
        userDefaults.removePersistentDomain(forName: "testRemoveCustomizeGrowCards")

        SiteStatsInformation.sharedInstance.siteID = 3
        var defaultInsights = SiteStatsInformation.sharedInstance.getCurrentSiteInsights(userDefaults)
        defaultInsights.insert(.growAudience, at: 0)
        defaultInsights.insert(.customize, at: 0)
        SiteStatsInformation.sharedInstance.saveCurrentSiteInsights(defaultInsights, userDefaults)

        let updatedInsights = SiteStatsInformation.sharedInstance.getCurrentSiteInsights(userDefaults)
        XCTAssertFalse( (updatedInsights.filter { $0 == .growAudience }).isEmpty )
        XCTAssertFalse( (updatedInsights.filter { $0 == .customize }).isEmpty )

        // When we remove customize and growaudience cards
        SiteStatsInformation.sharedInstance.removeCustomizeGrowCards(userDefaults)

        // Then customize and growaudience cards should no long exist
        let removedInsights = SiteStatsInformation.sharedInstance.getCurrentSiteInsights(userDefaults)
        XCTAssertTrue( (removedInsights.filter { $0 == .growAudience }).isEmpty )
        XCTAssertTrue( (removedInsights.filter { $0 == .customize }).isEmpty )
    }
}
