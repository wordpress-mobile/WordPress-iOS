import SwiftUI
import WordPressUI
import WordPressKit

struct TimeZoneSelectorView: View {
    @StateObject private var viewModel = TimeZoneSelectorViewModel()
    @State private var searchText = ""
    private var selectedValue: String?
    @Environment(\.dismiss) private var dismiss

    let onSelection: (WPTimeZone) -> Void

    init(selectedValue: String?, onSelection: @escaping (WPTimeZone) -> Void) {
        self.onSelection = onSelection
        self.selectedValue = selectedValue
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
        if let rowViewModel = viewModel.suggestedTimezoneRowViewModel {
            Section(Strings.suggested) {
                timeZoneRow(for: rowViewModel)
            }
        }
    }

    @ViewBuilder
    private func timeZoneSections(_ sections: [TimeZoneSectionViewModel]) -> some View {
        ForEach(sections) { section in
            Section(section.name) {
                ForEach(section.timezones) { rowViewModel in
                    timeZoneRow(for: rowViewModel)
                }
            }
        }
    }

    @ViewBuilder
    private func timeZoneRow(for viewModel: TimeZoneRowViewModel) -> some View {
        TimeZoneRowView(
            viewModel: viewModel,
            isSelected: viewModel.timezone.value == selectedValue
        ) {
            handleSelection(viewModel.timezone)
        }
    }

    private func handleSelection(_ timezone: WPTimeZone) {
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

    static let suggested = NSLocalizedString(
        "timeZoneSelector.suggested",
        value: "Suggested",
        comment: "Section title for suggested timezones"
    )
}
