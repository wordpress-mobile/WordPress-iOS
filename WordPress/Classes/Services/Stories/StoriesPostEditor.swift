import Foundation
import KanvasCamera

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

    var storyService: KanvasStoryService?
    var storyLoader: StoryMediaLoader? = StoryMediaLoader()

    init(post: AbstractPost,
                     onClose: ((Bool, Bool) -> Void)?,
                     settings: CameraSettings,
                     stickerProvider: StickerProvider?,
                     analyticsProvider: KanvasCameraAnalyticsProvider?,
                     quickBlogSelectorCoordinator: KanvasQuickBlogSelectorCoordinating?,
                     tagCollection: UIView?,
                     publishOnCompletion: Bool,
                     updated: @escaping (Result<(Post, [Media]), Error>) -> Void,
                     uploaded: @escaping (Result<(Post, [Media]), Error>) -> Void) {
        self.post = post
        self.onClose = onClose

        let saveDirectory = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)

        super.init(settings: KanvasService.cameraSettings,
                 stickerProvider: EmojiStickerProvider(),
                 analyticsProvider: KanvasCameraAnalyticsStub(),
                 quickBlogSelectorCoordinator: nil,
                 tagCollection: nil,
                 saveDirectory: saveDirectory)

        self.storyService = KanvasStoryService(post: post as! Post, updated: { [weak self] result in
            switch result {
            case .success:
                if publishOnCompletion {
                    self?.publishPost(action: .publish, dismissWhenDone: true, analyticsStat:
                                        .editorPublishedPost)
                } else {
                    self?.dismiss(animated: true, completion: nil)
                }
            case .failure:
                ()
            }
            self?.hideLoading()
            updated(result)
        }, uploaded: { [weak self] result in
            switch result {
            case .success(let output):
                self?.post = output.0
            case .failure:
                break
            }
            uploaded(result)
        })
    }

    func populate(with files: [StoryPoster.MediaFile], completion: @escaping (Result<Void, Error>) -> Void) {
        let semaphore = DispatchSemaphore(value: 1)
        storyLoader?.download(files: files, for: post) { [weak self] output in
            DispatchQueue.main.async {
                self?.show(media: output)
                completion(.success(()))
                semaphore.signal()
                print(output)
            }
        }
        semaphore.wait()
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

    var prepublishingIdentifiers: [PrepublishingIdentifier] {
        return  [.title, .visibility, .schedule, .tags]
    }
}

extension StoryEditor: PostEditorStateContextDelegate {
    func context(_ context: PostEditorStateContext, didChangeAction: PostEditorAction) {

    }

    func context(_ context: PostEditorStateContext, didChangeActionAllowed: Bool) {

    }
}
