import UIKit
import React
import WPMediaPicker

class GutenbergController: UIViewController, PostEditor {
    
    var html: String = ""
    var postTitle: String = "" //TODO

    lazy var postEditorUtil = {
        return PostEditorUtil(context: self)
    }()

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
    
    let gutenberg: Gutenberg

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

    required init(post: AbstractPost) {
        guard let post = post as? Post else {
            fatalError()
        }
        self.post = post
        self.html = post.content ?? ""
        self.gutenberg = Gutenberg(props: ["initialData": self.html])
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
        configureNavigationBar()
        reloadBlogPickerButton()
        gutenberg.delegate = self
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

    @objc private func close(sender: UIBarButtonItem) {
        closeWasPressed()
    }

    private func closeWasPressed() {
        postEditorUtil.cancelEditing()
        onClose?(false, false)
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

        postEditorUtil.handlePublishButtonTap()
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
        closeWasPressed()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, moreWasPressed sender: UIButton) {

    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, blogPickerWasPressed sender: UIButton) {

    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, publishButtonWasPressed sender: UIButton) {
        gutenberg.requestHTML()
    }

    func navigationBarManager(_ manager: PostEditorNavigationBarManager, displayCancelMediaUploads sender: UIButton) {

    }
}
