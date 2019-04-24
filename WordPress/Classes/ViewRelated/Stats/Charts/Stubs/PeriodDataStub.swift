
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

// MARK: - ViewsPeriodDataStub

class ViewsPeriodDataStub: PeriodDataStub {}

extension ViewsPeriodDataStub: BarChartDataConvertible {
    var accessibilityDescription: String {
        return "Bar Chart depicting Views for selected period, Visitors superimposed"   // NB: we don't localize stub data
    }

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

// MARK: - VisitorsPeriodDataStub

class VisitorsPeriodDataStub: PeriodDataStub {}

extension VisitorsPeriodDataStub: BarChartDataConvertible {
    var accessibilityDescription: String {
        return "Bar Chart depicting Visitors for selected period"   // NB: we don't localize stub data
    }

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

        var entries = [BarChartDataEntry]()
        for datum in data {
            let dateInterval = datum.date.timeIntervalSince1970
            let offset = dateInterval - firstDateInterval

            let x = offset
            let y = Double(datum.visitorCount)
            let entry = BarChartDataEntry(x: x, y: y)
            entries.append(entry)
        }

        let chartData = BarChartData(entries: entries)
        chartData.barWidth = effectiveWidth

        return chartData
    }
}

// MARK: - LikesPeriodDataStub

class LikesPeriodDataStub: PeriodDataStub {}

extension LikesPeriodDataStub: BarChartDataConvertible {
    var accessibilityDescription: String {
        return "Bar Chart depicting Likes for selected period"   // NB: we don't localize stub data
    }

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

        var entries = [BarChartDataEntry]()
        for datum in data {
            let dateInterval = datum.date.timeIntervalSince1970
            let offset = dateInterval - firstDateInterval

            let x = offset
            let y = Double(datum.likeCount)
            let entry = BarChartDataEntry(x: x, y: y)
            entries.append(entry)
        }

        let chartData = BarChartData(entries: entries)
        chartData.barWidth = effectiveWidth

        return chartData
    }
}

// MARK: - CommentsPeriodDataStub

class CommentsPeriodDataStub: PeriodDataStub {}

extension CommentsPeriodDataStub: BarChartDataConvertible {
    var accessibilityDescription: String {
        return "Bar Chart depicting Comments for selected period"   // NB: we don't localize stub data
    }

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

        var entries = [BarChartDataEntry]()
        for datum in data {
            let dateInterval = datum.date.timeIntervalSince1970
            let offset = dateInterval - firstDateInterval

            let x = offset
            let y = Double(datum.commentCount)
            let entry = BarChartDataEntry(x: x, y: y)
            entries.append(entry)
        }

        let chartData = BarChartData(entries: entries)
        chartData.barWidth = effectiveWidth

        return chartData
    }
}
