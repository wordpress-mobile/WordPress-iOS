import Foundation
import Kanvas

/// An story editor which displays the Kanvas camera + editing screens.
class StoryEditor: CameraController {

    var post: AbstractPost = AbstractPost()

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
        return "wp_stories_creator"
    }

    private var cameraHandler: CameraHandler?
    private var poster: StoryPoster?
    private lazy var storyLoader: StoryMediaLoader = {
        return StoryMediaLoader()
    }()

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
        settings.features.editorConfirmAtTop = true
        settings.features.muteButton = true
        settings.crossIconInEditor = true
        settings.enabledModes = [.normal]
        settings.defaultMode = .normal
        settings.features.scaleMediaToFill = true
        settings.animateEditorControls = false
        settings.exportStopMotionPhotoAsVideo = false
        settings.fontSelectorUsesFont = true

        return settings
    }

    typealias Results = Result<AbstractPost, PostCoordinator.SavingError>

    static func editor(blog: Blog,
                       context: NSManagedObjectContext,
                       updated: @escaping (Results) -> Void,
                       uploaded: @escaping (Results) -> Void) -> StoryEditor {
        let post = PostService(managedObjectContext: context).createDraftPost(for: blog)
        return editor(post: post, mediaFiles: nil, publishOnCompletion: true, updated: updated, uploaded: uploaded)
    }

    static func editor(post: AbstractPost,
                       mediaFiles: [MediaFile]?,
                       publishOnCompletion: Bool = false,
                       updated: @escaping (Results) -> Void,
                       uploaded: @escaping (Results) -> Void) -> StoryEditor {
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
                     mediaFiles: [MediaFile]?,
                     publishOnCompletion: Bool,
                     updated: @escaping (Results) -> Void,
                     uploaded: @escaping (Results) -> Void
                    ) {
        self.post = post
        self.onClose = onClose

        let saveDirectory: URL?
        do {
            saveDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        } catch let error {
            assertionFailure("Should be able to create a save directory in documents \(error)")
            saveDirectory = nil
        }

        Kanvas.KanvasColors.shared = KanvasCustomUI.shared.cameraColors()
        Kanvas.KanvasFonts.shared = KanvasCustomUI.shared.cameraFonts()
        Kanvas.KanvasImages.shared = KanvasCustomUI.shared.cameraImages()
        Kanvas.KanvasStrings.shared = KanvasStrings(
            cameraPermissionsTitleLabel: NSLocalizedString("Post to WordPress", comment: "Title of camera permissions screen"),
            cameraPermissionsDescriptionLabel: NSLocalizedString("Allow access so you can start taking photos and videos.", comment: "Message on camera permissions screen to explain why the app needs camera and microphone permissions")
        )

        let analyticsSession = PostEditorAnalyticsSession(editor: .stories, post: post)
        self.editorSession = analyticsSession

        super.init(settings: settings,
                 mediaPicker: WPMediaPickerForKanvas.self,
                 stickerProvider: nil,
                 analyticsProvider: KanvasAnalyticsHandler(editorAnalyticsSession: analyticsSession),
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

            let uploads: (String, [Media])? = try? self.poster?.upload(mediaItems: postMedia, post: post, completion: { post in
                uploaded(post)
            })

            if let firstMediaFile = mediaFiles?.first {
                let processor = GutenbergBlockProcessor(for: "wp:jetpack/story", replacer: { block in
                    let mediaFiles = block.attributes["mediaFiles"] as? [[String: Any]]
                    if let mediaFile = mediaFiles?.first, mediaFile["url"] as? String == firstMediaFile.url {
                        return uploads?.0
                    } else {
                        return nil
                    }
                })
                post.content = processor.process(post.content ?? "")
            } else {
                post.content = uploads?.0
            }

            do {
                try post.managedObjectContext?.save()
            } catch let error {
                assertionFailure("Failed to save post during story upload: \(error)")
            }

            updated(.success(post))

            if publishOnCompletion {
                self.publishPost(action: .publish, dismissWhenDone: true, analyticsStat:
                                    .editorPublishedPost)
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        })
        self.delegate = cameraHandler
    }

    func populate(with files: [MediaFile], completion: @escaping (Result<Void, Error>) -> Void) {
        storyLoader.download(files: files, for: post) { [weak self] output in
            DispatchQueue.main.async {
                self?.show(media: output)
                completion(.success(()))
            }
        }
    }
}

extension StoryEditor: PublishingEditor {
    var prepublishingIdentifiers: [PrepublishingIdentifier] {
        return  [.title, .visibility, .schedule, .tags]
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
