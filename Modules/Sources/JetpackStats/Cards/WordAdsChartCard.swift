import SwiftUI

/// A chart card for displaying WordAds metrics with granularity selection and period navigation.
struct WordAdsChartCard: View {
    @ObservedObject var viewModel: WordAdsChartCardViewModel

    @ScaledMetric(relativeTo: .body) private var chartHeight: CGFloat = 180

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, Constants.step3)
                .padding(.top, Constants.step2)
                .padding(.bottom, Constants.step1)

            chartArea
                .frame(height: chartHeight)
                .padding(.horizontal, Constants.step2)
                .padding(.vertical, Constants.step2)
                .animation(.spring, value: viewModel.selectedMetric)
                .animation(.easeInOut, value: viewModel.isLoading)

            Divider()

            footer
        }
        .onAppear {
            viewModel.onAppear()
        }
        .cardStyle()
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 0) {
            StatsCardTitleView(title: viewModel.formattedCurrentDate)

            Spacer(minLength: 8)

            granularityMenu
        }
    }

    private var granularityMenu: some View {
        Menu {
            ForEach(DateRangeGranularity.allCases.filter { $0 != .hour }) { granularity in
                Button {
                    viewModel.onGranularityChanged(granularity)
                } label: {
                    Text(granularity.localizedTitle)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.selectedGranularity.localizedTitle)
                    .font(.subheadline.weight(.medium))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(Color.primary)
        }
        .accessibilityLabel(Strings.Chart.granularity)
    }

    // MARK: - Chart Area

    @ViewBuilder
    private var chartArea: some View {
        if viewModel.isFirstLoad {
            loadingView
        } else if let data = viewModel.currentChartData {
            if data.isEmpty {
                loadingErrorView(with: Strings.Chart.empty)
            } else {
                chartView(data: data)
                    .opacity(viewModel.isLoading ? 0.3 : 1.0)
                    .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        } else {
            loadingErrorView(with: viewModel.loadingError?.localizedDescription ?? Strings.Errors.generic)
        }
    }

    private var loadingView: some View {
        mockChartView
            .opacity(0.2)
            .pulsating()
    }

    private func loadingErrorView(with message: String) -> some View {
        mockChartView
            .grayscale(1)
            .opacity(0.1)
            .overlay {
                SimpleErrorView(message: message)
            }
    }

    private var mockChartView: some View {
        SimpleBarChartView(
            data: SimpleChartData.mock(
                metric: viewModel.selectedMetric,
                granularity: viewModel.selectedGranularity,
                dataPointCount: viewModel.selectedGranularity.preferredQuantity
            ),
            selectedDate: nil,
            onBarTapped: { _ in }
        )
        .redacted(reason: .placeholder)
    }

    private func chartView(data: SimpleChartData) -> some View {
        SimpleBarChartView(
            data: data,
            selectedDate: viewModel.selectedBarDate,
            onBarTapped: { date in
                viewModel.onBarTapped(date)
            }
        )
    }

    // MARK: - Footer

    private var footer: some View {
        MetricsOverviewTabView(
            data: viewModel.isFirstLoad ? viewModel.placeholderTabViewData : viewModel.tabViewData,
            selectedMetric: $viewModel.selectedMetric,
            onMetricSelected: { metric in
                viewModel.onMetricSelected(metric)
            },
            showTrend: false
        )
        .redacted(reason: viewModel.isLoading ? .placeholder : [])
        .pulsating(viewModel.isLoading)
        .background(
            CardGradientBackground(metric: viewModel.selectedMetric)
        )
        .animation(.easeInOut, value: viewModel.selectedMetric)
    }
}

// MARK: - Supporting Views

private struct CardGradientBackground: View {
    let metric: WordAdsMetric

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        LinearGradient(
            colors: [
                metric.primaryColor.opacity(colorScheme == .light ? 0.03 : 0.04),
                Constants.Colors.secondaryBackground
            ],
            startPoint: .top,
            endPoint: .center
        )
    }
}

// MARK: - Preview

#Preview {
    WordAdsChartCard(
        viewModel: WordAdsChartCardViewModel(service: MockStatsService())
    )
    .padding()
    .background(Constants.Colors.background)
}
