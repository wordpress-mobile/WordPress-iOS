import SwiftUI
import WordPressKit
import UIKit

@available(iOS 16, *)
struct PHPLogsView: View {
    @StateObject var viewModel: PHPLogsViewModel
    @State private var searchCriteria = PHPLogsSearchCriteria(startDate: Date.oneWeekAgo)
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                filterBar
                Divider()
            }
            .background(colorScheme == .dark ? Color(uiColor: .secondarySystemBackground) : nil)
            main
        }
        .onAppear {
            loadLogs(searchCriteria: searchCriteria)
        }
        .onChange(of: searchCriteria) { value in
            loadLogs(searchCriteria: value, reset: true)
        }
    }

    @ViewBuilder
    private var main: some View {
        if viewModel.loadedLogs.isEmpty {
            VStack {
                Spacer()
                stateView
                Spacer()
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

    @ViewBuilder
    private var stateView: some View {
        if viewModel.isLoading {
            ProgressView()
        } else if viewModel.error != nil {
            NoAtomicLogsView(state: .error(reload))
        } else {
            NoAtomicLogsView(state: .empty)
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
        let attributedDescription = entry.attributedDescription
        return NavigationLink(destination: { SiteMonitoringEntryDetailsView(text: attributedDescription) }) {
            PHPLogsEntryRowView(entry: entry)
                .swipeActions(edge: .trailing) {
                    ShareLink(item: attributedDescription.string) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .tint(Color.blue)
                }
                .contextMenu {
                    ShareLink(item: attributedDescription.string) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } preview: {
                    Text(AttributedString(attributedDescription))
                        .frame(width: 320)
                        .padding()
                }
        }
    }

    private func loadLogs(searchCriteria: PHPLogsSearchCriteria, reset: Bool = false) {
        Task {
            await viewModel.loadLogs(searchCriteria: searchCriteria, reset: reset)
        }
    }

    private func reload() {
        loadLogs(searchCriteria: searchCriteria, reset: true)
    }
}

private struct PHPLogsEntryRowView: View {
    let entry: AtomicErrorLogEntry

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(entry.severity ?? "")
                    .font(.system(.caption, design: .monospaced))
                    .textCase(.uppercase)
                    .padding(4)
                    .foregroundColor(Color(uiColor: entry.severityTextColor))
                    .background(Color(uiColor: entry.severityBackgroundColor))
                    .cornerRadius(4)
                Spacer()
                Text((entry.timestamp?.mediumStringWithTime()) ?? "")
                    .font(.system(.footnote))
                    .foregroundStyle(.secondary)
            }
            Text(entry.message ?? "")
                .font(.system(.subheadline))
                .lineLimit(3)
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
            scrollId = nil
        }

        guard !isLoading && hasMore else {
            return
        }
        isLoading = true
        error = nil

        do {
            let endDate = searchCriteria.endDate ?? Date.now
            let startDate = searchCriteria.startDate ?? (Calendar.current.date(byAdding: .weekOfYear, value: -1, to: endDate) ?? endDate)

            let response = try await atomicSiteService.errorLogs(
                siteID: siteID,
                range: startDate..<endDate,
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

extension AtomicErrorLogEntry: Identifiable {
    var severityBackgroundColor: UIColor {
        let severity = AtomicErrorLogEntry.Severity(rawValue: severity ?? "")!
        switch severity {
        case .user: return .muriel(name: .gray, .shade5)
        case .warning: return .muriel(name: .yellow, .shade5)
        case .deprecated: return .muriel(name: .blue, .shade5)
        case .fatalError: return .muriel(name: .red, .shade5)
        }
    }

    var severityTextColor: UIColor {
        let severity = AtomicErrorLogEntry.Severity(rawValue: severity ?? "")!
        switch severity {
        case .user: return .muriel(name: .gray, .shade80)
        case .warning: return .muriel(name: .yellow, .shade80)
        case .deprecated: return .muriel(name: .blue, .shade80)
        case .fatalError: return .muriel(name: .red, .shade80)
        }
    }
}

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
