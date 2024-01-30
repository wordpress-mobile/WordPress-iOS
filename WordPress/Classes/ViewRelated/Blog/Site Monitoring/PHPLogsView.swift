import SwiftUI
import WordPressKit

struct PHPLogsView: View {
    @StateObject var viewModel: PHPLogsViewModel
    @State private var searchCriteria = PHPLogsSearchCriteria(startDate: Date.oneWeekAgo)

    var body: some View {
        VStack {
            filterBar
            Spacer()
            main
            Spacer()
        }
        .onAppear(perform: {
            loadLogs(searchCriteria: searchCriteria)
        })
        .onChange(of: searchCriteria) { value in
            loadLogs(searchCriteria: value, reset: true)
        }
    }

    @ViewBuilder
    private var main: some View {
        if viewModel.loadedLogs.isEmpty {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.error != nil {
                Text("Error")
            } else {
                Text("No results")
            }
        } else {
            List {
                Section {
                    ForEach(viewModel.loadedLogs) { entry in
                        makeRow(for: entry)
                    }
                    if viewModel.hasMore {
                        footerRow
                    }
                }
                .listSectionSeparator(.hidden, edges: .bottom)
            }
            .listStyle(.plain)
        }
    }

    private var filterBar: some View {
        FilterCompactBar {
            FilterCompactDatePicker(
                Strings.filterStartDate,
                selection: $searchCriteria.startDate,
                in: Date.distantPast...(searchCriteria.endDate ?? Date.now)
            )
            FilterCompactDatePicker(
                Strings.filterEndDate,
                selection: $searchCriteria.endDate,
                in: (searchCriteria.startDate ?? Date.distantPast)...Date.now
            )
            FilterCompactButton(Strings.filterSeverity, selection: $searchCriteria.severity) {
                Picker("", selection: $searchCriteria.severity) {
                    let cases = [AtomicErrorLogEntry.Severity.user, .warning, .deprecated, .fatalError]
                    ForEach(cases, id: \.self) {
                        Text($0.localizedTitle).tag(Optional.some($0))
                    }
                }.pickerStyle(.inline)
            } label: {
                Text($0.localizedTitle)
            }
            .contentPresentationStyle(.menu)
        }
    }

    private var footerRow: some View {
        VStack(alignment: .center) {
            if viewModel.isLoading {
                PagingFooterWrapperView(state: .loading)
            } else if viewModel.error != nil {
                PagingFooterWrapperView(state: .error)
            } else {
                EmptyView()
            }
        }
        .frame(height: 50)
        .onAppear {
            loadLogs(searchCriteria: searchCriteria)
        }
    }

    private func makeRow(for entry: AtomicErrorLogEntry) -> some View {
        NavigationLink(destination: { EmptyView() }) {
            VStack(alignment: .leading) {
                HStack {
                    Text(entry.severity ?? "")
                        .font(.system(size: 12, design: .monospaced))
                        .textCase(.uppercase)
                        .padding(4)
                        .background(Color.yellow.opacity(0.33))
                        .cornerRadius(4)
                    Spacer()
                    Text((entry.timestamp?.mediumStringWithTime()) ?? "")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Text(entry.message ?? "")
                    .font(.system(size: 15))
                    .lineLimit(3)
            }
        }
    }

    private func loadLogs(searchCriteria: PHPLogsSearchCriteria, reset: Bool = false) {
        Task {
            await viewModel.loadLogs(searchCriteria: searchCriteria, reset: reset)
        }
    }
}

@MainActor
final class PHPLogsViewModel: ObservableObject {
    private let blog: Blog
    private let atomicSiteService: AtomicSiteService

    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var loadedLogs: [AtomicErrorLogEntry] = []
    @Published private(set) var hasMore = true

    private var scrollId: String?

    init(blog: Blog, atomicSiteService: AtomicSiteService) {
        self.blog = blog
        self.atomicSiteService = atomicSiteService
    }

    /// Loads the next page. Does nothing if it's already loading or has no more items to load.
    func loadLogs(searchCriteria: PHPLogsSearchCriteria, reset: Bool = false) async {
        guard let siteID = blog.dotComID?.intValue else {
            return // Should never happen
        }

        if reset {
            loadedLogs = []
            hasMore = true
        }

        guard !isLoading && hasMore else {
            return
        }
        isLoading = true
        error = nil

        do {
            let response = try await atomicSiteService.errorLogs(
                siteID: siteID,
                range: (searchCriteria.startDate ?? Date.oneWeekAgo)..<(searchCriteria.endDate ?? Date.now),
                severity: searchCriteria.severity,
                scrollID: scrollId
            )
            isLoading = false
            scrollId = response.scrollId
            loadedLogs += response.logs
            hasMore = response.totalResults > loadedLogs.count
        } catch {
            isLoading = false
            self.error = error
        }
    }
}

extension AtomicErrorLogEntry: Identifiable {}

struct PHPLogsSearchCriteria: Equatable {
    var startDate: Date?
    var endDate: Date?
    var severity: AtomicErrorLogEntry.Severity?
}

extension AtomicErrorLogEntry.Severity {
    var localizedTitle: String {
        switch self {
        case .user: NSLocalizedString("phpLogs.severityUser", value: "User", comment: "A title for the log severity level")
        case .warning: NSLocalizedString("phpLogs.severityWarning", value: "Warning", comment: "A title for the log severity level")
        case .deprecated: NSLocalizedString("phpLogs.severityDeprecated", value: "Deprecated", comment: "A title for the log severity level")
        case .fatalError: NSLocalizedString("phpLogs.severityFatalError", value: "Fatal Error", comment: "A title for the log severity level")
        }
    }
}

private enum Strings {
    static let filterStartDate = NSLocalizedString("phpLogs.filterStartDate", value: "Start Date", comment: "A title for the filter on the PHP logs screen")
    static let filterEndDate = NSLocalizedString("phpLogs.filterEndDate", value: "End Date", comment: "A title for the filter on the PHP logs screen")
    static let filterSeverity = NSLocalizedString("phpLogs.filterSeverity", value: "Severity", comment: "A title for the filter on the PHP logs screen")
}
