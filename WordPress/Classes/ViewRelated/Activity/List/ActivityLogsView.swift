import SwiftUI
import WordPressUI
import WordPressKit
import WordPressShared

struct ActivityLogsView: View {
    @ObservedObject var viewModel: ActivityLogsViewModel

    var body: some View {
        let content = Group {
            if !viewModel.searchText.isEmpty {
                ActivityLogsSearchView(viewModel: viewModel)
            } else {
                ActivityLogsListView(viewModel: viewModel)
            }
        }
        .navigationTitle(viewModel.isBackupMode ? Strings.backupsTitle : Strings.activityTitle)

        if viewModel.isBackupMode {
            content
        } else {
            content.searchable(text: $viewModel.searchText)
        }
    }
}

private struct ActivityLogsListView: View {
    @ObservedObject var viewModel: ActivityLogsViewModel

    var body: some View {
        List {
            if let backupTracker = viewModel.backupTracker {
                DownloadableBackupSection(backupTracker: backupTracker)
            }

            if let response = viewModel.response {
                ActivityLogsPaginatedForEach(response: response, blog: viewModel.blog)

                if viewModel.isFreePlan {
                    Text(Strings.freePlanNotice)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .accessibilityIdentifier("activity_logs_list")
        .overlay {
            if let response = viewModel.response {
                if response.isEmpty {
                    EmptyStateView(
                        viewModel.isBackupMode ? Strings.emptyBackups : Strings.empty,
                        systemImage: "archivebox",
                        description: viewModel.isBackupMode ? Strings.emptyBackupsSubtitle : nil
                    )
                }
            } else if viewModel.isLoading {
                ProgressView()
            } else if let error = viewModel.error {
                EmptyStateView.failure(error: error) {
                    Task { await viewModel.refresh() }
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ActivityLogsFiltersMenu(viewModel: viewModel)
            }
        }
    }
}

private struct ActivityLogsSearchView: View {
    @ObservedObject var viewModel: ActivityLogsViewModel

    var body: some View {
        DataViewSearchView(
            searchText: viewModel.searchText,
            search: viewModel.search
        ) { response in
            ActivityLogsPaginatedForEach(response: response, blog: viewModel.blog)
        }
    }
}

private struct ActivityLogsPaginatedForEach: View {
    @ObservedObject var response: ActivityLogsPaginatedResponse
    let blog: Blog

    struct ActivityGroup: Identifiable {
        var id: Date { date }
        let date: Date
        var title: String { date.formatted(date: .long, time: .omitted) }
        let items: [ActivityLogRowViewModel]
    }

    private var groupedItems: [ActivityGroup] {
        let grouped = Dictionary(grouping: response.items) { item in
            Calendar.current.startOfDay(for: item.date)
        }
        return grouped.map { ActivityGroup(date: $0.key, items: $0.value) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        ForEach(groupedItems) { group in
            Section(group.title) {
                ForEach(group.items) {
                    makeRow(with: $0)
                        .listRowSeparator($0.id == group.items.first?.id ? .hidden : .automatic, edges: .top)
                }
            }
        }
        if response.isLoading {
            DataViewPagingFooterView(.loading)
        } else if response.error != nil {
            DataViewPagingFooterView(.failure)
                .onRetry { response.loadMore() }
        }
    }

    private func makeRow(with item: ActivityLogRowViewModel) -> some View {
        ActivityLogRowView(viewModel: item)
            .onAppear { response.onRowAppeared(item) }
            .background {
                // TODO: Switch to NavigationStack and Button on iOS 17
                NavigationLink {
                    ActivityLogDetailsView(activity: item.activity, blog: blog)
                } label: {
                    EmptyView()
                }.opacity(0)
            }
    }
}

private enum Strings {
    static let empty = NSLocalizedString("activityLogs.empty", value: "No Activity", comment: "Empty state message for activity logs")
    static let freePlanNotice = NSLocalizedString("activityLogs.freePlan.notice", value: "Since you're on a free plan, you'll see limited events in your Activity Log.", comment: "Notice shown to free plan users about limited activity log events")
    static let activityTitle = NSLocalizedString("activityLogs.title", value: "Activity", comment: "Title for activity logs screen")
    static let backupsTitle = NSLocalizedString("backups.title", value: "Backups", comment: "Title for backups screen")
    static let emptyBackups = NSLocalizedString("backups.empty.title", value: "Your first backup will be ready soon", comment: "Title for the view when there aren't any Backups to display")
    static let emptyBackupsSubtitle = NSLocalizedString("backups.empty.subtitle", value: "Your first backup will appear here within 24 hours and you will receive a notification once the backup has been completed", comment: "Text displayed in the view when there aren't any Backups to display")
}
