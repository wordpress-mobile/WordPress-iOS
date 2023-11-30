import JetpackStatsWidgetsCore
import XCTest

final class WidgetDataCacheReaderTests: XCTestCase {

    typealias Result = Swift.Result<HomeWidgetDataDouble, WidgetDataReadError>

    /// When the cache has data for the requested site, it returns it regardless of whether the user is logged in
    func testWidgetDataForKnownSiteIdentifier() {
        let data = HomeWidgetDataDouble(siteID: 1)
        let sut = WidgetDataCacheReaderDouble(dataToReturn: data)

        assert(
            result: sut.widgetData(forSiteIdentifier: "1", defaultSiteID: 2, userLoggedIn: false),
            equals: .success(data)
        )
        assert(
            result: sut.widgetData(forSiteIdentifier: "1", defaultSiteID: nil, userLoggedIn: false),
            equals: .success(data)
        )
        assert(
            result: sut.widgetData(forSiteIdentifier: "1", defaultSiteID: 2, userLoggedIn: true),
            equals: .success(data)
        )
        assert(
            result: sut.widgetData(forSiteIdentifier: "1", defaultSiteID: nil, userLoggedIn: true),
            equals: .success(data)
        )
    }

    /// When the requested site id is not in the cache but the default site is,
    /// it returns it regardless of the user logged in status
    func testWidgetDataForNilSiteIdentifierWithDataForDefaultSite() {
        let id = 1
        let data = HomeWidgetDataDouble(siteID: id)
        let sut = WidgetDataCacheReaderDouble(dataToReturn: data)

        assert(
            result: sut.widgetData(forSiteIdentifier: nil, defaultSiteID: id, userLoggedIn: true),
            equals: .success(data)
        )
        assert(
            result: sut.widgetData(forSiteIdentifier: nil, defaultSiteID: id, userLoggedIn: false),
            equals: .success(data)
        )
    }

    /// When the requested site id is nil but the cache has data for the default site,
    /// it returns it data for the default site, regardless of the user logged in status
    func testWidgetDataForMissingSiteIdentifierWithDataForDefaultSite() {
        let id = 1
        let data = HomeWidgetDataDouble(siteID: id)
        let sut = WidgetDataCacheReaderDouble(dataToReturn: data)

        assert(
            result: sut.widgetData(forSiteIdentifier: "2", defaultSiteID: id, userLoggedIn: true),
            equals: .success(data)
        )
        assert(
            result: sut.widgetData(forSiteIdentifier: "2", defaultSiteID: id, userLoggedIn: false),
            equals: .success(data)
        )
    }

    /// When the cache has no data and the user is logged out, it always returns a failure with the "logged out" error
    func testWidgetDataWithNoDataAndUserLoggedOut() {
        let sut = WidgetDataCacheReaderDouble(dataToReturn: nil)

        assert(
            result: sut.widgetData(forSiteIdentifier: "1", defaultSiteID: 2, userLoggedIn: false),
            equals: .failure(.loggedOut)
        )
        assert(
            result: sut.widgetData(forSiteIdentifier: "1", defaultSiteID: nil, userLoggedIn: false),
            equals: .failure(.loggedOut)
        )
        assert(
            result: sut.widgetData(forSiteIdentifier: nil, defaultSiteID: 2, userLoggedIn: false),
            equals: .failure(.loggedOut)
        )
        assert(
            result: sut.widgetData(forSiteIdentifier: nil, defaultSiteID: nil, userLoggedIn: false),
            equals: .failure(.loggedOut)
        )
    }

    /// When the cache has no data and the user is logged in, it always returns a failure with the "no site" error
    func testWidgetDataWithNoDataAndUserLoggedIn() {
        let sut = WidgetDataCacheReaderDouble(dataToReturn: nil)

        assert(
            result: sut.widgetData(forSiteIdentifier: "id", defaultSiteID: 1, userLoggedIn: true),
            equals: .failure(.noSite)
        )
        assert(
            result: sut.widgetData(forSiteIdentifier: "id", defaultSiteID: nil, userLoggedIn: true),
            equals: .failure(.noSite)
        )
        assert(
            result: sut.widgetData(forSiteIdentifier: nil, defaultSiteID: 1, userLoggedIn: true),
            equals: .failure(.noSite)
        )
        assert(
            result: sut.widgetData(forSiteIdentifier: nil, defaultSiteID: nil, userLoggedIn: true),
            equals: .failure(.noSite)
        )
    }

