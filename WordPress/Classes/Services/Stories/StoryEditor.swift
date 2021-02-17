import Foundation
import Kanvas

/// An story editor which displays the Kanvas camera + editing screens.
class StoryEditor: CameraController {

    var post: AbstractPost = AbstractPost()

    var onClose: ((Bool, Bool) -> Void)? = nil

    lazy var editorSession: PostEditorAnalyticsSession = {
        PostEditorAnalyticsSession(editor: .stories, post: post)
    }()

    let navigationBarManager: PostEditorNavigationBarManager? = nil

    fileprivate(set) lazy var debouncer: Debouncer = {
        return Debouncer(delay: PostEditorDebouncerConstants.autoSavingDelay, callback: debouncerCallback)
    }()

    private(set) lazy var postEditorStateContext: PostEditorStateContext = {
        return PostEditorStateContext(post: post, delegate: self)
    }()

    var verificationPromptHelper: VerificationPromptHelper? = nil

    var analyticsEditorSource: String {
        return "wp_stories_creator"
    }

    private let publishOnCompletion: Bool
    private var cameraHandler: CameraHandler?

    private static let useMetal = true

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
        settings.crossIconInEditor = true
        settings.enabledModes = [.normal]
        settings.defaultMode = .normal
        settings.features.scaleMediaToFill = true
        settings.animateEditorControls = false
        settings.exportStopMotionPhotoAsVideo = false
        settings.fontSelectorUsesFont = true

        return settings
    }

    static func editor(blog: Blog, context: NSManagedObjectContext) -> StoryEditor {
        let post = PostService(managedObjectContext: context).createDraftPost(for: blog)
        return editor(post: post, publishOnCompletion: true)
    }

    static func editor(post: AbstractPost, publishOnCompletion: Bool = false) -> StoryEditor {
        let controller = StoryEditor(post: post,
                                     onClose: nil,
                                     settings: cameraSettings,
                                     stickerProvider: nil,
                                     analyticsProvider: nil,
                                     quickBlogSelectorCoordinator: nil,
                                     tagCollection: nil,
                                     publishOnCompletion: publishOnCompletion)
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
                     publishOnCompletion: Bool) {
        self.post = post
        self.onClose = onClose
        self.publishOnCompletion = publishOnCompletion

        let saveDirectory: URL?
        do {
            saveDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        } catch let error {
            assertionFailure("Should be able to create a save directory in documents \(error)")
            saveDirectory = nil
        }

        super.init(settings: settings,
                 mediaPicker: nil,
                 stickerProvider: nil,
                 analyticsProvider: nil,
                 quickBlogSelectorCoordinator: nil,
                 tagCollection: nil,
                 saveDirectory: saveDirectory)

        cameraHandler = CameraHandler(created: { [weak self] _ in
            if publishOnCompletion {
                self?.publishPost(action: .publish, dismissWhenDone: true, analyticsStat:
                                    .editorPublishedPost)
            } else {
                self?.dismiss(animated: true, completion: nil)
            }
        })
        self.delegate = cameraHandler
    }
}

extension StoryEditor: PublishingEditor {
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
