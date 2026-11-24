import SwiftUI
import WordPressShared
import UniformTypeIdentifiers

struct ReaderSavedPostsSettingsView: View {
    @StateObject private var viewModel: ReaderSavedPostsSettingsViewModel

    @MainActor
    init() {
        _viewModel = StateObject(wrappedValue: ReaderSavedPostsSettingsViewModel(store: .shared))
    }

    var body: some View {
        List {
            Section {
                Button {
                    viewModel.isShowingFilePicker = true
                } label: {
                    Label(Strings.importButton, systemImage: "arrow.down.doc")
                }
                .disabled(viewModel.isBusy)

                Button {
                    viewModel.exportSavedPosts()
                } label: {
                    Label(Strings.exportButton, systemImage: "arrow.up.doc")
                }
                .disabled(viewModel.isBusy)

                if viewModel.isImporting {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text(Strings.importingStatus)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                } else if viewModel.isExporting {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text(Strings.exportingStatus)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            } footer: {
                Text(Strings.sectionFooter)
            }
        }
        .navigationTitle(Strings.title)
        .sheet(item: $viewModel.exportedFileURL) { url in
            ActivityView(activityItems: [url.value])
        }
        .fileImporter(
            isPresented: $viewModel.isShowingFilePicker,
            allowedContentTypes: [.json],
            onCompletion: viewModel.handleFileImport
        )
        .alert(Strings.importCompleteTitle, isPresented: $viewModel.isShowingImportResult) {
            Button(SharedStrings.Button.ok) {}
        } message: {
            Text(viewModel.importResultMessage)
        }
        .alert(Strings.errorTitle, isPresented: $viewModel.isShowingError) {
            Button(SharedStrings.Button.ok) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .onAppear {
            viewModel.viewAppeared()
        }
    }
}

// MARK: - ViewModel

/// Imports and exports the saved posts kept in the WordPress.com account.
@MainActor
final class ReaderSavedPostsSettingsViewModel: ObservableObject {
    @Published var exportedFileURL: IdentifiableURL?
    @Published var isShowingFilePicker = false
    @Published var isShowingImportResult = false
    @Published var isShowingError = false
    @Published var isExporting = false
    @Published var isImporting = false

    /// Whether an import or export is currently in flight.
    var isBusy: Bool { isImporting || isExporting }

    @Published private(set) var importResultMessage = ""
    @Published private(set) var errorMessage = ""

    private let store: ReaderSavedPostsStore
    private let exporter = ReaderSavedPostsExporter()

    init(store: ReaderSavedPostsStore) {
        self.store = store
    }

    func viewAppeared() {
        WPAnalytics.track(.readerSavedPostsSettingsShown)
    }

    func exportSavedPosts() {
        guard !isBusy else { return }
        guard let savedPosts = store.savedPosts else {
            showError(Strings.signInRequired)
            return
        }
        isExporting = true
        Task {
            defer { isExporting = false }
            do {
                guard let fileURL = try await exporter.export(collection: savedPosts) else {
                    showError(Strings.exportEmpty)
                    return
                }
                exportedFileURL = IdentifiableURL(value: fileURL)
                WPAnalytics.track(.readerSavedPostsExported)
            } catch {
                showError(Strings.exportError)
            }
        }
    }

    func handleFileImport(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else {
            showError(Strings.importError)
            return
        }
        guard store.isActive else {
            showError(Strings.signInRequired)
            return
        }
        guard url.startAccessingSecurityScopedResource() else {
            showError(Strings.importError)
            return
        }

        let posts: [ReaderSavedPostsExporter.ExportedPost]
        do {
            posts = try ReaderSavedPostsExporter.parseExportFile(at: url)
        } catch {
            url.stopAccessingSecurityScopedResource()
            showError(error.localizedDescription)
            return
        }
        url.stopAccessingSecurityScopedResource()

        isImporting = true
        Task {
            // The posts go straight to the account.
            let importResult = await ReaderSavedPostsExporter.importPostsToAccount(posts, store: store)
            isImporting = false
            importResultMessage = String.localizedStringWithFormat(
                Strings.importResultFormat,
                importResult.imported,
                importResult.skipped,
                importResult.failed
            )
            isShowingImportResult = true
            WPAnalytics.track(
                .readerSavedPostsImported,
                properties: [
                    "imported": importResult.imported,
                    "skipped": importResult.skipped,
                    "failed": importResult.failed
                ]
            )
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        isShowingError = true
    }
}

// MARK: - Activity View

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Helpers

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let value: URL
}

// MARK: - Strings

private enum Strings {
    static let title = NSLocalizedString(
        "reader.savedPosts.settings.title",
        value: "Saved Posts",
        comment: "Title for the saved Reader posts settings screen"
    )
    static let exportButton = NSLocalizedString(
        "reader.savedPosts.settings.export",
        value: "Export Saved Posts",
        comment: "Button to export saved Reader posts as a JSON file"
    )
    static let importButton = NSLocalizedString(
        "reader.savedPosts.settings.import",
        value: "Import Saved Posts",
        comment: "Button to import saved Reader posts from a JSON file"
    )
    static let sectionFooter = NSLocalizedString(
        "reader.savedPosts.settings.footer",
        value:
            "Export your saved posts as a JSON file for backup, or import a previously exported file. Duplicate posts are skipped automatically.",
        comment: "Footer text explaining the saved posts export and import feature"
    )
    static let exportEmpty = NSLocalizedString(
        "reader.savedPosts.settings.exportEmpty",
        value: "No saved posts to export.",
        comment: "Message shown when user tries to export but has no saved posts"
    )
    static let exportError = NSLocalizedString(
        "reader.savedPosts.settings.exportError",
        value: "Could not export saved posts. Please try again.",
        comment: "Error message when export of saved Reader posts fails"
    )
    static let exportingStatus = NSLocalizedString(
        "reader.savedPosts.settings.exportingStatus",
        value: "Preparing export…",
        comment: "Status text shown while the saved Reader posts export file is being prepared"
    )
    static let importError = NSLocalizedString(
        "reader.savedPosts.settings.importError",
        value: "Could not import the selected file. Please try again.",
        comment: "Error message when import of saved Reader posts fails"
    )
    static let importCompleteTitle = NSLocalizedString(
        "reader.savedPosts.settings.importCompleteTitle",
        value: "Import Complete",
        comment: "Title of alert shown after importing saved posts"
    )
    static let importResultFormat = NSLocalizedString(
        "reader.savedPosts.settings.importResult",
        value: "%1$d imported, %2$d skipped, %3$d failed.",
        comment:
            "Result message after importing saved posts. %1$d is imported count, %2$d is skipped count, %3$d is failed count."
    )
    static let importingStatus = NSLocalizedString(
        "reader.savedPosts.settings.importingStatus",
        value: "Saving posts to your account…",
        comment: "Status text shown while the posts in an imported file are saved to the WordPress.com account"
    )
    static let signInRequired = NSLocalizedString(
        "reader.savedPosts.settings.signInRequired",
        value: "Sign in to WordPress.com to import or export saved posts.",
        comment: "Error shown in saved posts settings when there's no WordPress.com account"
    )
    static let errorTitle = NSLocalizedString(
        "reader.savedPosts.settings.errorTitle",
        value: "Error",
        comment: "Title of error alert in saved posts settings"
    )
}
