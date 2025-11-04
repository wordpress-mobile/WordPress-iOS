import SwiftUI

/// A view that displays a list of application log files in reverse chronological order.
public struct ActivityLogListView: View {

    enum ViewState {
        case loading
        case loaded([ApplicationLog], DeletionState)
        case error(Error)
    }

    enum DeletionState {
        case none
        case confirm
        case deleting(Task<Void, Never>)
        case deletionError(Error)
    }

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    @State
    var state: ViewState = .loading

    @State
    var isConfirmingDeletion: Bool = false

    public init() {}

    public var body: some View {
        Group {
            switch self.state {
            case .loading:
                loadingView
            case .loaded(let logFiles, let deletionState):
                listView(logFiles: logFiles, deletionState: deletionState)
            case .error(let error):
                ErrorView(
                    title: "Error loading logs",
                    message: error.localizedDescription
                )
            }
        }
        .navigationTitle("Application Logs")
        .overlay {
            if case .loaded(_, let deletionState) = self.state {
                switch deletionState {
                case .none: EmptyView() // Do nothing
                case .deleting: ProgressView()
                case .confirm: EmptyView() // Do nothing
                case .deletionError(let error): ErrorView(
                    title: "Unable to delete logs",
                    message: error.localizedDescription
                )
                }
            }
        }
        .alert("Are you sure you want to delete all logs?", isPresented: self.$isConfirmingDeletion, actions: {

            Button ("Delete all Logs", role: .destructive) {
                self.deleteAllLogFiles()
            }

            Button("Cancel", role: .cancel) {
                // Alert will be dismissed on its own
            }

        }, message: {
            Text("You won't be able to get them back.")
        })
        .onAppear {
            self.dataProvider.userDid(.viewApplicationLogList)
        }
        .refreshable {
            await self.loadLogFiles()
        }
        .task {
            await self.loadLogFiles()
        }
    }

    @ViewBuilder
    func listView(logFiles: [ApplicationLog], deletionState: DeletionState) -> some View {
        if !logFiles.isEmpty {
            List {
                Section {
                    ForEach(logFiles) { logFile in
                        NavigationLink(
                            destination: ActivityLogDetailView(applicationLog: logFile)
                                .environmentObject(dataProvider)
                        ) {
                            SubtitledListViewItem(
                                title: logFile.createdAt.description,
                                subtitle: logFile.path.lastPathComponent
                            )
                        }
                    }.onDelete(perform: self.deleteLogFiles)
                } header: {
                    Text("Log files by created date")
                } footer: {
                    Text("Up to seven days worth of logs are saved.")
                }

                Button("Clear All Activity Logs") {
                    self.isConfirmingDeletion = true
                }
            }
        } else {
            ContentUnavailableView {
                Label("No Logs Found", systemImage: "doc.text")
            } description: {
                Text("There are no activity logs available")
            }
        }
    }

    @ViewBuilder
    var loadingView: some View {
        ProgressView("Loading logs...")
    }

    func deleteLogFiles(_ indexSet: IndexSet) {
        guard case .loaded(let array, _) = state else {
            return
        }

        let logsToDelete = indexSet.map { array[$0] }

        let task = Task {
            do {
                try await self.dataProvider.deleteApplicationLogs(in: logsToDelete)
                let refreshedLogList = try await self.dataProvider.fetchApplicationLogs()
                self.state = .loaded(refreshedLogList, .none)
            } catch {
                self.state = .loaded(array, .deletionError(error))
            }
        }

        self.state = .loaded(array, .deleting(task))
    }

    func deleteAllLogFiles() {
        guard case .loaded(let array, _) = state else {
            return
        }

        let task = Task {
            do {
                try await self.dataProvider.deleteAllApplicationLogs()
                self.state = .loaded([], .none)
            } catch {
                self.state = .loaded(array, .deletionError(error))
            }
        }

        self.state = .loaded(array, .deleting(task))
    }

    func loadLogFiles() async {
        do {
            let logs = try await self.dataProvider.fetchApplicationLogs()
            self.state = .loaded(logs, .none)
        } catch {
            self.state = .error(error)
        }
    }
}

#Preview {
    NavigationStack {
        ActivityLogListView().environmentObject(SupportDataProvider.testing)
    }
}
