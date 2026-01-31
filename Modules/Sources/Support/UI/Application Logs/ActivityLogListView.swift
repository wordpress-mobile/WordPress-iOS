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

    @State
    private var showExtensiveLoggingAlert = false

    @State
    private var extensiveLoggingEnabled = ExtensiveLogging.enabled

    @State
    private var showExtensiveLogs = false

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
                    title: Localization.errorLoadingLogs,
                    message: error.localizedDescription
                )
            }
        }
        .navigationTitle(Localization.applicationLogsTitle)
        .overlay {
            if case .loaded(_, let deletionState) = self.state {
                switch deletionState {
                case .none: EmptyView() // Do nothing
                case .deleting: ProgressView()
                case .confirm: EmptyView() // Do nothing
                case .deletionError(let error): ErrorView(
                    title: Localization.unableToDeleteLogs,
                    message: error.localizedDescription
                )
                }
            }
        }
        .alert(Localization.confirmDeleteAllLogs, isPresented: self.$isConfirmingDeletion, actions: {

            Button (Localization.deleteAllLogs, role: .destructive) {
                self.deleteAllLogFiles()
            }

            Button(Localization.cancel, role: .cancel) {
                // Alert will be dismissed on its own
            }

        }, message: {
            Text(Localization.cannotRecoverLogs)
        })
        .alert(Localization.extensiveLoggingAlertTitle, isPresented: $showExtensiveLoggingAlert) {
            Button(Localization.cancel, role: .cancel) {}
            Button(Localization.enable) {
                ExtensiveLogging.enabled = true
                extensiveLoggingEnabled = true
            }
        } message: {
            Text(Localization.extensiveLoggingAlertMessage)
        }
        .sheet(isPresented: $showExtensiveLogs) {
            ExtensiveLogsView(dataProvider: dataProvider)
        }
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
                    Text(Localization.logFilesByDate)
                } footer: {
                    Text(Localization.logRetentionNotice)
                }

                Button(Localization.clearAllActivityLogs) {
                    self.isConfirmingDeletion = true
                }

                Section {
                    Toggle(isOn: Binding(
                        get: { extensiveLoggingEnabled },
                        set: { newValue in
                            if newValue {
                                showExtensiveLoggingAlert = true
                            } else {
                                ExtensiveLogging.enabled = false
                                extensiveLoggingEnabled = false
                            }
                        }
                    )) {
                        Text(Localization.extensiveLogging)
                    }

                    if extensiveLoggingEnabled {
                        Button {
                            showExtensiveLogs = true
                        } label: {
                            HStack {
                                Text(Localization.extensiveLogs)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption.weight(.semibold))
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        } else {
            ContentUnavailableView {
                Label(Localization.noLogsFound, systemImage: "doc.text")
            } description: {
                Text(Localization.noLogsAvailable)
            }
        }
    }

    @ViewBuilder
    var loadingView: some View {
        ProgressView(Localization.loadingLogs)
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

private struct ExtensiveLogsView: UIViewControllerRepresentable {
    var dataProvider: SupportDataProvider

    public func makeUIViewController(context: Context) -> UIViewController {
        dataProvider.extensiveLogsViewController()
    }

    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        ActivityLogListView().environmentObject(SupportDataProvider.testing)
    }
}
