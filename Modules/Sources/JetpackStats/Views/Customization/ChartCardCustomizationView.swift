import SwiftUI

struct ChartCardCustomizationView: View {
    let chartViewModel: ChartCardViewModel

    @State private var selectedMetrics: Set<SiteMetric> = []
    @State private var metrics: [SiteMetric] = []
    @State private var editMode: EditMode = .active

    @ScaledMetric private var iconWidth = 26

    @Environment(\.context) var context
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            ForEach(metrics, id: \.self) { metric in
                metricRow(metric: metric)
            }
            .onMove { from, to in
                metrics.move(fromOffsets: from, toOffset: to)
            }

            // Reset Settings button at the bottom
            Section {
                Button(action: resetToDefaults) {
                    Text(Strings.Buttons.resetSettings)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)

                }
                .padding(.top, 12)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(Strings.Buttons.cancel) {
                    chartViewModel.isEditing = false
                    dismiss()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                if !selectedMetrics.isEmpty {
                    Button(Strings.Buttons.done) {
                        // Convert selected metrics to array in the order they appear in metrics
                        let orderedSelectedMetrics = metrics.filter { selectedMetrics.contains($0) }

                            // Update existing chart configuration
                        var updatedConfig = chartViewModel.configuration
                        updatedConfig.metrics = orderedSelectedMetrics
                        chartViewModel.updateConfiguration(updatedConfig)
                        chartViewModel.isEditing = false

                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            metrics = context.service.supportedMetrics

            // If editing existing chart, pre-select its current metrics
            selectedMetrics = Set(chartViewModel.metrics)

            // Reorder metrics to put selected ones first in their current order
            let currentMetrics = chartViewModel.metrics
            let otherMetrics = metrics.filter { !currentMetrics.contains($0) }
            metrics = currentMetrics + otherMetrics
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
        .listRowBackground(Color.clear)
    }

    private func resetToDefaults() {
        // Get default metrics from service (excluding downloads)
        let defaultMetrics = context.service.supportedMetrics.filter { $0 != .downloads }

        // Update selected metrics
        selectedMetrics = Set(defaultMetrics)

        // Update the metrics array order to show default metrics first
        let otherMetrics = metrics.filter { !defaultMetrics.contains($0) }
        metrics = defaultMetrics + otherMetrics
    }
}
