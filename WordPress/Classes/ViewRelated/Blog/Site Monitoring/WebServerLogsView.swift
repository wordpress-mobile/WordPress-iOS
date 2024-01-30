import SwiftUI
import WordPressKit

struct WebServerLogsView: View {
    @StateObject var viewModel: WebServerLogsViewModel
    @State private var searchCriteria = WebServerLogsSearchCriteria(startDate: Date.oneWeekAgo)

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
                NoAtomicLogsView(state: .error(reload))
            } else {
                NoAtomicLogsView(state: .empty)
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
            FilterCompactButton(Strings.filterRequestType, selection: $searchCriteria.requestType) {
                Picker("", selection: $searchCriteria.requestType) {
                    let cases = ["GET", "HEAD", "POST", "PUT", "DELETE"]
                    ForEach(cases, id: \.self) {
                        Text($0).tag(Optional.some($0))
                    }
                }.pickerStyle(.inline)
            } label: {
                Text($0)
            }
            .contentPresentationStyle(.menu)
            FilterCompactButton(Strings.filterStatus, selection: $searchCriteria.status) {
                Picker("", selection: $searchCriteria.status) {
                    let cases = [200, 301, 302, 400, 401, 403, 404, 500]
                    ForEach(cases, id: \.self) {
                        Text("\($0)").tag(Optional.some($0))
                    }
                }.pickerStyle(.inline)
            } label: {
                Text("\($0)")
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

    private func makeRow(for entry: AtomicWebServerLogEntry) -> some View {
        NavigationLink(destination: { EmptyView() }) {
            VStack(alignment: .leading) {
                HStack {
                    Text(entry.requestType ?? "")
                        .font(.system(size: 12, design: .monospaced))
                        .textCase(.uppercase)
                        .padding(4)
                        .background(Color.blue.opacity(0.33))
                        .cornerRadius(4)
                    Text(entry.status.flatMap(String.init) ?? "")
                        .font(.system(size: 12, design: .monospaced))
                        .textCase(.uppercase)
                    Spacer()
                    Text((entry.date?.mediumStringWithTime()) ?? "")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Text(entry.requestUrl ?? "")
                    .font(.system(size: 15))
                    .lineLimit(3)
            }
        }
    }

    private func loadLogs(searchCriteria: WebServerLogsSearchCriteria, reset: Bool = false) {
        Task {
            await viewModel.loadLogs(searchCriteria: searchCriteria, reset: reset)
        }
    }

    private func reload() {
        loadLogs(searchCriteria: searchCriteria, reset: true)
    }
}

@MainActor
final class WebServerLogsViewModel: ObservableObject {
    private let blog: Blog
    private let atomicSiteService: AtomicSiteService

    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var loadedLogs: [AtomicWebServerLogEntry] = []
    @Published private(set) var hasMore = true

    private var scrollId: String?

    init(blog: Blog, atomicSiteService: AtomicSiteService) {
        self.blog = blog
        self.atomicSiteService = atomicSiteService
    }

    /// Loads the next page. Does nothing if it's already loading or has no more items to load.
    func loadLogs(searchCriteria: WebServerLogsSearchCriteria, reset: Bool = false) async {
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
            let response = try await atomicSiteService.webServerLogs(
                siteID: siteID,
                range: (searchCriteria.startDate ?? Date.oneWeekAgo)..<(searchCriteria.endDate ?? Date.now),
                httpMethod: searchCriteria.requestType,
                statusCode: searchCriteria.status,
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

extension AtomicWebServerLogEntry: Identifiable {}

struct WebServerLogsSearchCriteria: Equatable {
    var startDate: Date?
    var endDate: Date?
    var requestType: String?
    var status: Int?
}

private enum Strings {
    static let filterStartDate = NSLocalizedString("webServerLogs.filterStartDate", value: "Start Date", comment: "A title for the filter on the PHP logs screen")
    static let filterEndDate = NSLocalizedString("webServerLogs.filterEndDate", value: "End Date", comment: "A title for the filter on the PHP logs screen")
    static let filterRequestType = NSLocalizedString("webServerLogs.filterRequestType", value: "Request type", comment: "A title for the filter on the PHP logs screen")
    static let filterStatus = NSLocalizedString("webServerLogs.filterStatus", value: "Status", comment: "A title for the filter on the PHP logs screen")
}
