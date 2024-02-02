import Foundation

struct StatsTrafficBarChartMockData {
    let tabsData: [BarChartTabData]
    let summary: StatsSummaryTimeIntervalData
    let period: StatsPeriodUnit

    static let data: [StatsTrafficBarChartMockData] = [
        .init(
            tabsData: [Week.barChartTabData1, Week.barChartTabData2, Week.barChartTabData3, Week.barChartTabData4],
            summary: Week.statsSummaryTimeIntervalData,
            period: .week
        ),
        .init(
            tabsData: [Month.barChartTabData1, Month.barChartTabData2, Month.barChartTabData3, Month.barChartTabData4],
            summary: Month.statsSummaryTimeIntervalData,
            period: .month
        ),
        .init(
            tabsData: [Year.barChartTabData1, Year.barChartTabData2, Year.barChartTabData3, Year.barChartTabData4],
            summary: Year.statsSummaryTimeIntervalData,
            period: .year
        ),
        .init(
            tabsData: [Empty.barChartTabData1, Empty.barChartTabData2, Empty.barChartTabData3, Empty.barChartTabData4],
            summary: Empty.statsSummaryTimeIntervalData,
            period: .month
        ),
    ]

    struct Week {
        static let barChartTabData1 = BarChartTabData(
            tabTitle: "Views",
            tabData: 143,
            difference: -176,
            differencePercent: -55,
            date: Date(timeIntervalSinceReferenceDate: 726969600.0),
            period: .week,
            analyticsStat: nil
        )

        static let barChartTabData2 = BarChartTabData(
            tabTitle: "Visitors",
            tabData: 17,
            difference: -14,
            differencePercent: -45,
            date: Date(timeIntervalSinceReferenceDate: 726969600.0),
            period: .week,
            analyticsStat: nil
        )

        static let barChartTabData3 = BarChartTabData(
            tabTitle: "Likes",
            tabData: 6,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726969600.0),
            period: .week,
            analyticsStat: nil
        )

