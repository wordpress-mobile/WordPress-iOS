import SwiftUI
@preconcurrency import WordPressKit

struct WordAdsPaymentHistoryView: View {
    let earnings: StatsWordAdsEarningsResponse

    @Environment(\.context) private var context

    var body: some View {
        List {
            ForEach(groupedEarningsByYear, id: \.year) { group in
                Section(header: Text(String(group.year))) {
                    ForEach(group.earnings, id: \.period) { earning in
                        WordAdsPaymentHistoryRowView(viewModel: WordAdsPaymentHistoryRowViewModel(earning: earning))
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var groupedEarningsByYear: [YearGroup] {
        let grouped = Dictionary(grouping: earnings.wordAdsEarnings) { $0.period.year }
        return grouped.map { YearGroup(year: $0.key, earnings: $0.value) }
            .sorted { $0.year > $1.year }
    }

    private struct YearGroup {
        let year: Int
        let earnings: [StatsWordAdsEarningsResponse.MonthlyEarning]
    }
}

#Preview {
    let json = """
    {
        "ID": 123456,
        "name": "Test Site",
        "URL": "https://test.com",
        "earnings": {
            "total_earnings": "150.00",
            "total_amount_owed": "120.00",
            "wordads": {
                "2025-12": {"amount": 25.50, "status": "0", "pageviews": "4500"},
                "2025-11": {"amount": 20.30, "status": "0", "pageviews": "3800"},
                "2025-10": {"amount": 18.75, "status": "1", "pageviews": "3200"},
                "2025-09": {"amount": 15.20, "status": "1", "pageviews": "2900"},
                "2025-08": {"amount": 12.80, "status": "1", "pageviews": "2500"},
                "2025-07": {"amount": 11.50, "status": "1", "pageviews": "2300"},
                "2024-12": {"amount": 10.20, "status": "1", "pageviews": "2100"},
                "2024-11": {"amount": 9.80, "status": "1", "pageviews": "1900"},
                "2024-10": {"amount": 8.50, "status": "1", "pageviews": "1700"},
                "2024-09": {"amount": 7.20, "status": "1", "pageviews": "1500"}
            }
        }
    }
    """
    let earnings = try! JSONDecoder().decode(StatsWordAdsEarningsResponse.self, from: json.data(using: .utf8)!)

    return NavigationStack {
        WordAdsPaymentHistoryView(earnings: earnings)
            .navigationTitle(Strings.WordAds.paymentsHistory)
            .navigationBarTitleDisplayMode(.inline)
    }
    .environment(\.context, .demo)
}
