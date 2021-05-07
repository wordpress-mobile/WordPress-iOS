import Foundation
import Kanvas

/// An story editor which displays the Kanvas camera + editing screens.
class StoryEditor: CameraController {

    var post: AbstractPost = AbstractPost()

    private static let directoryName = "Stories"

    /// A directory to temporarily hold imported media.
    /// - Throws: Any errors resulting from URL or directory creation.
    /// - Returns: A URL with the media cache directory.
    static func mediaCacheDirectory() throws -> URL {
        let storiesURL = try MediaFileManager.cache.directoryURL().appendingPathComponent(directoryName, isDirectory: true)
        try FileManager.default.createDirectory(at: storiesURL, withIntermediateDirectories: true, attributes: nil)
        return storiesURL
    }

    /// A directory to temporarily hold saved archives.
    /// - Throws: Any errors resulting from URL or directory creation.
    /// - Returns: A URL with the save directory.
    static func saveDirectory() throws -> URL {
        let saveDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(directoryName, isDirectory: true)
        try FileManager.default.createDirectory(at: saveDirectory, withIntermediateDirectories: true, attributes: nil)
        return saveDirectory
    }

    var onClose: ((Bool, Bool) -> Void)? = nil

    var editorSession: PostEditorAnalyticsSession

    let navigationBarManager: PostEditorNavigationBarManager? = nil

    fileprivate(set) lazy var debouncer: Debouncer = {
        return Debouncer(delay: PostEditorDebouncerConstants.autoSavingDelay, callback: debouncerCallback)
    }()

    private(set) lazy var postEditorStateContext: PostEditorStateContext = {
        return PostEditorStateContext(post: post, delegate: self)
    }()

    var verificationPromptHelper: VerificationPromptHelper? = nil

    var analyticsEditorSource: String {
        return "stories"
    }

    private var cameraHandler: CameraHandler?
    private var poster: StoryPoster?
    private lazy var storyLoader: StoryMediaLoader = {
        return StoryMediaLoader()
    }()

    private static let useMetal = false

    static var cameraSettings: CameraSettings {
        let settings = CameraSettings()
        settings.features.ghostFrame = true
        settings.features.metalPreview = useMetal
        settings.features.metalFilters = useMetal
        settings.features.openGLPreview = !useMetal
        settings.features.openGLCapture = !useMetal
        settings.features.cameraFilters = false
        settings.features.experimentalCameraFilters = true
        settings.features.editor = true
        settings.features.editorGIFMaker = false
        settings.features.editorFilters = false
        settings.features.editorText = true
        settings.features.editorMedia = true
        settings.features.editorDrawing = false
        settings.features.editorMedia = false
        settings.features.mediaPicking = true
        settings.features.editorPostOptions = false
        settings.features.newCameraModes = true
        settings.features.gifs = false
        settings.features.multipleExports = true
        settings.features.editorConfirmAtTop = true
        settings.features.muteButton = true
        settings.crossIconInEditor = true
        settings.enabledModes = [.normal]
        settings.defaultMode = .normal
        settings.features.scaleMediaToFill = true
        settings.features.resizesFonts = false
        settings.animateEditorControls = false
        settings.exportStopMotionPhotoAsVideo = false
        settings.fontSelectorUsesFont = true
        settings.aspectRatio = 9/16

        return settings
    }

    enum EditorCreationError: Error {
        case unsupportedDevice
    }

    typealias UpdateResult = Result<String, PostCoordinator.SavingError>
    typealias UploadResult = Result<Void, PostCoordinator.SavingError>

    static func editor(blog: Blog,
                       context: NSManagedObjectContext,
                       updated: @escaping (UpdateResult) -> Void) throws -> StoryEditor {
        let post = PostService(managedObjectContext: context).createDraftPost(for: blog)
        return try editor(post: post, mediaFiles: nil, publishOnCompletion: true, updated: updated)
    }

    static func editor(post: AbstractPost,
                       mediaFiles: [MediaFile]?,
                       publishOnCompletion: Bool = false,
                       updated: @escaping (UpdateResult) -> Void) throws -> StoryEditor {

        guard !UIDevice.isPad() else {
            throw EditorCreationError.unsupportedDevice
        }

        let controller = StoryEditor(post: post,
                                     onClose: nil,
                                     settings: cameraSettings,
                                     stickerProvider: nil,
                                     analyticsProvider: nil,
                                     quickBlogSelectorCoordinator: nil,
                                     tagCollection: nil,
                                     mediaFiles: mediaFiles,
                                     publishOnCompletion: publishOnCompletion,
                                     updated: updated)
        controller.modalPresentationStyle = .fullScreen
        controller.modalTransitionStyle = .crossDissolve
        return controller
    }

