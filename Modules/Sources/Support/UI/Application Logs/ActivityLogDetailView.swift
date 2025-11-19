import SwiftUI

/// A view to display the contents of a log file
struct ActivityLogDetailView: View {

    @EnvironmentObject
    private var dataProvider: SupportDataProvider

    enum ViewState: Equatable {
        case loading
        case loaded(String, isSharing: Bool)
        case error(Error)

        static func == (lhs: ActivityLogDetailView.ViewState, rhs: ActivityLogDetailView.ViewState) -> Bool {
            return switch (lhs, rhs) {
            case (.loading, .loading): true
            case (.loaded(let lhscontent, let lhsisSharing), .loaded(let rhscontent, let rhsisSharing)):
                lhscontent == rhscontent && lhsisSharing == rhsisSharing
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
            case .loaded(let content, _):
                self.loadedView(content: content)
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
            guard case .loaded(let content, _) = self.state else {
                return
            }

            self.state = .loaded(content, isSharing: false)
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
    func loadedView(content: String) -> some View {
        ScrollView {
            VStack(alignment: .leading) {
                TextEditor(text: .constant(content))
                    .font(.system(.body, design: .monospaced))
                    .fixedSize(horizontal: false, vertical: true)
                    .scrollDisabled(true)
                    .padding()
            }
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

            self.state = .loaded(content, isSharing: false)
        } catch {
            self.state = .error(error)
        }
    }

    private func startSharing() {
        guard case .loaded(let content, _) = self.state else {
            return
        }

        state = .loaded(content, isSharing: true)
    }
}

#Preview {
    NavigationStack {
        ActivityLogDetailView(
            applicationLog: SupportDataProvider.applicationLog
        ).environmentObject(SupportDataProvider.testing)
    }
}
