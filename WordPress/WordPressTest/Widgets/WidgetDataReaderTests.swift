import XCTest
@testable import WordPress

final class WidgetDataReaderTests: XCTestCase {
    func testNoSite() {
        let intent = SelectSiteIntent()
        intent.site = Site(identifier: nil, display: "")
        let sut = makeSUT(
            makeUserDefaults(suiteName: #function),
            makeCacheReader(isCacheExisted: false),
            isLoggedIn: true
        )

        verifyWidgetStatus(sut, configuration: intent, defaultSiteID: nil, expectNoSite: true)
    }

    func testSiteSelectedWithNoDefaultSiteAvailable() {
        let intent = SelectSiteIntent()
        intent.site = Site(identifier: nil, display: "")
        let sut = makeSUT(
            makeUserDefaults(suiteName: #function),
            makeCacheReader(isCacheExisted: true),
            isLoggedIn: true
        )

        verifyWidgetStatus(sut, configuration: intent, defaultSiteID: nil, expectSiteSelected: true)
    }

    func testLoggedOut() {
        let intent = SelectSiteIntent()
        intent.site = Site(identifier: nil, display: "")
        let sut = makeSUT(
            makeUserDefaults(suiteName: #function),
            makeCacheReader(isCacheExisted: true),
            isLoggedIn: false
        )

        verifyWidgetStatus(sut, configuration: intent, defaultSiteID: nil, expectLoggedOut: true)
    }

    func testNoDataWhenNoUserDefaults() {
        let intent = SelectSiteIntent()
        intent.site = Site(identifier: nil, display: "")
        let sut = makeSUT(
            nil,
            makeCacheReader(isCacheExisted: true),
            isLoggedIn: false
        )

        verifyWidgetStatus(sut, configuration: intent, defaultSiteID: 123, expectNoData: true)
    }

    func testNoDataWhenWidgetDataNotFound() {
        let intent = SelectSiteIntent()
        intent.site = Site(identifier: "test", display: "")
        let sut = makeSUT(
            makeUserDefaults(suiteName: #function),
            makeCacheReader(isCacheExisted: false),
            isLoggedIn: true
        )

        verifyWidgetStatus(sut, configuration: intent, defaultSiteID: 123, expectNoData: true)
    }

    func testSiteSelected() {
        let intent = SelectSiteIntent()
        intent.site = Site(identifier: "test", display: "")
        let sut = makeSUT(
            makeUserDefaults(suiteName: #function),
            makeCacheReader(isCacheExisted: true),
            isLoggedIn: true
        )

        verifyWidgetStatus(sut, configuration: intent, defaultSiteID: 123, expectSiteSelected: true)
    }
}

extension WidgetDataReaderTests {
    func makeSUT(
        _ userDefaults: UserDefaults?,
        _ cacheReader: WidgetDataCacheReader,
        isLoggedIn: Bool
    ) -> WidgetDataReader<HomeWidgetTodayData> {
        userDefaults?.set(isLoggedIn, forKey: AppConfiguration.Widget.Stats.userDefaultsLoggedInKey)
        return WidgetDataReader<HomeWidgetTodayData>(userDefaults, cacheReader)
    }

    func makeUserDefaults(suiteName: String) -> UserDefaults? {
        let userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults?.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    func makeCacheReader(isCacheExisted: Bool) -> MockHomeWidgetDataFileReader {
        MockHomeWidgetDataFileReader(isMockDataReturned: isCacheExisted)
    }

    func verifyWidgetStatus(
        _ sut: WidgetDataReader<HomeWidgetTodayData>,
        configuration: SelectSiteIntent,
        defaultSiteID: Int?,
        expectDisabled: Bool = false,
        expectNoData: Bool = false,
        expectNoSite: Bool = false,
        expectLoggedOut: Bool = false,
        expectSiteSelected: Bool = false
    ) {
        let disabledExpectation = XCTestExpectation(description: "Disabled Expectation")
        disabledExpectation.isInverted = !expectDisabled
        let noDataExpectation = XCTestExpectation(description: "NoData Expectation")
        noDataExpectation.isInverted = !expectNoData
        let noSiteExpectation = XCTestExpectation(description: "NoSite Expectation")
        noSiteExpectation.isInverted = !expectNoSite
        let loggedOutExpectation = XCTestExpectation(description: "LoggedOut Expectation")
        loggedOutExpectation.isInverted = !expectLoggedOut
        let siteSelectedExpectation = XCTestExpectation(description: "NoSiteSelected Expectation")
        siteSelectedExpectation.isInverted = !expectSiteSelected

        switch sut.widgetData(
            for: configuration,
            defaultSiteID: defaultSiteID
        ) {
        case .success:
            siteSelectedExpectation.fulfill()
        case .failure(let error):
            switch error {
            case .noData:
                noDataExpectation.fulfill()
            case .noSite:
                noSiteExpectation.fulfill()
            case .loggedOut:
                loggedOutExpectation.fulfill()
            case .jetpackFeatureDisabled:
                disabledExpectation.fulfill()
            }
        }
        wait(for: [
            disabledExpectation,
            noDataExpectation,
            noSiteExpectation,
            loggedOutExpectation,
            siteSelectedExpectation
        ], timeout: 0.1)
    }
}

struct MockHomeWidgetDataFileReader: WidgetDataCacheReader {
    let mockData = HomeWidgetTodayData(siteID: 0,
                                       siteName: "My WordPress Site",
                                       url: "",
                                       timeZone: TimeZone.current,
                                       date: Date(),
                                       stats: TodayWidgetStats(
                                        views: 649,
                                        visitors: 572,
                                        likes: 16,
                                        comments: 8
                                       ))
    let isMockDataReturned: Bool

    func widgetData<T: HomeWidgetData>(for siteID: String) -> T? {
        if isMockDataReturned {
            return mockData as? T
        } else {
            return nil
        }
    }

    func widgetData<T: HomeWidgetData>() -> [T]? {
        if isMockDataReturned {
            return [mockData] as? [T]
        } else {
            return nil
        }
    }
}