    init(post: AbstractPost,
                     onClose: ((Bool, Bool) -> Void)?,
                     settings: CameraSettings,
                     stickerProvider: StickerProvider?,
                     analyticsProvider: KanvasAnalyticsProvider?,
                     quickBlogSelectorCoordinator: KanvasQuickBlogSelectorCoordinating?,
                     tagCollection: UIView?,
                     mediaFiles: [MediaFile]?,
                     publishOnCompletion: Bool,
                     updated: @escaping (UpdateResult) -> Void) {
        self.post = post
        self.onClose = onClose
        self.editorSession = PostEditorAnalyticsSession(editor: .stories, post: post)

        Kanvas.KanvasColors.shared = KanvasCustomUI.shared.cameraColors()
        Kanvas.KanvasFonts.shared = KanvasCustomUI.shared.cameraFonts()
        Kanvas.KanvasImages.shared = KanvasCustomUI.shared.cameraImages()
        Kanvas.KanvasStrings.shared = KanvasStrings(
            cameraPermissionsTitleLabel: NSLocalizedString("Post to WordPress", comment: "Title of camera permissions screen"),
            cameraPermissionsDescriptionLabel: NSLocalizedString("Allow access so you can start taking photos and videos.", comment: "Message on camera permissions screen to explain why the app needs camera and microphone permissions")
        )

        let saveDirectory: URL?
        do {
            saveDirectory = try Self.saveDirectory()
        } catch let error {
            assertionFailure("Should be able to create a save directory in Documents \(error)")
            saveDirectory = nil
        }

        super.init(settings: settings,
                 mediaPicker: WPMediaPickerForKanvas.self,
                 stickerProvider: nil,
                 analyticsProvider: KanvasAnalyticsHandler(),
                 quickBlogSelectorCoordinator: nil,
                 tagCollection: nil,
                 saveDirectory: saveDirectory)

        cameraHandler = CameraHandler(created: { [weak self] media in
            self?.poster = StoryPoster(context: post.blog.managedObjectContext ?? ContextManager.shared.mainContext, mediaFiles: mediaFiles)
            let postMedia: [StoryPoster.MediaItem] = media.compactMap { result in
                switch result {
                case .success(let item):
                    guard let item = item else { return nil }
                    return StoryPoster.MediaItem(url: item.output, size: item.size, archive: item.archive, original: item.unmodified)
                case .failure:
                    return nil
                }
            }

            guard let self = self else { return }

            let uploads: (String, [Media])? = try? self.poster?.add(mediaItems: postMedia, post: post)

            let content = uploads?.0 ?? ""

            updated(.success(content))

            if publishOnCompletion {
                // Replace the contents if we are publishing a new post
                post.content = content

                do {
                    try post.managedObjectContext?.save()
                } catch let error {
                    assertionFailure("Failed to save post during story update: \(error)")
                }

                self.publishPost(action: .publish, dismissWhenDone: true, analyticsStat:
                                    .editorPublishedPost)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        })
        self.delegate = cameraHandler
    }

    func present(on: UIViewController, with files: [MediaFile]) {
        storyLoader.download(files: files, for: post) { [weak self] output in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.show(media: output)
                on.present(self, animated: true, completion: {})
            }
        }
    }

    func trackOpen() {
        editorSession.start()
    }
}

extension StoryEditor: PublishingEditor {
    var prepublishingIdentifiers: [PrepublishingIdentifier] {
        return  [.title, .visibility, .schedule, .tags, .categories]
    }

    var prepublishingSourceView: UIView? {
        return nil
    }

    var alertBarButtonItem: UIBarButtonItem? {
        return nil
    }

    var isUploadingMedia: Bool {
        return false
    }

    var postTitle: String {
        get {
            return post.postTitle ?? ""
        }
        set {
            post.postTitle = newValue
        }
    }

    func getHTML() -> String {
        return post.content ?? ""
    }

    func cancelUploadOfAllMedia(for post: AbstractPost) {

    }

    func publishingDismissed() {
        hideLoading()
    }

    var wordCount: UInt {
        return post.content?.wordCount() ?? 0
    }
}

extension StoryEditor: PostEditorStateContextDelegate {
    func context(_ context: PostEditorStateContext, didChangeAction: PostEditorAction) {

    }

    func context(_ context: PostEditorStateContext, didChangeActionAllowed: Bool) {

    }
}
