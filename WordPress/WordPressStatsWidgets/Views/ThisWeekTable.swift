import SwiftUI
import WidgetKit

struct ThisWeekTable: View {
    static let sampleContent: [ThisWeekWidgetDay] = [ThisWeekWidgetDay(date: Date(), viewsCount: 130, dailyChangePercent: -0.22), ThisWeekWidgetDay(date: Date(timeIntervalSinceNow: 86400), viewsCount: 250, dailyChangePercent: -0.06), ThisWeekWidgetDay(date: Date(timeIntervalSinceNow: 172800), viewsCount: 260, dailyChangePercent: 0.86)]

    var body: some View {
        VStack {
            FlexibleCard(axis: .horizontal, title: "This Week", value: .description("Around the world with Pam"))
                .padding(.bottom, 12)
            ForEach(Array(Self.sampleContent.enumerated()), id: \.element) { index, sample in
                ThisWeekRow(day: sample)
                if index != Self.sampleContent.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
    }
}

extension ThisWeekWidgetDay: Identifiable {

    var id: UUID {
        UUID()
    }
}

struct ThisWeekContentView_Previews: PreviewProvider {
    static var previews: some View {
        ThisWeekTable()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}