        static let barChartTabData4 = BarChartTabData(
            tabTitle: "Comments",
            tabData: 3,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 726969600.0),
            period: .week,
            analyticsStat: nil
        )

        static let statsSummaryData = [
            StatsSummaryData(
                period: .day,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726796800.0),
                viewsCount: 2,
                visitorsCount: 1,
                likesCount: 0,
                commentsCount: 0
            ),
            StatsSummaryData(
                period: .day,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726883200.0),
                viewsCount: 0,
                visitorsCount: 0,
                likesCount: 0,
                commentsCount: 0
            ),
            StatsSummaryData(
                period: .day,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726969600.0),
                viewsCount: 17,
                visitorsCount: 6,
                likesCount: 0,
                commentsCount: 0
            ),
            StatsSummaryData(
                period: .day,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 727056000.0),
                viewsCount: 37,
                visitorsCount: 9,
                likesCount: 2,
                commentsCount: 0
            ),
            StatsSummaryData(
                period: .day,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 727142400.0),
                viewsCount: 23,
                visitorsCount: 5,
                likesCount: 0,
                commentsCount: 0
            ),
            StatsSummaryData(
                period: .day,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 727228800.0),
                viewsCount: 59,
                visitorsCount: 7,
                likesCount: 3,
                commentsCount: 2
            ),
            StatsSummaryData(
                period: .day,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 727315200.0),
                viewsCount: 8,
                visitorsCount: 5,
                likesCount: 1,
                commentsCount: 1
            )
        ]

        static let statsSummaryTimeIntervalData = StatsSummaryTimeIntervalData(
            period: .day,
            periodEndDate: Date(timeIntervalSinceReferenceDate: 727315200.0),
            summaryData: statsSummaryData
        )
    }

    struct Month {
        static let barChartTabData1 = BarChartTabData(
            tabTitle: "Views",
            tabData: 1136,
            difference: 294,
            differencePercent: 35,
            date: Date(timeIntervalSinceReferenceDate: 725760000.0),
            period: .month,
            analyticsStat: nil
        )

        static let barChartTabData2 = BarChartTabData(
            tabTitle: "Visitors",
            tabData: 49,
            difference: 13,
            differencePercent: 36,
            date: Date(timeIntervalSinceReferenceDate: 725760000.0),
            period: .month,
            analyticsStat: nil
        )

        static let barChartTabData3 = BarChartTabData(
            tabTitle: "Likes",
            tabData: 52,
            difference: 36,
            differencePercent: 225,
            date: Date(timeIntervalSinceReferenceDate: 725760000.0),
            period: .month,
            analyticsStat: nil
        )

        static let barChartTabData4 = BarChartTabData(
            tabTitle: "Comments",
            tabData: 28,
            difference: 16,
            differencePercent: 133,
            date: Date(timeIntervalSinceReferenceDate: 725760000.0),
            period: .month,
            analyticsStat: nil
        )

        static let statsSummaryData = [
            StatsSummaryData(
                period: .week,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 724550400.0),
                viewsCount: 247,
                visitorsCount: 10,
                likesCount: 3,
                commentsCount: 0
            ),
            StatsSummaryData(
                period: .week,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 725155200.0),
                viewsCount: 232,
                visitorsCount: 22,
                likesCount: 6,
                commentsCount: 2
            ),
            StatsSummaryData(
                period: .week,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 725760000.0),
                viewsCount: 670,
                visitorsCount: 28,
                likesCount: 27,
                commentsCount: 11
            ),
            StatsSummaryData(
                period: .week,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726364800.0),
                viewsCount: 319,
                visitorsCount: 31,
                likesCount: 19,
                commentsCount: 14
            ),
            StatsSummaryData(
                period: .week,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726969600.0),
                viewsCount: 147,
                visitorsCount: 18,
                likesCount: 6,
                commentsCount: 3
            )
        ]

        static let statsSummaryTimeIntervalData = StatsSummaryTimeIntervalData(
            period: .week,
            periodEndDate: Date(timeIntervalSinceReferenceDate: 727315200.0),
            summaryData: statsSummaryData
        )
    }

    struct Year {
        static let barChartTabData1 = BarChartTabData(
                tabTitle: "Views",
                tabData: 113326,
                difference: 0,
                differencePercent: 0,
                date: Date(timeIntervalSinceReferenceDate: 725760000.0),
                period: .year,
                analyticsStat: nil
            )

            static let barChartTabData2 = BarChartTabData(
                tabTitle: "Visitors",
                tabData: 43329,
                difference: -352,
                differencePercent: -88,
                date: Date(timeIntervalSinceReferenceDate: 725760000.0),
                period: .year,
                analyticsStat: nil
            )

            static let barChartTabData3 = BarChartTabData(
                tabTitle: "Likes",
                tabData: 5232,
                difference: -252,
                differencePercent: -83,
                date: Date(timeIntervalSinceReferenceDate: 725760000.0),
                period: .year,
                analyticsStat: nil
            )

            static let barChartTabData4 = BarChartTabData(
                tabTitle: "Comments",
                tabData: 2538,
                difference: -527,
                differencePercent: -95,
                date: Date(timeIntervalSinceReferenceDate: 725760000.0),
                period: .year,
                analyticsStat: nil
            )

        static let statsSummaryData = [
                StatsSummaryData(
                    period: .month,
                    periodStartDate: Date(timeIntervalSinceReferenceDate: 696902400.0),
                    viewsCount: 676,
                    visitorsCount: 30,
                    likesCount: 26,
                    commentsCount: 27
                ),
                StatsSummaryData(
                    period: .month,
                    periodStartDate: Date(timeIntervalSinceReferenceDate: 699321600.0),
                    viewsCount: 1194,
                    visitorsCount: 53,
                    likesCount: 44,
                    commentsCount: 102
                ),
                StatsSummaryData(
                    period: .month,
                    periodStartDate: Date(timeIntervalSinceReferenceDate: 701996400.0),
                    viewsCount: 1236,
                    visitorsCount: 39,
                    likesCount: 21,
                    commentsCount: 83
                ),
                StatsSummaryData(
                    period: .month,
                    periodStartDate: Date(timeIntervalSinceReferenceDate: 704588400.0),
                    viewsCount: 1577,
                    visitorsCount: 54,
                    likesCount: 48,
                    commentsCount: 80
                ),
                StatsSummaryData(
                    period: .month,
                    periodStartDate: Date(timeIntervalSinceReferenceDate: 707266800.0),
                    viewsCount: 659,
                    visitorsCount: 29,
                    likesCount: 14,
                    commentsCount: 36
                ),
                StatsSummaryData(
                    period: .month,
                    periodStartDate: Date(timeIntervalSinceReferenceDate: 709858800.0),
                    viewsCount: 426,
                    visitorsCount: 23,
                    likesCount: 17,
                    commentsCount: 15
                ),
                StatsSummaryData(
                    period: .month,
                    periodStartDate: Date(timeIntervalSinceReferenceDate: 712537200.0),
                    viewsCount: 510,
                    visitorsCount: 30,
                    likesCount: 18,
                    commentsCount: 18
                ),
                StatsSummaryData(
                    period: .month,
                    periodStartDate: Date(timeIntervalSinceReferenceDate: 715215600.0),
                    viewsCount: 750,
                    visitorsCount: 27,
                    likesCount: 28,
                    commentsCount: 57
                ),
                StatsSummaryData(
                    period: .month,
                    periodStartDate: Date(timeIntervalSinceReferenceDate: 717807600.0),
                    viewsCount: 842,
                    visitorsCount: 31,
                    likesCount: 29,
                    commentsCount: 45
                ),
                StatsSummaryData(
                    period: .month,
                    periodStartDate: Date(timeIntervalSinceReferenceDate: 720489600.0),
                    viewsCount: 616,
                    visitorsCount: 24,
                    likesCount: 13,
                    commentsCount: 22
                ),
                StatsSummaryData(
                    period: .month,
                    periodStartDate: Date(timeIntervalSinceReferenceDate: 723081600.0),
                    viewsCount: 842,
                    visitorsCount: 36,
                    likesCount: 16,
                    commentsCount: 12
                ),
                StatsSummaryData(
                    period: .month,
                    periodStartDate: Date(timeIntervalSinceReferenceDate: 725760000.0),
                    viewsCount: 1136,
                    visitorsCount: 49,
                    likesCount: 52,
                    commentsCount: 28
                )
            ]

            static let statsSummaryTimeIntervalData = StatsSummaryTimeIntervalData(
                period: .month,
                periodEndDate: Date(timeIntervalSinceReferenceDate: 727315200.0),
                summaryData: statsSummaryData
            )
    }

    struct Empty {
        static let barChartTabData1 = BarChartTabData(
            tabTitle: "Views",
            tabData: 0,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 725760000.0),
            period: .month,
            analyticsStat: nil
        )

        static let barChartTabData2 = BarChartTabData(
            tabTitle: "Visitors",
            tabData: 0,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 725760000.0),
            period: .month,
            analyticsStat: nil
        )

        static let barChartTabData3 = BarChartTabData(
            tabTitle: "Likes",
            tabData: 0,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 725760000.0),
            period: .month,
            analyticsStat: nil
        )

        static let barChartTabData4 = BarChartTabData(
            tabTitle: "Comments",
            tabData: 0,
            difference: 0,
            differencePercent: 0,
            date: Date(timeIntervalSinceReferenceDate: 725760000.0),
            period: .month,
            analyticsStat: nil
        )

        static let statsSummaryData = [
            StatsSummaryData(
                period: .week,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 724550400.0),
                viewsCount: 0,
                visitorsCount: 0,
                likesCount: 0,
                commentsCount: 0
            ),
            StatsSummaryData(
                period: .week,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 725155200.0),
                viewsCount: 0,
                visitorsCount: 0,
                likesCount: 0,
                commentsCount: 2
            ),
            StatsSummaryData(
                period: .week,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 725760000.0),
                viewsCount: 0,
                visitorsCount: 0,
                likesCount: 0,
                commentsCount: 0
            ),
            StatsSummaryData(
                period: .week,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726364800.0),
                viewsCount: 0,
                visitorsCount: 0,
                likesCount: 0,
                commentsCount: 0
            ),
            StatsSummaryData(
                period: .week,
                periodStartDate: Date(timeIntervalSinceReferenceDate: 726969600.0),
                viewsCount: 0,
                visitorsCount: 0,
                likesCount: 0,
                commentsCount: 3
            )
        ]

        static let statsSummaryTimeIntervalData = StatsSummaryTimeIntervalData(
            period: .week,
            periodEndDate: Date(timeIntervalSinceReferenceDate: 727315200.0),
            summaryData: statsSummaryData
        )
    }

}

class StatsTrafficBarChartMockVC: UITableViewController {
    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(StatsTrafficBarChartCell.self, forCellReuseIdentifier: "StatsTrafficBarChartCell")
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StatsTrafficBarChartCell", for: indexPath) as! StatsTrafficBarChartCell
        let data = StatsTrafficBarChartMockData.data[indexPath.section]
        let chart = StatsTrafficBarChart(data: data.summary)
        cell.configure(
            tabsData: data.tabsData,
            barChartData: chart.barChartData,
            barChartStyling: chart.barChartStyling,
            period: data.period
        )
        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return StatsTrafficBarChartMockData.data.count
    }
}
