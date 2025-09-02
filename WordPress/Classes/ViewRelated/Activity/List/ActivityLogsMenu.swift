import SwiftUI
import WordPressKit
import WordPressShared

struct ActivityLogsFiltersMenu: View {
    @ObservedObject var viewModel: ActivityLogsViewModel

    @State private var isShowingActivityTypePicker = false
    @State private var isShowingStartDatePicker = false
    @State private var isShowingEndDatePicker = false

    var body: some View {
        Menu {
            Section {
                dateFilters
                if !viewModel.isBackupMode {
                    activityTypeFilter
                }
                if !viewModel.parameters.isEmpty {
                    resetFiltersButton
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
        }
        .sheet(isPresented: $isShowingActivityTypePicker) {
            NavigationView {
                ActivityTypeSelectionView(viewModel: viewModel)
            }
        }
        .sheet(isPresented: $isShowingStartDatePicker) {
            DatePickerSheet(
                title: Strings.startDate,
                selection: $viewModel.parameters.startDate,
                isPresented: $isShowingStartDatePicker,
                viewModel: viewModel
            )
        }
        .sheet(isPresented: $isShowingEndDatePicker) {
            DatePickerSheet(
                title: Strings.endDate,
                selection: $viewModel.parameters.endDate,
                isPresented: $isShowingEndDatePicker,
                viewModel: viewModel
            )
        }
    }

    private var dateFilters: some View {
        Group {
            // Start Date
            Button {
                // Track analytics for date filter tap
                WPAnalytics.track(.activitylogFilterbarRangeButtonTapped)
                isShowingStartDatePicker = true
            } label: {
                Text(Strings.startDate)
                if let date = viewModel.parameters.startDate {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                }
                Image(systemName: "calendar")
            }

            // End Date
            Button {
                // Track analytics for date filter tap
                WPAnalytics.track(.activitylogFilterbarRangeButtonTapped)
                isShowingEndDatePicker = true
            } label: {
                Text(Strings.endDate)
                if let date = viewModel.parameters.endDate {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                }
                Image(systemName: "calendar")
            }
        }
    }

    private var activityTypeFilter: some View {
        Button {
            WPAnalytics.track(.activitylogFilterbarTypeButtonTapped)
            isShowingActivityTypePicker = true
        } label: {
            Text(Strings.activityTypes)
            if !viewModel.parameters.activityTypes.isEmpty {
                Text("\(viewModel.parameters.activityTypes.count)")
            }
            Image(systemName: "list.bullet")
        }
    }

    private var resetFiltersButton: some View {
        Button(role: .destructive) {
            WPAnalytics.track(.activitylogFilterbarResetRange)
            WPAnalytics.track(.activitylogFilterbarResetType)
            viewModel.parameters = GetActivityLogsParameters()
        } label: {
            Label(Strings.resetFilters, systemImage: "arrow.counterclockwise")
        }
    }
}

private struct DatePickerSheet: View {
    let title: String
    @Binding var selection: Date?
    @Binding var isPresented: Bool
    var viewModel: ActivityLogsViewModel?

    @State private var date = Date()

    var body: some View {
        NavigationView {
            picker
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .onAppear {
            date = selection ?? Date()
        }
    }

    private var picker: some View {
        DatePicker(title, selection: $date, displayedComponents: [.date, .hourAndMinute])
            .datePickerStyle(.graphical)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(SharedStrings.Button.done) {
                        selection = date
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive) {
                        selection = nil
                        isPresented = false
                    } label: {
                        Text(SharedStrings.Button.clear)
                    }
                }
            }
    }
}

private enum Strings {
    static let startDate = NSLocalizedString("activityLogs.filter.startDate", value: "Start Date", comment: "Start date filter label")
    static let endDate = NSLocalizedString("activityLogs.filter.endDate", value: "End Date", comment: "End date filter label")
    static let activityTypes = NSLocalizedString("activityLogs.filter.activityTypes", value: "Activity Types", comment: "Activity types filter label")
    static let resetFilters = NSLocalizedString("activityLogs.filter.reset", value: "Reset Filters", comment: "Reset filters button label")
}
