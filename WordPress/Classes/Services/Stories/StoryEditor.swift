import Foundation
import Kanvas

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

    private var cameraHandler: CameraHandler?
    private var poster: StoryPoster?
    private var storyLoader: StoryMediaLoader? = StoryMediaLoader()

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

    static func editor(blog: Blog,
                       context: NSManagedObjectContext,
                       updated: @escaping (Result<(Post, [Media]), Error>) -> Void,
                       uploaded: @escaping (Result<(Post, [Media]), Error>) -> Void) -> StoryEditor {
        let post = PostService(managedObjectContext: context).createDraftPost(for: blog)
        return editor(post: post, mediaFiles: nil, publishOnCompletion: true, updated: updated, uploaded: uploaded)
    }

    static func editor(post: AbstractPost,
                       mediaFiles: [StoryPoster.MediaFile]?,
                       publishOnCompletion: Bool = false,
                       updated: @escaping (Result<(Post, [Media]), Error>) -> Void,
                       uploaded: @escaping (Result<(Post, [Media]), Error>) -> Void) -> StoryEditor {
        let controller = StoryEditor(post: post,
                                     onClose: nil,
                                     settings: cameraSettings,
                                     stickerProvider: nil,
                                     analyticsProvider: nil,
                                     quickBlogSelectorCoordinator: nil,
                                     tagCollection: nil,
                                     mediaFiles: mediaFiles,
                                     publishOnCompletion: publishOnCompletion,
                                     updated: updated,
                                     uploaded: uploaded)
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
                     mediaFiles: [StoryPoster.MediaFile]?,
                     publishOnCompletion: Bool,
                     updated: @escaping (Result<(Post, [Media]), Error>) -> Void,
                     uploaded: @escaping (Result<(Post, [Media]), Error>) -> Void
                    ) {
        self.post = post
        self.onClose = onClose

        let saveDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)

        super.init(settings: settings,
                 mediaPicker: nil,
                 stickerProvider: nil,
                 analyticsProvider: nil,
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
            let media = self.poster?.upload(mediaItems: postMedia, post: post as! Post, completion: uploaded)
            if let media = media {
                updated(.success((post as! Post, media)))
            }

            if publishOnCompletion {
                post.content = "<!-- wp:jetpack/story {} --> <div class=\"wp-story wp-block-jetpack-story\"></div><!-- /wp:jetpack/story -->"
                self.publishPost(action: .publish, dismissWhenDone: true, analyticsStat:
                                    .editorPublishedPost)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        })
        self.delegate = cameraHandler
    }

    func populate(with files: [StoryPoster.MediaFile], completion: @escaping (Result<Void, Error>) -> Void) {
        storyLoader?.download(files: files, for: post) { [weak self] output in
            DispatchQueue.main.async {
                self?.show(media: output)
                completion(.success(()))
                print(output)
            }
        }
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
