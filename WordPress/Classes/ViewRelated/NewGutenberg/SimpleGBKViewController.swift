import UIKit
import GutenbergKit
import CocoaLumberjackSwift
import WordPressData
import BuildSettingsKit
import WebKit
import DesignSystem

class SimpleGBKViewController: UIViewController {

    enum EditorLoadingState {
        case uninitialized
        case loadingDependencies(_ task: Task<Void, Error>)
        case loadingCancelled
        case dependencyError(Error)
        case dependenciesReady(EditorDependencies)
        case started
    }

    struct EditorDependencies {
        let settings: String?
        let didLoadCookies: Bool
    }

    private let blog: Blog

    private var editorViewController: GutenbergKit.EditorViewController
    private var editorState: EditorLoadingState = .uninitialized
    private var activityIndicator: UIActivityIndicatorView?
    private var editorLoadingTask: Task<Void, Error>?

    private let blockEditorSettingsService: RawBlockEditorSettingsService

    init(
        postID: Int,
        postTitle: String?,
        content: String,
        blog: Blog,
        postType: String?
    ) {
        self.blog = blog

        EditorLocalization.localize = getLocalizedString

        let editorConfiguration = EditorConfiguration(blog: blog)
            .toBuilder()
            .setPostID(postID)
            .setPostType(postType)
            .setTitle(postTitle ?? "")
            .setShouldHideTitle(postTitle == nil)
            .setContent(content)
            .setNativeInserterEnabled(FeatureFlag.nativeBlockInserter.enabled)
            .build()

        self.editorViewController = GutenbergKit.EditorViewController(
            configuration: editorConfiguration,
            mediaPicker: MediaPickerController(blog: blog)
        )

        self.blockEditorSettingsService = RawBlockEditorSettingsService(blog: blog)

        super.init(nibName: nil, bundle: nil)

        self.editorViewController.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    deinit {
        editorLoadingTask?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        setupEditorView()
        startLoadingDependencies()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if case .loadingDependencies = self.editorState {
            self.showActivityIndicator()
        }

        if case .loadingCancelled = self.editorState {
            startLoadingDependencies()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if case .loadingCancelled = self.editorState {
            preconditionFailure("Dependency loading should not be cancelled")
        }

        self.editorLoadingTask = Task { [weak self] in
            guard let self else { return }
            do {
                while case .loadingDependencies = self.editorState {
                    try await Task.sleep(nanoseconds: 1000)
                }

                switch self.editorState {
                    case .uninitialized: preconditionFailure("Dependencies must be initialized")
                    case .loadingDependencies: preconditionFailure("Dependencies should not still be loading")
                    case .loadingCancelled: preconditionFailure("Dependency loading should not be cancelled")
                    case .dependencyError(let error): self.showEditorError(error)
                    case .dependenciesReady(let dependencies): try await self.startEditor(settings: dependencies.settings)
                    case .started: preconditionFailure("The editor should not already be started")
                }
            } catch {
                self.showEditorError(error)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if case .loadingDependencies(let task) = self.editorState {
            task.cancel()
        }

        self.editorLoadingTask?.cancel()
    }

    private func setupEditorView() {
        view.tintColor = UIAppColor.editorPrimary

        addChild(editorViewController)
        view.addSubview(editorViewController.view)
        view.pinSubviewToAllEdges(editorViewController.view)
        editorViewController.didMove(toParent: self)

#if DEBUG
        editorViewController.webView.isInspectable = true
#endif
    }

    func showEditorError(_ error: Error) {
        DDLogError("Editor error: \(error)")
    }

    func startLoadingDependencies() {
        switch self.editorState {
        case .uninitialized:
            break
        case .loadingDependencies:
            preconditionFailure("`startLoadingDependencies` should not be called while in the `.loadingDependencies` state")
        case .loadingCancelled:
            break
        case .dependencyError:
            break
        case .dependenciesReady:
            preconditionFailure("`startLoadingDependencies` should not be called while in the `.dependenciesReady` state")
        case .started:
            preconditionFailure("`startLoadingDependencies` should not be called while in the `.started` state")
        }

        self.editorState = .loadingDependencies(Task {
            do {
                let dependencies = try await fetchEditorDependencies()
                self.editorState = .dependenciesReady(dependencies)
            } catch {
                self.editorState = .dependencyError(error)
            }
        })
    }

    @MainActor
    func startEditor(settings: String?) async throws {
        guard case .dependenciesReady = self.editorState else {
            preconditionFailure("`startEditor` should only be called when the editor is in the `.dependenciesReady` state.")
        }

        let updatedConfiguration = self.editorViewController.configuration.toBuilder()
            .apply(settings) { $0.setEditorSettings($1) }
            .setNativeInserterEnabled(FeatureFlag.nativeBlockInserter.enabled)
            .build()

        self.editorViewController.updateConfiguration(updatedConfiguration)
        self.editorViewController.startEditorSetup()
    }

    private func showActivityIndicator() {
        let indicator = UIActivityIndicatorView()
        indicator.color = .gray
        indicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(indicator)

        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        indicator.startAnimating()
        self.activityIndicator = indicator
    }

    private func hideActivityIndicator() {
        activityIndicator?.stopAnimating()
        activityIndicator?.removeFromSuperview()
        activityIndicator = nil
    }

    private func fetchEditorDependencies() async throws -> EditorDependencies {
        let settings: String?
        do {
            settings = try await blockEditorSettingsService.getSettingsString(allowingCachedResponse: true)
        } catch {
            DDLogError("Failed to fetch editor settings: \(error)")
            settings = nil
        }

        let loaded = await loadAuthenticationCookiesAsync()

        return EditorDependencies(settings: settings, didLoadCookies: loaded)
    }

    private func loadAuthenticationCookiesAsync() async -> Bool {
        guard blog.isPrivate() else {
            return true
        }

        guard let authenticator = RequestAuthenticator(blog: blog),
            let blogURL = blog.url,
            let authURL = URL(string: blogURL) else {
            return false
        }

        let cookieJar = WKWebsiteDataStore.default().httpCookieStore

        return await withCheckedContinuation { continuation in
            authenticator.request(url: authURL, cookieJar: cookieJar) { _ in
                DDLogInfo("Authentication cookies loaded into shared cookie store for GutenbergKit")
                continuation.resume(returning: true)
            }
        }
    }

    func getCurrentContent() async throws -> (title: String, content: String) {
        let editorData = try await editorViewController.getTitleAndContent()
        return (editorData.title, editorData.content)
    }
}

extension SimpleGBKViewController: GutenbergKit.EditorViewControllerDelegate {
    func editorDidLoad(_ viewContoller: GutenbergKit.EditorViewController) {
        self.hideActivityIndicator()
    }

    func editor(_ viewContoller: GutenbergKit.EditorViewController, didDisplayInitialContent content: String) {
    }

    func editor(_ viewContoller: GutenbergKit.EditorViewController, didEncounterCriticalError error: any Error) {
        DDLogError("Editor critical error: \(error)")
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didUpdateContentWithState state: GutenbergKit.EditorState) {
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didUpdateHistoryState state: GutenbergKit.EditorState) {
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didUpdateFeaturedImage mediaID: Int) {
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didLogException error: GutenbergKit.GutenbergJSException) {
        DDLogError("Gutenberg exception: \(error)")
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didLogMessage message: String, level: GutenbergKit.LogLevel) {
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didRequestMediaFromSiteMediaLibrary config: GutenbergKit.OpenMediaLibraryAction) {
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didTriggerAutocompleter type: String) {
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didOpenModalDialog dialogType: String) {
    }

    func editor(_ viewController: GutenbergKit.EditorViewController, didCloseModalDialog dialogType: String) {
    }
}

private func getLocalizedString(for value: GutenbergKit.EditorLocalizableString) -> String {
    switch value {
    case .showMore: NSLocalizedString("editor.blockInserter.showMore", value: "Show More", comment: "Button title to expand and show more blocks")
    case .showLess: NSLocalizedString("editor.blockInserter.showLess", value: "Show Less", comment: "Button title to collapse and show fewer blocks")
    case .search: NSLocalizedString("editor.blockInserter.search", value: "Search", comment: "Placeholder text for block search field")
    case .insertBlock: NSLocalizedString("editor.blockInserter.insertBlock", value: "Insert Block", comment: "Context menu action to insert a block")
    case .failedToInsertMedia: NSLocalizedString("editor.media.failedToInsert", value: "Failed to insert media", comment: "Error message when media insertion fails")
    case .patterns: NSLocalizedString("editor.patterns.title", value: "Patterns", comment: "Navigation title for patterns view")
    case .noPatternsFound: NSLocalizedString("editor.patterns.noPatternsFound", value: "No Patterns Found", comment: "Title shown when no patterns match the search")
    case .insertPattern: NSLocalizedString("editor.patterns.insertPattern", value: "Insert Pattern", comment: "Context menu action to insert a pattern")
    case .patternsCategoryUncategorized: NSLocalizedString("editor.patterns.uncategorized", value: "Uncategorized", comment: "Category name for patterns without a category")
    case .patternsCategoryAll: NSLocalizedString("editor.patterns.all", value: "All", comment: "Category name for section showing all patterns")
    }
}
