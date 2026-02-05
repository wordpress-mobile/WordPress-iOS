import SwiftUI

struct CustomDateRangePicker: View {
    @Binding var dateRange: StatsDateRange
    @StateObject private var viewModel: CustomDateRangePickerViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.context) private var context

    init(dateRange: Binding<StatsDateRange>) {
        self._dateRange = dateRange
        self._viewModel = StateObject(wrappedValue: CustomDateRangePickerViewModel(
            dateRange: dateRange.wrappedValue,
            calendar: dateRange.wrappedValue.calendar
        ))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                contents
            }
            .background(Constants.Colors.background)
            .navigationTitle(Strings.DatePicker.customRange)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Buttons.cancel) { dismiss() }
                        .tint(Color.primary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Buttons.apply) { buttonApplyTapped() }
                        .fontWeight(.semibold)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(Color.primary)
                        .foregroundStyle(Color(.systemBackground))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var contents: some View {
        VStack(spacing: 16) {
            VStack(spacing: 16) {
                dateSelectionSection
                currentSelectionHeader
            }
            .padding()
            .cardStyle()
            .padding(.horizontal, Constants.step1)

            quickPeriodPicker
                .padding()
        }
        .padding(.top, 16)
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
    }

    // MARK: - Actions

    private func buttonApplyTapped() {
        dateRange = viewModel.createStatsDateRange()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Track custom date range selection
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        context.tracker?.send(.customDateRangeSelected, properties: [
            "start_date": dateFormatter.string(from: viewModel.startDate),
            "end_date": dateFormatter.string(from: viewModel.endDate)
        ])

        dismiss()
    }

    // MARK: - View Components

    private var currentSelectionHeader: some View {
        VStack(spacing: 5) {
            Text(viewModel.formattedDateCount)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .animation(.spring, value: viewModel.formattedDateCount)
            TimezoneInfoView()
        }
    }

    private var dateSelectionSection: some View {
        HStack(alignment: .bottom, spacing: 0) {
            datePickerColumn(label: Strings.DatePicker.from.uppercased(), selection: $viewModel.startDate, alignment: .leading)

            Spacer(minLength: 32)

            datePickerColumn(label: Strings.DatePicker.to.uppercased(), selection: $viewModel.endDate, alignment: .trailing)
        }
        .overlay(alignment: .bottom) {
            Image(systemName: "arrow.forward")
                .font(.headline.weight(.bold))
                .foregroundColor(.secondary)
                .padding(.bottom, 10)
        }
    }

    private func datePickerColumn(label: String, selection: Binding<Date>, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            DatePicker("", selection: selection, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
                .fixedSize()
                .environment(\.timeZone, context.timeZone)
        }
        .lineLimit(1)
    }

    // MARK: - Quick Periods

    struct QuickPeriod: Identifiable {
        var id: String { name }
        let name: String
        let action: () -> Void
        let datePreview: String
    }

    private var quickPeriods: [QuickPeriod] {
        return [
            makeQuickPeriod(named: Strings.Calendar.week, component: .weekOfYear),
            makeQuickPeriod(named: Strings.Calendar.month, component: .month),
            makeQuickPeriod(named: Strings.Calendar.quarter, component: .quarter),
            makeQuickPeriod(named: Strings.Calendar.year, component: .year),
        ].compactMap { $0 }
    }

    private func makeQuickPeriod(named name: String, component: Calendar.Component) -> QuickPeriod? {
        guard let interval = context.calendar.dateInterval(of: component, for: viewModel.startDate) else {
            return nil
        }
        return QuickPeriod(
            name: name,
            action: { viewModel.selectQuickPeriod(component) },
            datePreview: context.formatters.dateRange.string(from: interval)
        )
    }

    private var quickPeriodPicker: some View {
        VStack(spacing: 12) {
            Text(Strings.DatePicker.quickPeriodsForStartDate)
                .font(.footnote)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(quickPeriods) { period in
                    QuickPeriodButtonView(period: period)
                }
            }
        }
    }

}

private struct QuickPeriodButtonView: View {
    let period: CustomDateRangePicker.QuickPeriod

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            period.action()
        } label: {
            VStack(spacing: 4) {
                Text(period.name)
                    .font(.callout.weight(.medium))
                Text(period.datePreview)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .contentTransition(.numericText())
                    .animation(.spring, value: period.datePreview)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(Color(.tertiarySystemFill))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewContainer: View {
        @State private var showingPicker = true
        @State private var dateRange = Calendar.demo.makeDateRange(for: .today)

        var body: some View {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack {
                    Text("Main View")
                        .font(.largeTitle)

                    Button("Show Date Picker") {
                        showingPicker = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .sheet(isPresented: $showingPicker) {
                CustomDateRangePicker(dateRange: $dateRange)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    return PreviewContainer()
}
