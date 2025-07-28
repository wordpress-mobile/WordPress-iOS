import SwiftUI

struct ChartCardCustomizationView: View {
    @ObservedObject var viewModel: StatsViewModel

    @State private var selectedMetrics: Set<SiteMetric> = []
    @State private var metrics: [SiteMetric] = []
    @State private var editMode: EditMode = .active

    @ScaledMetric private var iconWidth = 26

    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            ForEach(metrics, id: \.self) { metric in
                metricRow(metric: metric)
            }
            .onMove { from, to in
                metrics.move(fromOffsets: from, toOffset: to)
            }
        }
        .listStyle(.plain)
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !selectedMetrics.isEmpty {
                    Button(Strings.Buttons.done) {
                        // Convert selected metrics to array in the order they appear in metrics
                        let orderedSelectedMetrics = metrics.filter { selectedMetrics.contains($0) }
                        viewModel.addChartWithMetrics(orderedSelectedMetrics)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            metrics = viewModel.context.service.supportedMetrics
        }
    }
    
    private func metricRow(metric: SiteMetric) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if selectedMetrics.contains(metric) {
                    selectedMetrics.remove(metric)
                } else {
                    selectedMetrics.insert(metric)
                }
            }
        }) {
            HStack(spacing: Constants.step0_5) {
                Image(systemName: selectedMetrics.contains(metric) ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(selectedMetrics.contains(metric) ? .accentColor : Color(.tertiaryLabel))
                    .padding(.trailing, 8)

                Image(systemName: metric.systemImage)
                    .font(.subheadline)
                    .frame(width: iconWidth)

                Text(metric.localizedTitle)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Chart Customization") {
    struct PreviewWrapper: View {
        @State private var isPresented = true
        
        var body: some View {
            Color.clear
                .sheet(isPresented: $isPresented) {
                    NavigationStack {
                        ChartCardCustomizationView(
                            viewModel: StatsViewModel(
                                context: .demo,
                                initialDateRange: Calendar.demo.makeDateRange(for: .today)
                            )
                        )
                        .navigationTitle(Strings.AddChart.selectMetric)
                        .navigationBarTitleDisplayMode(.inline)
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
        }
    }
    
    return PreviewWrapper()
        .environment(\.context, .demo)
}

#Preview("Chart Customization - Direct") {
    NavigationStack {
        ChartCardCustomizationView(
            viewModel: StatsViewModel(
                context: .demo,
                initialDateRange: Calendar.demo.makeDateRange(for: .today)
            )
        )
        .navigationTitle(Strings.AddChart.selectMetric)
        .navigationBarTitleDisplayMode(.inline)
    }
    .environment(\.context, .demo)
}
