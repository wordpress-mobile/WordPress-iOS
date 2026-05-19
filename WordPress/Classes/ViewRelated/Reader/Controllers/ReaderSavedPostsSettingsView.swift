import SwiftUI
import WordPressData
import WordPressShared
import UniformTypeIdentifiers

struct ReaderSavedPostsSettingsView: View {
    @StateObject private var viewModel: ReaderSavedPostsSettingsViewModel

    init(coreDataStack: CoreDataStackSwift = ContextManager.shared) {
        _viewModel = StateObject(wrappedValue: ReaderSavedPostsSettingsViewModel(coreDataStack: coreDataStack))
    }

    var body: some View {
        List {
            Section {
                Button {
                    viewModel.isShowingFilePicker = true
                } label: {
                    Label(Strings.importButton, systemImage: "arrow.down.doc")
                }
                .disabled(viewModel.isImporting)

                Button {
                    viewModel.exportSavedPosts()
                } label: {
                    Label(Strings.exportButton, systemImage: "arrow.up.doc")
                }
                .disabled(viewModel.isImporting)

                if viewModel.isImporting {
                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(value: viewModel.importProgress, total: 1.0)
                        Text(viewModel.importStatusText)
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

@MainActor
final class ReaderSavedPostsSettingsViewModel: ObservableObject {
    @Published var exportedFileURL: IdentifiableURL?
    @Published var isShowingFilePicker = false
    @Published var isShowingImportResult = false
    @Published var isShowingError = false
    @Published var isImporting = false
    @Published var importProgress: Double = 0
    @Published var importStatusText = ""

    @Published private(set) var importResultMessage = ""
    @Published private(set) var errorMessage = ""

    private let coreDataStack: CoreDataStackSwift
    private let exporter = ReaderSavedPostsExporter()
    private var progressObservation: NSKeyValueObservation?

    init(coreDataStack: CoreDataStackSwift) {
        self.coreDataStack = coreDataStack
    }

    func viewAppeared() {
        WPAnalytics.track(.readerSavedPostsSettingsShown)
    }

    func exportSavedPosts() {
        do {
            guard let fileURL = try exporter.export(context: coreDataStack.mainContext) else {
                errorMessage = Strings.exportEmpty
                isShowingError = true
                return
            }
            exportedFileURL = IdentifiableURL(value: fileURL)
            WPAnalytics.track(.readerSavedPostsExported)
        } catch {
            errorMessage = Strings.exportError
            isShowingError = true
        }
    }

    func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = Strings.importError
                isShowingError = true
                return
            }

            let posts: [ReaderSavedPostsExporter.ExportedPost]
            do {
                posts = try ReaderSavedPostsExporter.parseExportFile(at: url)
            } catch {
                url.stopAccessingSecurityScopedResource()
                errorMessage = error.localizedDescription
                isShowingError = true
                return
            }

            url.stopAccessingSecurityScopedResource()

            isImporting = true
            importProgress = 0
            importStatusText = String.localizedStringWithFormat(Strings.importProgressFormat, 0, posts.count)

            let progress = Progress(totalUnitCount: Int64(posts.count))
            progressObservation = progress.observe(\.fractionCompleted) { [weak self] progress, _ in
                Task { @MainActor in
                    self?.importProgress = progress.fractionCompleted
                    self?.importStatusText = String.localizedStringWithFormat(
                        Strings.importProgressFormat,
                        Int(progress.completedUnitCount),
                        Int(progress.totalUnitCount)
                    )
                }
            }

            Task {
                let importResult = await ReaderSavedPostsExporter.importPosts(
                    posts,
                    coreDataStack: coreDataStack,
                    progress: progress
                )
                progressObservation = nil
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

        case .failure:
            errorMessage = Strings.importError
            isShowingError = true
        }
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
    static let importProgressFormat = NSLocalizedString(
        "reader.savedPosts.settings.importProgress",
        value: "Fetching post %1$d of %2$d…",
        comment: "Progress text during import. %1$d is current post number, %2$d is total."
    )
    static let errorTitle = NSLocalizedString(
        "reader.savedPosts.settings.errorTitle",
        value: "Error",
        comment: "Title of error alert in saved posts settings"
    )
}
