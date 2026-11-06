#if UI_TEST_HTTP_FIXTURES
import Foundation
import Testing
import HTTPFixtures

@Suite
struct StatsSeriesTests {
    private static let fields = #"""
        [
            {"name": "views", "average": 400, "hourly": true},
            {"name": "visitors", "average": 250},
            {"name": "subscribers", "level": 1200, "growth": 2}
        ]
        """#

    private let fixtures: FixtureSet

    init() throws {
        fixtures = try makeFixtureSet([
            "visits.json": mapping(
                #"{"method": "GET", "urlPath": "/stats/visits/"}"#,
                response: #"""
                    {"status": 200, "transformers": ["stats-series"], "transformerParameters": {"fields": \#(Self.fields)}}
                    """#
            )
        ])
    }

    private struct Series {
        let date: String
        let unit: String
        let fields: [String]
        let rows: [[Any]]

        var periods: [String] { rows.compactMap { $0.first as? String } }

        func values(of field: String) -> [Int?] {
            let index = fields.firstIndex(of: field) ?? 0
            return rows.map { $0[index] as? Int }
        }
    }

    private func series(_ query: String) throws -> Series {
        let response = fixtures.response(for: get("/stats/visits/?\(query)"))
        #expect(response.status == 200)
        #expect(response.headers["Content-Type"] == "application/json")
        let json = try #require(try JSONSerialization.jsonObject(with: response.body) as? [String: Any])
        return Series(
            date: json["date"] as? String ?? "",
            unit: json["unit"] as? String ?? "",
            fields: json["fields"] as? [String] ?? [],
            rows: json["data"] as? [[Any]] ?? []
        )
    }

    @Test func hasARowForEveryDayOfTheInterval() throws {
        let series = try series("unit=day&start_date=2026-09-29&date=2026-10-05&quantity=0")

        #expect(series.date == "2026-10-05")
        #expect(series.unit == "day")
        #expect(series.fields == ["period", "views", "visitors", "subscribers"])
        #expect(
            series.periods == [
                "2026-09-29", "2026-09-30", "2026-10-01", "2026-10-02", "2026-10-03", "2026-10-04", "2026-10-05"
            ]
        )
    }

    @Test func aDayHasTheSameValueInEveryInterval() throws {
        let week = try series("unit=day&start_date=2026-09-29&date=2026-10-05")
        let day = try series("unit=day&start_date=2026-10-02&date=2026-10-02")

        #expect(day.periods == ["2026-10-02"])
        #expect(day.values(of: "views") == [week.values(of: "views")[3]])
        #expect(day.values(of: "visitors") == [week.values(of: "visitors")[3]])
    }

    @Test func valuesVaryAroundTheAverage() throws {
        let views = try series("unit=day&start_date=2026-07-01&date=2026-09-28").values(of: "views").compactMap { $0 }

        #expect(views.count == 90)
        #expect(Set(views).count > 30)
        #expect(views.allSatisfy { (200...600).contains($0) })
        #expect((360...440).contains(views.reduce(0, +) / views.count))
    }

    @Test func countsBackFromTheDateWithoutAStartDate() throws {
        let series = try series("unit=day&date=2026-10-05&quantity=3")

        #expect(series.periods == ["2026-10-03", "2026-10-04", "2026-10-05"])
    }

    @Test func hoursOnlyHaveTheFieldsThatAreHourly() throws {
        let series = try series("unit=hour&start_date=2026-10-05%2000:00:00&date=2026-10-05%2023:59:59&quantity=0")

        #expect(series.date == "2026-10-05 23:59:59")
        #expect(series.periods.count == 24)
        #expect(series.periods.first == "2026-10-05 00:00:00")
        #expect(series.periods.last == "2026-10-05 23:00:00")
        #expect(series.values(of: "views").allSatisfy { $0 != nil })
        #expect(series.values(of: "visitors").allSatisfy { $0 == nil })
    }

    @Test func theHoursOfADayAddUpToAboutTheDay() throws {
        let hours = try series("unit=hour&start_date=2026-10-05%2000:00:00&date=2026-10-05%2023:59:59")
        let day = try series("unit=day&start_date=2026-10-05&date=2026-10-05")

        let total = hours.values(of: "views").compactMap { $0 }.reduce(0, +)
        let views = try #require(day.values(of: "views")[0])
        #expect(abs(total - views) <= 12)
    }

    @Test func aWeekIsTheSumOfItsDays() throws {
        // Weeks start on Monday, and are labeled the way WordPress.com labels them.
        let weeks = try series("unit=week&start_date=2026-09-21&date=2026-10-04")
        let days = try series("unit=day&start_date=2026-09-21&date=2026-10-04").values(of: "views").compactMap { $0 }

        #expect(weeks.periods == ["2026W09W21", "2026W09W28"])
        #expect(weeks.values(of: "views") == [days[0..<7].reduce(0, +), days[7..<14].reduce(0, +)])
    }

    @Test func monthsAndYearsAreLabeledWithTheirFirstDay() throws {
        #expect(
            try series("unit=month&start_date=2026-08-15&date=2026-10-05").periods == [
                "2026-08-01", "2026-09-01", "2026-10-01"
            ]
        )
        #expect(try series("unit=year&date=2026-10-05&quantity=2").periods == ["2025-01-01", "2026-01-01"])
    }

    @Test func aLevelIsItsValueTodayAndLowerBefore() throws {
        // The fixtures' clock reads 15 June 2025.
        let subscribers = try series("unit=day&start_date=2025-06-13&date=2025-06-15").values(of: "subscribers")

        #expect(subscribers == [1196, 1198, 1200])
    }

    @Test func hasNoRowsWithoutADate() throws {
        #expect(try series("unit=day").rows.isEmpty)
    }

    @Test(arguments: [
        #"{"status": 200, "transformers": ["stats-series"]}"#,
        #"{"status": 200, "transformers": ["stats-series"], "transformerParameters": {"fields": [{"name": "views"}]}}"#,
        #"{"status": 200, "transformers": ["stats-series"], "transformerParameters": {"fields": [], "seed": 1}}"#,
        #"{"status": 200, "transformers": ["random-values"]}"#,
        #"{"status": 200, "transformerParameters": {"fields": []}}"#
    ])
    func rejectsAResponseItCannotGenerate(response: String) {
        #expect(throws: FixtureError.self) {
            try makeFixtureSet(["visits.json": mapping(#"{"urlPath": "/stats/visits/"}"#, response: response)])
        }
    }
}
#endif
