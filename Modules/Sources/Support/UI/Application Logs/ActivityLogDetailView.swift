import SwiftUI

/// A view to display the contents of a log file
struct ActivityLogDetailView: View {

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    enum ViewState {
        case loading
        case loaded([String])
        case error(Error)
    }

    @State
    private var state: ViewState = .loading

    let applicationLog: ApplicationLog

    var body: some View {
        Group {
            switch self.state {
            case .loading:
                self.loadingView
            case .loaded(let lines):
                self.loadedView(lines: lines)
            case .error(let error):
                self.errorView(error: error)
            }
        }
        .navigationTitle(applicationLog.path.lastPathComponent)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: self.applicationLog.path) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(self.isSharingDisabled)
            }
        }
        .onAppear {
            self.dataProvider.userDid(.viewApplicationLog(self.applicationLog.id))
        }
        .task(self.loadLogContent)
        .refreshable(action: self.loadLogContent)
    }

    private var isSharingDisabled: Bool {
        guard case .loaded = self.state else {
            return true
        }

        return false
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

            self.state = .loaded(lines)
        } catch {
            self.state = .error(error)
        }
    }
}

#Preview {
    NavigationStack {
        ActivityLogDetailView(
            applicationLog: SupportDataProvider.applicationLog
        ).environmentObject(SupportDataProvider.testing)
    }
}
