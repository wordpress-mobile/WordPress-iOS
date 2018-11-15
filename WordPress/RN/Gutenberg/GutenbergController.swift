import UIKit
import React
import WPMediaPicker

class GutenbergController: UIViewController, PublishablePostEditor {

    enum RequestHTMLReason {
        case publish
        case close
    }

    var html: String {
        set {
            post.content = newValue
        }
        get {
            return post.content ?? ""
        }
    }

    var postTitle: String

    /// Maintainer of state for editor - like for post button
    ///
    lazy var postEditorStateContext: PostEditorStateContext = {
        return PostEditorStateContext(post: post, delegate: self)
    }()

    var verificationPromptHelper: VerificationPromptHelper?

    var onClose: ((Bool, Bool) -> Void)?

    var isOpenedDirectlyForPhotoPost: Bool = false

    var isUploadingMedia: Bool {
        return false
    }

    func removeFailedMedia() {
        // TODO
    }

    var shouldRemovePostOnDismiss: Bool {
        return false
    }

    func cancelUploadOfAllMedia(for post: AbstractPost) {
        //TODO
    }

    func setHTML(_ html: String) {
        self.html = html
        //TODO: Update Gutenberg UI
    }

    func getHTML() -> String {
        return html
    }

    var post: AbstractPost {
        didSet {
            postEditorStateContext = PostEditorStateContext(post: post, delegate: self)
        }
    }

    let navigationBarManager = PostEditorNavigationBarManager()

    lazy var mediaPickerHelper: GutenbergMediaPickerHelper = {
        return GutenbergMediaPickerHelper(context: self, post: post)
    }()

    var hasFailedMedia: Bool {
        return false
    }

    var mainContext: NSManagedObjectContext {
        return ContextManager.sharedInstance().mainContext
    }

    var currentBlogCount: Int {
        let service = BlogService(managedObjectContext: mainContext)
        return service.blogCountForAllAccounts()
    }

    var isSingleSiteMode: Bool {
        return currentBlogCount <= 1 || post.hasRemote()
    }

    fileprivate var requestHTMLReason: RequestHTMLReason?

    fileprivate lazy var postEditorUtil = {
        return PostEditorUtil(context: self)
    }()

    fileprivate let gutenberg: Gutenberg

    required init(post: AbstractPost) {
        guard let post = post as? Post else {
            fatalError()
        }
        self.post = post
        self.postTitle = post.postTitle ?? ""
        self.gutenberg = Gutenberg(props: ["initialData": self.post.content ?? ""])
        self.verificationPromptHelper = AztecVerificationPromptHelper(account: self.post.blog.account)
        super.init(nibName: nil, bundle: nil)

        navigationBarManager.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    deinit {
        gutenberg.invalidate()
    }

    override func loadView() {
        view = gutenberg.rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        postEditorUtil.createRevisionOfPost()
        configureNavigationBar()
        reloadBlogPickerButton()
        gutenberg.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        verificationPromptHelper?.updateVerificationStatus()
    }

    func configureNavigationBar() {
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.accessibilityIdentifier = "Gutenberg Editor Navigation Bar"
        navigationItem.leftBarButtonItems = navigationBarManager.leftBarButtonItems
        navigationItem.rightBarButtonItems = navigationBarManager.rightBarButtonItems
    }

    func reloadBlogPickerButton() {
        var pickerTitle = post.blog.url ?? String()
        if let blogName = post.blog.settings?.name, blogName.isEmpty == false {
            pickerTitle = blogName
        }

        navigationBarManager.reloadBlogPickerButton(with: pickerTitle, enabled: !isSingleSiteMode)
    }
}

extension GutenbergController: GutenbergBridgeDelegate {

    func gutenbergDidRequestMediaPicker(callback: @escaping MediaPickerDidPickMediaCallback) {
        mediaPickerHelper.presentMediaPickerFullScreen(animated: true,
                                                       dataSourceType: .mediaLibrary,
                                                       callback: callback)
    }

    func gutenbergDidProvideHTML(_ html: String, changed: Bool) {
        self.html = html
        postEditorStateContext.updated(hasChanges: changed)

        if let reason = requestHTMLReason {
            requestHTMLReason = nil // clear the reason
            switch reason {
            case .publish:
                postEditorUtil.handlePublishButtonTap()
            case .close:
                postEditorUtil.cancelEditing()
            }
        }
    }
}

extension GutenbergController: PostEditorStateContextDelegate {

    func context(_ context: PostEditorStateContext, didChangeAction: PostEditorAction) {
        reloadPublishButton()
    }

    func context(_ context: PostEditorStateContext, didChangeActionAllowed: Bool) {
        reloadPublishButton()
    }

    func reloadPublishButton() {
        navigationBarManager.reloadPublishButton()
    }

}

extension GutenbergController: PostEditorNavigationBarManagerDelegate {
    var publishButtonText: String {
        return "Publish"
    }

    var isPublishButtonEnabled: Bool {
        return self.postEditorStateContext.isPublishButtonEnabled
    }

    var uploadingButtonSize: CGSize {
        return AztecPostViewController.Constants.uploadingButtonSize
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, closeWasPressed sender: UIButton) {
        requestHTMLReason = .close
        gutenberg.requestHTML()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, moreWasPressed sender: UIButton) {

    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, blogPickerWasPressed sender: UIButton) {

    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, publishButtonWasPressed sender: UIButton) {
        requestHTMLReason = .publish
        gutenberg.requestHTML()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, displayCancelMediaUploads sender: UIButton) {

    }
}