    /// When the cache has data that doesn't match the input parameters, and the user is logged in,
    /// it returns the site with the lower id
    func testWidgetDataFallbackWhenLoggedIn() {
        let data = HomeWidgetDataDouble(siteID: 0)
        let sut = WidgetDataCacheReaderDouble(
            dataToReturn: [
                // Notice the not-sorted order, to verify the SUT uses logic insted of picking the first in the list
                HomeWidgetDataDouble(siteID: 2),
                data,
                HomeWidgetDataDouble(siteID: 1)
            ]
        )

        assert(
            result: sut.widgetData(forSiteIdentifier: "3", defaultSiteID: 4, userLoggedIn: true),
            equals: .success(data)
        )
        assert(
            result: sut.widgetData(forSiteIdentifier: "3", defaultSiteID: nil, userLoggedIn: true),
            equals: .success(data)
        )
        assert(
            result: sut.widgetData(forSiteIdentifier: nil, defaultSiteID: 4, userLoggedIn: true),
            equals: .success(data)
        )
        assert(
            result: sut.widgetData(forSiteIdentifier: nil, defaultSiteID: nil, userLoggedIn: true),
            equals: .success(data)
        )
    }

    /// When the cache has data that doesn't match the input parameters, and the user is logged out,
    /// it returns the "logged out" error
    func testWidgetDataFallbackWhenLoggedOut() {
        let sut = WidgetDataCacheReaderDouble(
            dataToReturn: [
                HomeWidgetDataDouble(siteID: 2),
                HomeWidgetDataDouble(siteID: 1)
            ]
        )

        assert(
            result: sut.widgetData(forSiteIdentifier: "3", defaultSiteID: 4, userLoggedIn: false),
            equals: .failure(.loggedOut)
        )
        assert(
            result: sut.widgetData(forSiteIdentifier: "3", defaultSiteID: nil, userLoggedIn: false),
            equals: .failure(.loggedOut)
        )
        assert(
            result: sut.widgetData(forSiteIdentifier: nil, defaultSiteID: 4, userLoggedIn: false),
            equals: .failure(.loggedOut)
        )
        assert(
            result: sut.widgetData(forSiteIdentifier: nil, defaultSiteID: nil, userLoggedIn: false),
            equals: .failure(.loggedOut)
        )
    }

    // MARK: -

    func assert(result actual: Result, equals expected: Result, line: UInt = #line) {
        switch (actual, expected) {
        case (.success(let actualData), .success(let expectedData)):
            XCTAssertEqual(actualData, expectedData, line: line)
        case (.failure(let actualError), .failure(let expectedError)):
            XCTAssertEqual(actualError, expectedError, line: line)
        case (.success(let data), .failure):
            XCTFail("Expected to fail but succeeded with \(data)", line: line)
        case (.failure(let error), .success):
            XCTFail("Expected to succeed but failed with \(error)", line: line)
        }
    }
}

struct WidgetDataCacheReaderDouble: WidgetDataCacheReader {

    private let results: [StubbedResult]

    struct StubbedResult {
        let id: String
        let data: HomeWidgetDataDouble?

        init(id: String, data: HomeWidgetDataDouble?) {
            self.id = id
            self.data = data
        }

        init(double: HomeWidgetDataDouble) {
            self.init(
                id: "\(double.siteID)",
                data: double
            )
        }
    }

    init(dataToReturn: HomeWidgetDataDouble?) {
        self.results = dataToReturn.map { [StubbedResult(double: $0)] } ?? []
    }

    init(dataToReturn: [HomeWidgetDataDouble]) {
        self.results = dataToReturn.map { StubbedResult(double: $0) }
    }

    init(results: [StubbedResult]) {
        self.results = results
    }

    func widgetData<T: HomeWidgetData>() -> [T]? {
        results.map(\.data) as? [T]
    }

    func widgetData<T>(for siteID: String) -> T? where T: HomeWidgetData {
        results.first(where: { $0.id == siteID })?.data as? T
    }
}

struct HomeWidgetDataDouble: HomeWidgetData, Equatable {
    let siteID: Int
    let siteName: String
    let url: String
    let timeZone: TimeZone
    let date: Date
    let statsURL: URL?

    static let filename: String = "test"

    init(
        siteID: Int = 1,
        siteName: String = "name",
        url: String = "https://test.com",
        timeZone: TimeZone = .current, // Would like to use .gmt (deterministic) once targeting 16+,
        date: Date = Date(), // Would like to use .now (clearer) once targeting 15+
        statsURL: URL? = nil
    ) {
        self.siteID = siteID
        self.siteName = siteName
        self.url = url
        self.timeZone = timeZone
        self.date = date
        self.statsURL = statsURL
    }
}
