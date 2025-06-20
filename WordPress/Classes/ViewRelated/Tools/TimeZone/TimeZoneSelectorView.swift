import SwiftUI
import WordPressUI
import WordPressKit

struct TimeZoneSelectorView: View {
    @StateObject private var viewModel: TimeZoneSelectorViewModel
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    let onSelection: (WPTimeZone) -> Void

    init(selectedValue: String?, onSelection: @escaping (WPTimeZone) -> Void) {
        self.onSelection = onSelection
        self._viewModel = StateObject(wrappedValue: TimeZoneSelectorViewModel(selectedValue: selectedValue))
    }

    var body: some View {
        List {
            if !searchText.isEmpty {
                timeZoneSections(viewModel.filteredSections(searchText: searchText))
            } else {
                suggestionSection
                timeZoneSections(viewModel.sections)
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.sections.isEmpty {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.error {
                    EmptyStateView.failure(error: error) {
                        Task { await viewModel.loadTimezones() }
                    }
                }
            } else if !searchText.isEmpty && viewModel.filteredSections(searchText: searchText).isEmpty {
                EmptyStateView.search()
            }
        }
        .task {
            await viewModel.loadTimezones()
        }
    }

    @ViewBuilder
    private var suggestionSection: some View {
        if let timezone = viewModel.suggestedTimezone {
            Section {
                Button(action: {
                    handleSelection(timezone)
                }) {
                    HStack {
                        Text(Strings.suggestion)
                            .foregroundColor(.secondary)
                        Text(timezone.label)
                            .foregroundColor(.accentColor)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
            }
        }
    }

    @ViewBuilder
    private func timeZoneSections(_ sections: [TimeZoneSectionViewModel]) -> some View {
        ForEach(sections) { section in
            Section(section.name) {
                ForEach(section.timezones) { rowViewModel in
                    TimeZoneRowView(
                        viewModel: rowViewModel,
                        isSelected: rowViewModel.timezone.value == viewModel.selectedValue
                    ) {
                        handleSelection(rowViewModel.timezone)
                    }
                }
            }
        }
    }

    private func handleSelection(_ timezone: WPTimeZone) {
        viewModel.selectedValue = timezone.value
        onSelection(timezone)
        dismiss()
    }
}

private struct TimeZoneRowView: View {
    let viewModel: TimeZoneRowViewModel
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.timezone.label)
                    .foregroundColor(.primary)
                    .fontWeight(isSelected ? .bold : .regular)

                HStack {
                    Text(viewModel.offset)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(viewModel.currentTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
    }
}

private enum Strings {
    static let title = NSLocalizedString(
        "timeZoneSelector.title",
        value: "Time Zone",
        comment: "Title for the time zone selector"
    )

    static let suggestion = NSLocalizedString(
        "timeZoneSelector.suggestion",
        value: "Suggestion:",
        comment: "Label displayed to the user left of the time zone suggestion"
    )
}
