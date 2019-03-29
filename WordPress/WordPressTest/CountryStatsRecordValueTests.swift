@testable import WordPress

class CountryStatsRecordValueTests: StatsTestCase {

    func testCreation() {
        let parent = createStatsRecord(in: mainContext, type: .countryViews, period: .year, date: Date())

        let country = CountryStatsRecordValue(parent: parent)
        country.viewsCount = 9001
        country.countryCode = "de"
        country.countryName = "🇩🇪"

        XCTAssertNoThrow(try mainContext.save())

        let fr = StatsRecord.fetchRequest(for: .countryViews, on: Date(), periodType: .year)

        let results = try! mainContext.fetch(fr)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first!.values?.count, 1)

        let fetchedCountry = results.first?.values?.firstObject! as! CountryStatsRecordValue

        XCTAssertEqual(fetchedCountry.viewsCount, country.viewsCount)
        XCTAssertEqual(fetchedCountry.countryCode, country.countryCode)
        XCTAssertEqual(fetchedCountry.countryName, country.countryName)
    }

}
