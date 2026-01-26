import Foundation
@preconcurrency import WordPressKit

struct WordAdsPaymentHistoryRowViewModel {
    let earning: StatsWordAdsEarningsResponse.MonthlyEarning

    var formattedPeriod: String {
        var components = DateComponents()
        components.year = earning.period.year
        components.month = earning.period.month
        components.day = 1

        guard let date = Calendar.current.date(from: components) else {
            return earning.period.string
        }

        return date.formatted(.dateTime.month(.abbreviated).year())
    }

    var formattedAmount: String {
        earning.amount.formatted(.currency(code: "USD"))
    }

    var formattedAdsServed: String {
        Strings.WordAds.adsServed(earning.pageviews)
    }

    var statusText: String {
        earning.status == .paid ? Strings.WordAds.paid : Strings.WordAds.outstanding
    }
}
