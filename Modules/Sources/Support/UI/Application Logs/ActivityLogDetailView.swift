import SwiftUI

/// A view to display the contents of a log file
struct ActivityLogDetailView: View {

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    enum ViewState: Equatable {
        case loading
        case loaded([String], isSharing: Bool)
        case error(Error)

        static func == (lhs: ActivityLogDetailView.ViewState, rhs: ActivityLogDetailView.ViewState) -> Bool {
            return switch (lhs, rhs) {
            case (.loading, .loading): true
            case (.loaded(let lhsLines, let lhsisSharing), .loaded(let rhsLines, let rhsisSharing)):
                lhsLines == rhsLines && lhsisSharing == rhsisSharing
            case (.error, .error): true
            default: false
            }
        }
    }

    @State
    private var state: ViewState = .loading

    @State
    private var isDisplayingShareSheet: Bool = false

    @State
    private var sharingIsDisabled: Bool = true

    let applicationLog: ApplicationLog

    var body: some View {
        Group {
            switch self.state {
            case .loading:
                self.loadingView
            case .loaded(let lines, _):
                self.loadedView(lines: lines)
            case .error(let error):
                self.errorView(error: error)
            }
        }
        .navigationTitle(applicationLog.path.lastPathComponent)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: self.startSharing) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(self.sharingIsDisabled)
            }
        }
        .sheet(isPresented: self.$isDisplayingShareSheet, onDismiss: {
            guard case .loaded(let lines, _) = self.state else {
                return
            }

            self.state = .loaded(lines, isSharing: false)
        }, content: {
            ActivityLogSharingView(applicationLog: applicationLog) {
                AnyView(erasing: Text("TODO: A new support request with the application log attached"))
            }
            .presentationDetents([.medium])
        })
        .onAppear {
            self.dataProvider.userDid(.viewApplicationLog(self.applicationLog.id))
        }
        .task(self.loadLogContent)
        .refreshable(action: self.loadLogContent)
        .onChange(of: state) { oldValue, newValue in
            if case .loaded(_, let isSharing) = state {
                self.sharingIsDisabled = false
                self.isDisplayingShareSheet = isSharing
            } else {
                self.isDisplayingShareSheet = false
                self.sharingIsDisabled = true
            }
        }
    }

    @ViewBuilder
    var loadingView: some View {
        ProgressView(Localization.loadingLogContent).padding()
    }

    @ViewBuilder
    func loadedView(lines: [String]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                logLinesContent(lines: lines)
            }
            .font(.system(.body, design: .monospaced))
            .padding()
        }
    }

    @ViewBuilder
    private func logLinesContent(lines: [String]) -> some View {
        ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
            Text(line)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    func errorView(error: Error) -> some View {
        ErrorView(
            title: "Unable to read log file",
            message: error.localizedDescription
        )
    }

    private func loadLogContent() async {
        do {
            let content = try await self.dataProvider.readApplicationLog(applicationLog)
            let lines = content
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map(String.init)

            self.state = .loaded(lines, isSharing: false)
        } catch {
            self.state = .error(error)
        }
    }

    private func startSharing() {
        guard case .loaded(let lines, _) = self.state else {
            return
        }

        state = .loaded(lines, isSharing: true)
    }
}

#Preview {
    NavigationStack {
        ActivityLogDetailView(
            applicationLog: SupportDataProvider.applicationLog
        ).environmentObject(SupportDataProvider.testing)
    }
}
