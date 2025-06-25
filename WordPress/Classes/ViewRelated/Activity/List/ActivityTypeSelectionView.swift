import SwiftUI
import WordPressKit
import WordPressUI

struct ActivityTypeSelectionView: View {
    @ObservedObject var viewModel: ActivityLogsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTypes: Set<String> = []
    @State private var availableActivityGroups: [WordPressKit.ActivityGroup] = []
    @State private var isLoading = false
    @State private var error: Error?

    init(viewModel: ActivityLogsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            if isLoading && availableActivityGroups.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error, availableActivityGroups.isEmpty {
                EmptyStateView.failure(error: error) {
                    Task { await fetchActivityGroups() }
                }
            } else if availableActivityGroups.isEmpty {
                EmptyStateView(
                    Strings.emptyActivityTypes,
                    systemImage: "list.bullet"
                )
            } else {
                List {
                    Section {
                        selectionControlsSection
                    }
                    Section {
                        activityTypesSection
                    }
                }
            }
        }
        .onAppear {
            selectedTypes = viewModel.parameters.activityTypes
        }
        .task {
            await fetchActivityGroups()
        }
        .navigationTitle(Strings.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                cancelButton
            }
            ToolbarItem(placement: .confirmationAction) {
                doneButton
            }
        }
    }

    // MARK: - View Components

    private var selectionControlsSection: some View {
        HStack {
            Button(Strings.selectAll) {
                selectedTypes = Set(availableActivityGroups.map { $0.key })
            }
            .disabled(selectedTypes.count == availableActivityGroups.count)

            Spacer()

            Button(Strings.deselectAll) {
                selectedTypes.removeAll()
            }
            .disabled(selectedTypes.isEmpty)
        }
        .font(.subheadline)
    }

    private var activityTypesSection: some View {
        ForEach(availableActivityGroups, id: \.key) { group in
            ActivityTypeRow(
                group: group,
                isSelected: selectedTypes.contains(group.key),
                onToggle: { toggleSelection(for: group.key) }
            )
        }
    }

    private var cancelButton: some View {
        Button(SharedStrings.Button.cancel) {
            dismiss()
        }
    }

    private var doneButton: some View {
        Button(SharedStrings.Button.done) {
            viewModel.parameters.activityTypes = selectedTypes
            dismiss()
        }
        .fontWeight(.semibold)
    }

    // MARK: - Helper Methods

    private func toggleSelection(for key: String) {
        if selectedTypes.contains(key) {
            selectedTypes.remove(key)
        } else {
            selectedTypes.insert(key)
        }
    }

    private func fetchActivityGroups() async {
        isLoading = true
        error = nil

        do {
            let groups = try await viewModel.fetchActivityGroups(
                after: viewModel.parameters.startDate,
                before: viewModel.parameters.endDate
            )
            availableActivityGroups = groups
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }
}

// MARK: - Activity Type Row

private struct ActivityTypeRow: View {
    let group: WordPressKit.ActivityGroup
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                groupInfo
                Spacer()
                selectionIndicator
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var groupInfo: some View {
        HStack {
            Text(group.name)
            Spacer()
            Text("\(group.count)")
                .foregroundColor(.secondary)
        }
    }

    private var selectionIndicator: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .foregroundColor(isSelected ? .accentColor : Color(.separator))
            .imageScale(.large)
    }
}

private enum Strings {
    static let title = NSLocalizedString("activityLogs.activityTypes.title", value: "Activity Types", comment: "Activity type selection screen title")
    static let selectAll = NSLocalizedString("activityLogs.activityTypes.selectAll", value: "Select All", comment: "Select all button")
    static let deselectAll = NSLocalizedString("activityLogs.activityTypes.deselectAll", value: "Deselect All", comment: "Deselect all button")
    static let emptyActivityTypes = NSLocalizedString("activityLogs.activityTypes.empty", value: "No activity types available", comment: "Empty state message when no activity types are available")
}
