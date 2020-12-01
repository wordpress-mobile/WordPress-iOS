import KanvasCamera

class StoryEditor: CameraController {
    var post: AbstractPost

    var onClose: ((Bool, Bool) -> Void)?

    var isOpenedDirectlyForPhotoPost: Bool

    private var service: KanvasService
    private var storyService: KanvasStoryService?

    private static var cameraSettings: CameraSettings {
        let settings = CameraSettings()
        settings.features.ghostFrame = true
        settings.features.metalPreview = true
        settings.features.metalFilters = true
        settings.features.openGLPreview = false
        settings.features.openGLCapture = false
        settings.features.cameraFilters = false
        settings.features.experimentalCameraFilters = true
        settings.features.editor = true
        settings.features.editorGIFMaker = false
        settings.features.editorFilters = false
        settings.features.editorText = true
        settings.features.editorMedia = true
        settings.features.editorDrawing = true
        settings.features.mediaPicking = true
        settings.features.editorPublishing = true
        settings.features.editorPostOptions = false
        settings.features.newCameraModes = true
        settings.features.gifs = false
        settings.features.multipleExports = true
        settings.crossIconInEditor = true
        settings.enabledModes = [.normal]
        settings.defaultMode = .normal
        settings.animateEditorControls = false
        settings.fontSelectorUsesFont = true
        settings.features.muteButton = true
        return settings
    }

    private var posted: () -> Void

    convenience init(blog: Blog) {
        let context = ContextManager.sharedInstance().mainContext
        let postService = PostService(managedObjectContext: context)
        let newPost = postService.createDraftPost(for: blog)

        self.init(post: newPost, loadAutosaveRevision: false, replaceEditor: { _, _ in

        }, editorSession: nil)
    }

    required init(post: AbstractPost, loadAutosaveRevision: Bool, replaceEditor: @escaping (EditorViewController, EditorViewController) -> (), editorSession: PostEditorAnalyticsSession?) {

        service = KanvasService()

        KanvasCameraColors.shared = KanvasCameraCustomUI.shared.cameraColors()
        KanvasCameraFonts.shared = KanvasCameraCustomUI.shared.cameraFonts()
        super.init(settings: StoryEditor.cameraSettings,
                   stickerProvider: EmojiStickerProvider(),
                   analyticsProvider: KanvasCameraAnalyticsStub(),
                   quickBlogSelectorCoordinator: nil,
                   tagCollection: nil)
        delegate = service
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
    }

    func prepopulateMediaItems(_ media: [Media]) {

    }

    func cancelUploadOfAllMedia(for post: AbstractPost) {

    }

    var hasFailedMedia: Bool

    var isUploadingMedia: Bool

    func removeFailedMedia() {

    }

    var verificationPromptHelper: VerificationPromptHelper?

    var errorDomain: String

    var mediaLibraryDataSource: MediaLibraryPickerDataSource

    func contentByStrippingMediaAttachments() -> String {

    }

    var debouncer: Debouncer

    var navigationBarManager: PostEditorNavigationBarManager

    var editorSession: PostEditorAnalyticsSession

    var replaceEditor: (EditorViewController, EditorViewController) -> ()

    var autosaver: Autosaver

    var postIsReblogged: Bool

    var wordCount: UInt
}

extension StoryEditor: PostEditor {
    var html: String {
        set {
            post.content = newValue
        }
        get {
            return post.content ?? ""
        }
    }

    var postTitle: String {
        set {
            post.postTitle = newValue
        }

        get {
            return post.postTitle ?? ""
        }
    }

    func setHTML(_ html: String) {
        self.html = html
    }

    func getHTML() -> String {
        return html
    }

    /// Maintainer of state for editor - like for post button
    ///
    private(set) lazy var postEditorStateContext: PostEditorStateContext = {
        return PostEditorStateContext(post: post, delegate: self)
    }()

    var analyticsEditorSource: String {
        return Analytics.editorSource
    }

    enum Analytics {
        static let editorSource = "story"
    }
}
