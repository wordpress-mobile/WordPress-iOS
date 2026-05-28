import SwiftUI

struct RealtimeMetricsCard: View {
    @State private var activeVisitors = 420
    @State private var visitorsLast30Min = 1280
    @State private var viewsLast30Min = 3720
    @State private var isPulsing = false

    @ScaledMetric(relativeTo: .caption) private var pulseCircleSize: CGFloat = 6

    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    Text("Realtime")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Circle()
                        .fill(Color.green)
                        .frame(width: pulseCircleSize, height: pulseCircleSize)
                        .scaleEffect(isPulsing ? 1.2 : 0.8)
                        .opacity(isPulsing ? 0.4 : 0.8)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isPulsing)
                        .padding(.leading, 8)

                    Spacer()
                }

                Text("Last 30 minutes")
                    .font(.subheadline.smallCaps()).fontWeight(.medium)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                realtimeStatRow(
                    systemImage: SiteMetric.views.systemImage,
                    label: SiteMetric.views.localizedTitle,
                    value: viewsLast30Min.formatted(.number.notation(.compactName))
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(SiteMetric.views.localizedTitle), \(viewsLast30Min.formatted())")

                realtimeStatRow(
                    systemImage: SiteMetric.visitors.systemImage,
                    label: SiteMetric.visitors.localizedTitle,
                    value: visitorsLast30Min.formatted(.number.notation(.compactName))
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(SiteMetric.visitors.localizedTitle), \(visitorsLast30Min.formatted())")

                realtimeStatRow(
                    systemImage: SiteMetric.visitors.systemImage,
                    label: Strings.SiteMetrics.visitorsNow,
                    value: activeVisitors.formatted(.number.notation(.compactName))
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Strings.Accessibility.visitorsNow(activeVisitors))
            }
        }
        .padding()
        .onAppear {
            isPulsing = true
        }
        .onReceive(timer) { _ in
            updateRealtimeStats()
        }
    }

    private func realtimeStatRow(systemImage: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)

                Text(label.uppercased())
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }

            Text(value)
                .contentTransition(.numericText())
                .animation(.spring, value: value)
                .font(Constants.Typography.mediumDisplayFont)
                .kerning(Constants.Typography.largeDisplayKerning)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func updateRealtimeStats() {
        withAnimation(.easeInOut(duration: 0.3)) {
            // Active visitors: typically 300-600 with small variations
            let activeVariation = Int.random(in: -30...30)
            activeVisitors = max(100, min(800, activeVisitors + activeVariation))

            // Visitors in last 30 min: typically 1000-2000, smoother changes
            let visitorVariation = Int.random(in: -50...80)
            visitorsLast30Min = max(500, min(3000, visitorsLast30Min + visitorVariation))

            // Views in last 30 min: typically 3000-5000, more volatile
            let viewsVariation = Int.random(in: -150...200)
            viewsLast30Min = max(1000, min(8000, viewsLast30Min + viewsVariation))

            // Occasionally simulate traffic spikes (5% chance)
            if Int.random(in: 1...20) == 1 {
                activeVisitors += Int.random(in: 50...150)
                visitorsLast30Min += Int.random(in: 200...400)
                viewsLast30Min += Int.random(in: 500...1000)
            }

            // Occasionally simulate traffic drops (5% chance)
            if Int.random(in: 1...20) == 20 {
                activeVisitors = max(100, activeVisitors - Int.random(in: 50...100))
                visitorsLast30Min = max(500, visitorsLast30Min - Int.random(in: 100...300))
                viewsLast30Min = max(1000, viewsLast30Min - Int.random(in: 300...600))
            }
        }
    }
}

#Preview {
    RealtimeMetricsCard()
        .padding()
        .background(Constants.Colors.background)
}
