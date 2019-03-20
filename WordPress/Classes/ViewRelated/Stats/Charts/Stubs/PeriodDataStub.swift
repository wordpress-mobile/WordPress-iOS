
import Foundation

import Charts

// MARK: - PeriodDatum

struct PeriodDatum: Decodable {
    let date: Date
    let viewCount: Int
    let visitorCount: Int
    let likeCount: Int
    let commentCount: Int
}

// MARK: - PeriodDataStub

class PeriodDataStub: DataStub<[PeriodDatum]> {
    init() {
        super.init([PeriodDatum].self, fileName: "period_data")
    }

    var periodData: [PeriodDatum] {
        return data as? [PeriodDatum] ?? []
    }
}

// MARK: - BarChartDataConvertible

extension PeriodDataStub: BarChartDataConvertible {
    var barChartData: BarChartData {

        let data = periodData

        // Our stub data is ordered
        let firstDateInterval: TimeInterval
        let lastDateInterval: TimeInterval
        let effectiveWidth: Double

        if data.isEmpty {
            firstDateInterval = 0
            lastDateInterval = 0
            effectiveWidth = 1
        } else {
            firstDateInterval = data.first!.date.timeIntervalSince1970
            lastDateInterval = data.last!.date.timeIntervalSince1970

            let range = lastDateInterval - firstDateInterval

            let effectiveBars = Double(Double(data.count) * 1.2)

            effectiveWidth = range / effectiveBars
        }

        var viewEntries = [BarChartDataEntry]()
        var visitorEntries = [BarChartDataEntry]()
        for datum in data {
            let dateInterval = datum.date.timeIntervalSince1970
            let offset = dateInterval - firstDateInterval

            let x = offset

            let viewY = Double(datum.viewCount)
            let viewEntry = BarChartDataEntry(x: x, y: viewY)
            viewEntries.append(viewEntry)

            let visitorY = Double(datum.visitorCount)
            let visitorEntry = BarChartDataEntry(x: x, y: visitorY)
            visitorEntries.append(visitorEntry)
        }

        let viewsDataSet = BarChartDataSet(values: viewEntries)
        let visitorsDataSet = BarChartDataSet(values: visitorEntries)
        let dataSets = [ viewsDataSet, visitorsDataSet ]

        let chartData = BarChartData(dataSets: dataSets)
        chartData.barWidth = effectiveWidth

        return chartData
    }
}
