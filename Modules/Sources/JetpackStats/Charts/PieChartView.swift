import SwiftUI
import Charts

struct PieChartView: View {
    let data: PieChartData

    @Environment(\.colorScheme) var colorScheme

    private var valueFormatter: StatsValueFormatter {
        StatsValueFormatter(metric: data.metric)
    }

    var body: some View {
        VStack(spacing: 0) {
            Chart(data.segments) { segment in
                SectorMark(
                    angle: .value("Value", segment.value),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.5
                )
                .foregroundStyle(color(for: segment))
                .cornerRadius(5)
                .annotation(position: .overlay) {
                    if shouldShowAnnotation(for: segment) {
                        Text("\(segment.name.capitalized) \((segment.percentage / 100).formatted(.percent.precision(.fractionLength(1))))")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.black.opacity(0.7))
                            )
                            .dynamicTypeSize(...DynamicTypeSize.large)
                    }
                }
            }
            .chartLegend(.hidden)
        }
    }

    private func color(for segment: PieChartData.Segment) -> Color {
        // Use light secondary color for "Other" segment
        if segment.isOther {
            return Color.secondary.opacity(0.2)
        }

        guard let index = data.segments.firstIndex(where: { $0.id == segment.id }) else {
            return data.metric.primaryColor
        }

        let baseColor = data.metric.primaryColor
        let variations: [Double] = [0.0, 0.2, 0.4, 0.6, 0.8, 0.9]
        let adjustmentIndex = index % variations.count
        let adjustment = variations[adjustmentIndex]

        if colorScheme == .light {
            return baseColor.opacity(1.0 - adjustment)
        } else {
            // In dark mode, mix with white to create lighter variants
            if #available(iOS 18, *) {
                return baseColor.mix(with: .white, by: adjustment)
            } else {
                return baseColor.opacity(1.0 - (adjustment * 0.5))
            }
        }
    }

    private func shouldShowAnnotation(for segment: PieChartData.Segment) -> Bool {
        // Never show annotation for "Other" segment
        guard !segment.isOther else { return false }

        // Show annotation for top 3 segments
        guard let index = data.segments.firstIndex(where: { $0.id == segment.id }) else {
            return false
        }

        return index < 3 && segment.percentage > 5.0
    }
}

#Preview {
    let mockItems: [TopListItem.Device] = [
        TopListItem.Device(name: "mobile", breakdown: .screensize, metrics: SiteMetricsSet(views: 738)),
        TopListItem.Device(name: "desktop", breakdown: .screensize, metrics: SiteMetricsSet(views: 258)),
        TopListItem.Device(name: "tablet", breakdown: .screensize, metrics: SiteMetricsSet(views: 4))
    ]

    let pieChartData = PieChartData(items: mockItems, metric: .views)

    return VStack {
        PieChartView(data: pieChartData)
            .frame(height: 200)
            .padding()
    }
}
